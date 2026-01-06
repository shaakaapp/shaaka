from rest_framework import serializers
from .models import Product, ProductImage, ProductReview
from users.serializers import UserProfileSerializer

class ProductImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ['id', 'image_url', 'created_at']

class ProductReviewSerializer(serializers.ModelSerializer):
    user_name = serializers.ReadOnlyField(source='user.full_name')
    
    class Meta:
        model = ProductReview
        fields = ['id', 'user', 'user_name', 'rating', 'comment', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']

class ProductSerializer(serializers.ModelSerializer):
    images = ProductImageSerializer(many=True, read_only=True)
    vendor_name = serializers.ReadOnlyField(source='vendor.full_name')
    # Use method field to check if current user reviewed? (Optional, maybe for UI)

    class Meta:
        model = Product
        fields = [
            'id', 'vendor', 'vendor_name', 'name', 'description', 
            'category', 'price', 'unit', 'stock_quantity', 
            'average_rating', 'rating_count', 'images', 'created_at'
        ]
        read_only_fields = ['id', 'vendor', 'average_rating', 'rating_count', 'created_at', 'updated_at']
