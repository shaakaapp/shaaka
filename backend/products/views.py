from rest_framework import generics, status, permissions, serializers
from rest_framework.response import Response
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from .models import Product, ProductImage, ProductReview, AutoScrollImage
from .serializers import ProductSerializer, ProductReviewSerializer, AutoScrollImageSerializer
from users.models import UserProfile

class ProductListCreateView(generics.ListCreateAPIView):
    serializer_class = ProductSerializer

    def get_queryset(self):
        queryset = Product.objects.all()
        
        # Handle Search
        search_query = self.request.query_params.get('search', None)
        if search_query:
            from django.db.models import Q
            queryset = queryset.filter(
                Q(name__icontains=search_query) | 
                Q(description__icontains=search_query) |
                Q(category__icontains=search_query)
            )

        # Handle Ordering
        ordering = self.request.query_params.get('ordering', '-created_at')
        if ordering in ['-rating_count', '-average_rating', 'price', '-price', '-created_at']:
            queryset = queryset.order_by(ordering)
        else:
            queryset = queryset.order_by('-created_at')
            
        return queryset

    def create(self, request, *args, **kwargs):
        # Expecting 'vendor_id' in data for now since we trust local usage, 
        # but in production use request.user
        vendor_id = request.data.get('vendor')
        vendor = get_object_or_404(UserProfile, id=vendor_id)
        
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            print(f"Product Creation Validation Error: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        product = serializer.save(vendor=vendor)

        # Handle Images
        images_data = request.data.get('images', []) # Expecting list of URL strings
        if images_data:
            for img_url in images_data:
                ProductImage.objects.create(product=product, image_url=img_url)

        headers = self.get_success_headers(serializer.data)
        # Return full serialized data including images
        return Response(ProductSerializer(product).data, status=status.HTTP_201_CREATED, headers=headers)

class VendorProductListView(generics.ListAPIView):
    serializer_class = ProductSerializer

    def get_queryset(self):
        vendor_id = self.kwargs['vendor_id']
        return Product.objects.filter(vendor_id=vendor_id).order_by('-created_at')

class ProductDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)

        # Handle Images Sync
        # The 'images' list in the request is treated as the definitive list.
        # 1. Identify existing images in DB
        current_images = {img.image_url: img for img in ProductImage.objects.filter(product=instance)}
        
        # 2. Get incoming list of URLs (both kept existing ones and new ones)
        incoming_urls = request.data.get('images', [])
        
        # 3. Determine deletions (In DB but not in incoming list)
        for url, img_obj in current_images.items():
            if url not in incoming_urls:
                img_obj.delete()
                
        # 4. Determine additions (In incoming list but not in DB)
        for url in incoming_urls:
            if url not in current_images:
                ProductImage.objects.create(product=instance, image_url=url)

        if getattr(instance, '_prefetched_objects_cache', None):
            # If 'prefetch_related' has been applied to a queryset, we need to
            # forcibly invalidate the prefetch cache on the instance.
            instance._prefetched_objects_cache = {}

        return Response(serializer.data)

class ProductReviewListCreateView(generics.ListCreateAPIView):
    serializer_class = ProductReviewSerializer

    def get_queryset(self):
        product_id = self.kwargs['product_id']
        return ProductReview.objects.filter(product_id=product_id).order_by('-created_at')

    def perform_create(self, serializer):
        product_id = self.kwargs['product_id']
        product = get_object_or_404(Product, id=product_id)
        
        user_id = self.request.data.get('user')
        user = get_object_or_404(UserProfile, id=user_id)
        
        # Check if user already reviewed
        if ProductReview.objects.filter(product=product, user=user).exists():
            raise serializers.ValidationError("You have already reviewed this product.")
            
        serializer.save(product=product, user=user)

class ProductReviewDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = ProductReview.objects.all()
    serializer_class = ProductReviewSerializer

class AutoScrollImageListView(generics.ListAPIView):
    serializer_class = AutoScrollImageSerializer
    permission_classes = [permissions.AllowAny] # Anyone can see the banners

    def get_queryset(self):
        return AutoScrollImage.objects.filter(is_active=True).order_by('order')
