from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db import transaction
from .models import Cart, CartItem, Order, OrderItem
from products.models import Product
from users.models import UserProfile
from .serializers import CartSerializer, OrderSerializer

@api_view(['GET'])
def get_cart(request, user_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        cart, created = Cart.objects.get_or_create(user=user)
        serializer = CartSerializer(cart)
        return Response(serializer.data)
    except UserProfile.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
def add_to_cart(request, user_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        cart, created = Cart.objects.get_or_create(user=user)
        
        product_id = request.data.get('product_id')
        quantity = int(request.data.get('quantity', 1))
        
        product = get_object_or_404(Product, id=product_id)
        
        # Check stock
        if product.stock_quantity < quantity:
            return Response({'error': 'Not enough stock available'}, status=status.HTTP_400_BAD_REQUEST)
        
        cart_item, item_created = CartItem.objects.get_or_create(
            cart=cart, 
            product=product,
            defaults={'quantity': 0}
        )
        
        # If adding more than stock allows (considering already in cart)
        if cart_item.quantity + quantity > product.stock_quantity:
             return Response({'error': 'Not enough stock available'}, status=status.HTTP_400_BAD_REQUEST)

        cart_item.quantity += quantity
        cart_item.save()
        
        return Response(CartSerializer(cart).data, status=status.HTTP_200_OK)
        
    except UserProfile.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
def update_cart_item(request, user_id, item_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        cart = Cart.objects.get(user=user)
        cart_item = get_object_or_404(CartItem, id=item_id, cart=cart)
        
        quantity = int(request.data.get('quantity'))
        
        if quantity <= 0:
            cart_item.delete()
        else:
            if quantity > cart_item.product.stock_quantity:
                return Response({'error': 'Not enough stock available'}, status=status.HTTP_400_BAD_REQUEST)
            cart_item.quantity = quantity
            cart_item.save()
            
        return Response(CartSerializer(cart).data)
    except UserProfile.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Cart.DoesNotExist:
        return Response({'error': 'Cart not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['DELETE'])
def remove_from_cart(request, user_id, item_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        cart = Cart.objects.get(user=user)
        cart_item = get_object_or_404(CartItem, id=item_id, cart=cart)
        cart_item.delete()
        
        return Response(CartSerializer(cart).data)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def clear_cart(request, user_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        cart = Cart.objects.get(user=user)
        cart.items.all().delete()
        return Response(CartSerializer(cart).data)
    except Exception as e:
         return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@transaction.atomic
def place_order(request, user_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        cart = get_object_or_404(Cart, user=user)
        
        if not cart.items.exists():
            return Response({'error': 'Cart is empty'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Prepare Order Data
        shipping_address = request.data.get('shipping_address') or user.address_line
        city = request.data.get('city') or user.city
        state = request.data.get('state') or user.state
        pincode = request.data.get('pincode') or user.pincode
        payment_method = request.data.get('payment_method', 'COD')

        if not shipping_address:
             return Response({'error': 'Shipping address required'}, status=status.HTTP_400_BAD_REQUEST)

        # Create Order
        order = Order.objects.create(
            user=user,
            shipping_address=shipping_address,
            city=city,
            state=state,
            pincode=pincode,
            total_amount=cart.total_price,
            payment_method=payment_method
        )
        
        # Move items to Order Items and Deduct Stock
        for item in cart.items.all():
            if item.quantity > item.product.stock_quantity:
                raise Exception(f"Not enough stock for {item.product.name}")
            
            OrderItem.objects.create(
                order=order,
                product=item.product,
                product_name=item.product.name,
                quantity=item.quantity,
                price_at_purchase=item.product.price
            )
            
            # Update Stock
            item.product.stock_quantity -= item.quantity
            item.product.save()
        
        # Clear Cart
        cart.items.all().delete()
        
        return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)
        
    except UserProfile.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def get_orders(request, user_id):
    try:
        # Check if user exists
        user = UserProfile.objects.get(id=user_id)
        orders = Order.objects.filter(user=user).order_by('-created_at')
        serializer = OrderSerializer(orders, many=True)
        return Response(serializer.data)
    except UserProfile.DoesNotExist:
         return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
def get_order_details(request, order_id):
    order = get_object_or_404(Order, id=order_id)
    serializer = OrderSerializer(order)
    return Response(serializer.data)
