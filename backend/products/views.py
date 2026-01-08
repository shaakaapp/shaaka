from rest_framework import generics, status, permissions, serializers
from rest_framework.response import Response
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from .models import Product, ProductImage, ProductReview
from .serializers import ProductSerializer, ProductReviewSerializer
from users.models import UserProfile

class ProductListCreateView(generics.ListCreateAPIView):
    queryset = Product.objects.all().order_by('-created_at')
    serializer_class = ProductSerializer

    def create(self, request, *args, **kwargs):
        # Expecting 'vendor_id' in data for now since we trust local usage, 
        # but in production use request.user
        vendor_id = request.data.get('vendor')
        vendor = get_object_or_404(UserProfile, id=vendor_id)
        
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
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

        # Handle Images Update
        # For simplicity, if 'images' is provided, we can append them. 
        # Or if we want to replace/delete, we'd need more logic.
        # Let's assume we just append new images for now or clients send a list to ADD.
        # User requested "option to edit", usually implies changing details.
        # Handling full image management might be complex (deleting individual images).
        # Let's support adding new images via the same 'images' list of URLs key.
        images_data = request.data.get('images', []) 
        if images_data:
            for img_url in images_data:
                 # Check if already exists to avoid duplicates if client sends all
                if not ProductImage.objects.filter(product=instance, image_url=img_url).exists():
                    ProductImage.objects.create(product=instance, image_url=img_url)

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
