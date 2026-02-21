from rest_framework import serializers
from .models import Cart, CartItem, Order, OrderItem
from products.serializers import ProductSerializer
from products.models import Product, ProductVariant
from drf_spectacular.utils import extend_schema_field

class CartItemSerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)
    product_id = serializers.IntegerField(write_only=True)
    stock_quantity = serializers.SerializerMethodField()
    variant_label = serializers.SerializerMethodField()
    total_price = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = CartItem
        fields = ['id', 'product', 'product_id', 'quantity', 'unit_value', 'total_price', 'stock_quantity', 'variant_label']

    @extend_schema_field(serializers.FloatField())
    def get_stock_quantity(self, obj):
        # Check if there is a variant for this unit_value
        variant = ProductVariant.objects.filter(product=obj.product, quantity=obj.unit_value).first()
        if variant:
            return float(variant.stock_quantity)
        return float(obj.product.stock_quantity)

    @extend_schema_field(serializers.CharField(allow_null=True))
    def get_variant_label(self, obj):
        variant = ProductVariant.objects.filter(product=obj.product, quantity=obj.unit_value).first()
        if variant:
             qty = variant.quantity
             # Format to remove trailing zeros if integer
             qty_str = f"{qty:f}".rstrip('0').rstrip('.')
             return f"{qty_str} {variant.unit}"
        return None

class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)
    total_price = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = Cart
        fields = ['id', 'user', 'items', 'total_price', 'updated_at']

class OrderItemSerializer(serializers.ModelSerializer):
    # We might want full product details or just the snapshot
    product = ProductSerializer(read_only=True)
    
    class Meta:
        model = OrderItem
        fields = ['id', 'product', 'product_name', 'quantity', 'price_at_purchase']

class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)

    class Meta:
        model = Order
        fields = [
            'id', 'user', 'items', 'status', 'total_amount', 
            'payment_method', 'is_paid', 'created_at',
            'shipping_address', 'city', 'state', 'pincode'
        ]
        read_only_fields = ['user', 'total_amount', 'created_at', 'status', 'is_paid']
