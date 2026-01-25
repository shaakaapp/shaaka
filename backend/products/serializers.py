from rest_framework import serializers
from .models import Product, ProductImage, ProductReview, ProductVariant
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

class ProductVariantSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductVariant
        fields = ['id', 'quantity', 'unit', 'price']

class ProductSerializer(serializers.ModelSerializer):
    images = ProductImageSerializer(many=True, read_only=True)
    variants = ProductVariantSerializer(many=True, required=False)
    vendor_name = serializers.ReadOnlyField(source='vendor.full_name')
    
    class Meta:
        model = Product
        fields = [
            'id', 'vendor', 'vendor_name', 'name', 'description', 
            'category', 'price', 'unit', 'stock_quantity', 
            'average_rating', 'rating_count', 'images', 'variants', 'created_at'
        ]
        read_only_fields = ['id', 'vendor', 'average_rating', 'rating_count', 'created_at', 'updated_at']

    def create(self, validated_data):
        variants_data = validated_data.pop('variants', [])
        product = Product.objects.create(**validated_data)
        
        variants = [ProductVariant(product=product, **v_data) for v_data in variants_data]
        if variants:
            ProductVariant.objects.bulk_create(variants)
            
        return product

    def update(self, instance, validated_data):
        variants_data = validated_data.pop('variants', None)
        
        # Update standard fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Update variants if provided
        if variants_data is not None:
            # For simplicity, we can delete existing and re-create, or update intelligently.
            # Re-creating is safer for simple lists.
            instance.variants.all().delete()
            for variant_data in variants_data:
                ProductVariant.objects.create(product=instance, **variant_data)
                
        return instance
