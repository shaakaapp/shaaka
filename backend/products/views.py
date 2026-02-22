from rest_framework import generics, status, permissions, serializers
from rest_framework.response import Response
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from .models import Product, ProductImage, ProductReview, AutoScrollImage, WishlistItem
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
            words = search_query.split()
            
            # Smart category synonyms mapped to Category enum
            synonyms = {
                # Snacks & Sweets
                'snack': ['Snacks', 'Sweets', 'Dry fruits', 'Veg starters', 'Non Veg starters', 'chat', 'namkeen', 'chips', 'biscuit', 'cookies', 'mixture', 'bhujia', 'mathri'],
                'sweet': ['Sweets', 'Desserts', 'mithai', 'halwa', 'ladoo', 'barfi', 'pedha', 'jalebi', 'gulab jamun', 'rasgulla', 'chikki'],
                'dessert': ['Sweets', 'Desserts', 'ice cream', 'cake', 'pastry'],
                
                # Vegetables & Fruits
                'veg': ['Vegetables', 'Veg starters', 'Veg thali', 'Pulao', 'greens', 'sabzi', 'tarkari'],
                'vegetable': ['Vegetables', 'Veg starters', 'Veg thali', 'Pulao', 'greens', 'sabzi', 'tarkari'],
                'fruit': ['Fruits', 'Dry fruits', 'phal', 'fresh fruit'],
                'dry fruit': ['Dry fruits', 'nuts', 'badam', 'kaju', 'pista', 'kismis', 'almond', 'cashew', 'raisin', 'walnut', 'dates'],
                'nut': ['Dry fruits', 'nuts', 'badam', 'kaju', 'pista', 'kismis', 'almond', 'cashew', 'raisin', 'walnut', 'dates'],
                
                # Meat & Non-Veg
                'nonveg': ['Non Veg starters', 'Non veg Thali', 'Biryani', 'meat', 'chicken', 'mutton', 'fish', 'egg', 'seafood'],
                'meat': ['Non Veg starters', 'Non veg Thali', 'Biryani', 'chicken', 'mutton', 'fish', 'egg', 'seafood'],
                'chicken': ['Non Veg starters', 'Non veg Thali', 'Biryani', 'poultry', 'murgh'],
                'mutton': ['Non Veg starters', 'Non veg Thali', 'Biryani', 'lamb', 'goat', 'gosht'],
                'fish': ['Non Veg starters', 'Non veg Thali', 'Biryani', 'seafood', 'prawn', 'crab', 'machli'],
                'egg': ['Non Veg starters', 'Non veg Thali', 'Biryani', 'anda'],

                # Drinks & Beverages
                'drink': ['Drinks', 'Tea Powders', 'beverage', 'juice', 'soda', 'cool drink', 'water', 'lassi', 'buttermilk', 'chai', 'coffee'],
                'beverage': ['Drinks', 'Tea Powders', 'juice', 'soda', 'cool drink', 'water', 'lassi', 'buttermilk', 'chai', 'coffee'],
                'tea': ['Drinks', 'Tea Powders', 'chai', 'green tea', 'black tea'],
                'coffee': ['Drinks', 'Tea Powders', 'filter coffee', 'instant coffee'],

                # Groceries (Staples)
                'grocery': ['Grains', 'Pulses', 'Flours', 'Rice', 'Oils', 'Spices', 'Millets', 'staple', 'pantry', 'kirana', 'provisions'],
                'staple': ['Grains', 'Pulses', 'Flours', 'Rice', 'Oils', 'Spices', 'Millets', 'pantry', 'kirana', 'provisions'],
                'grain': ['Grains', 'Rice', 'Millets', 'wheat', 'gehu', 'jowar', 'bajra', 'oats'],
                'pulse': ['Pulses', 'dal', 'dhal', 'lentil', 'chana', 'moong', 'toor', 'urad', 'masoor', 'rajma', 'chole', 'lobia', 'peas', 'beans', 'gram'],
                'dal': ['Pulses', 'dhal', 'lentil', 'chana', 'moong', 'toor', 'urad', 'masoor', 'rajma', 'chole'],
                'lentil': ['Pulses', 'dal', 'dhal', 'chana', 'moong', 'toor', 'urad', 'masoor', 'rajma', 'chole'],
                'flour': ['Flours', 'atta', 'maida', 'besan', 'sooji', 'rawa', 'wheat flour', 'rice flour', 'corn flour'],
                'atta': ['Flours', 'wheat flour'],
                'rice': ['Rice', 'chawal', 'basmati', 'sona masuri', 'raw rice', 'boiled rice', 'brown rice', 'poha', 'murmure'],
                'oil': ['Oils', 'tel', 'cooking oil', 'sunflower oil', 'groundnut oil', 'mustard oil', 'coconut oil', 'sesame oil', 'ghee'],
                'ghee': ['Oils', 'Dairy', 'clarified butter'],
                'spice': ['Spices', 'masala', 'mirchi', 'haldi', 'dhaniya', 'jeera', 'mustard seeds', 'rai', 'methi', 'elaichi', 'clove', 'cinnamon', 'pepper', 'garam masala'],
                'masala': ['Spices', 'spice', 'mirchi', 'haldi', 'dhaniya', 'jeera', 'mustard seeds', 'rai', 'methi', 'elaichi', 'clove', 'cinnamon', 'pepper', 'garam masala'],
                'millet': ['Millets', 'ragi', 'jowar', 'bajra', 'foxtail', 'little millet', 'barnyard millet', 'kodo millet', 'proso millet', 'siridhanya'],
                
                # Dairy
                'dairy': ['Dairy', 'milk', 'dudh', 'curd', 'dahi', 'yogurt', 'paneer', 'cheese', 'butter', 'makhan', 'ghee', 'cream'],
                'milk': ['Dairy', 'dudh'],
                'curd': ['Dairy', 'dahi', 'yogurt'],
                'paneer': ['Dairy', 'cottage cheese'],

                # Meals (Prepared Food)
                'dinner': ['Thali', 'Veg thali', 'Non veg Thali', 'Biryani', 'Pulao', 'meal', 'bhojan'],
                'lunch': ['Thali', 'Veg thali', 'Non veg Thali', 'Biryani', 'Pulao', 'meal', 'bhojan'],
                'thali': ['Thali', 'Veg thali', 'Non veg Thali', 'meal', 'bhojan'],
                'breakfast': ['Tiffins', 'nasta', 'nashta', 'morning meal'],
                'tiffin': ['Tiffins', 'breakfast', 'nasta', 'nashta', 'morning meal', 'idli', 'dosa', 'vada', 'upma', 'poori'],
                'starter': ['Veg starters', 'Non Veg starters', 'appetizer', 'snack', 'kebab', 'tikka', 'pakoda', 'samosa'],
                
                # Broad/Catch-all terms
                'food': ['Fruits', 'Vegetables', 'Dairy', 'Grains', 'Spices', 'Veg starters', 'Non Veg starters', 'Biryani', 'Pulao', 'Veg thali', 'Non veg Thali', 'Sweets', 'Snacks', 'Dry fruits', 'Tiffins', 'Desserts', 'Millets', 'Pulses', 'Flours', 'Rice', 'Oils'],
                'item': ['Others'],
                'other': ['Others']
            }
            
            for word in words:
                word_lower = word.lower()
                
                # Basic stemming (remove trailing s)
                stemmed_word = word_lower
                if word_lower.endswith('ies') and len(word_lower) > 4:
                    stemmed_word = word_lower[:-3] + 'y'
                elif word_lower.endswith('es') and len(word_lower) > 3:
                    stemmed_word = word_lower[:-2]
                elif word_lower.endswith('s') and len(word_lower) > 2:
                    stemmed_word = word_lower[:-1]
                
                # Check for category synonyms
                related_cats = []
                for key, cats in synonyms.items():
                    if key in word_lower or key in stemmed_word:
                        related_cats.extend(cats)
                
                # Build query condition for this word
                word_q = Q(name__icontains=word) | Q(description__icontains=word) | Q(category__icontains=word)
                if word_lower != stemmed_word:
                    word_q |= Q(name__icontains=stemmed_word) | Q(description__icontains=stemmed_word) | Q(category__icontains=stemmed_word)
                
                for cat in related_cats:
                    word_q |= Q(category__icontains=cat)
                    
                queryset = queryset.filter(word_q)

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


# Wishlist Views
class WishlistToggleView(APIView):
    def post(self, request, user_id):
        product_id = request.data.get('product_id')
        if not product_id:
             return Response({'error': 'product_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
             user = UserProfile.objects.get(id=user_id)
             product = Product.objects.get(id=product_id)
        except (UserProfile.DoesNotExist, Product.DoesNotExist):
             return Response({'error': 'User or Product not found'}, status=status.HTTP_404_NOT_FOUND)

        wishlist_item, created = WishlistItem.objects.get_or_create(user=user, product=product)
        if created:
             return Response({'message': 'Added to wishlist', 'status': 'added'}, status=status.HTTP_201_CREATED)
        else:
             wishlist_item.delete()
             return Response({'message': 'Removed from wishlist', 'status': 'removed'}, status=status.HTTP_200_OK)

class WishlistCheckView(APIView):
    def get(self, request, user_id, product_id):
         exists = WishlistItem.objects.filter(user_id=user_id, product_id=product_id).exists()
         return Response({'is_wishlisted': exists})

class WishlistListView(generics.ListAPIView):
    serializer_class = ProductSerializer

    def get_queryset(self):
         user_id = self.kwargs['user_id']
         # Get all products that this user has wishlisted
         return Product.objects.filter(wishlisted_by__user_id=user_id).order_by('-wishlisted_by__added_at')
