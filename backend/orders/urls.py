from django.urls import path
from . import views

urlpatterns = [
    # Cart URLs
    path('cart/<int:user_id>/', views.get_cart, name='get_cart'),
    path('cart/<int:user_id>/add/', views.add_to_cart, name='add_to_cart'),
    path('cart/<int:user_id>/update/<int:item_id>/', views.update_cart_item, name='update_cart_item'),
    path('cart/<int:user_id>/remove/<int:item_id>/', views.remove_from_cart, name='remove_from_cart'),
    path('cart/<int:user_id>/clear/', views.clear_cart, name='clear_cart'),
    
    # Order URLs
    path('orders/<int:user_id>/place/', views.place_order, name='place_order'),
    path('orders/<int:user_id>/list/', views.get_orders, name='get_orders'),
    path('orders/detail/<int:order_id>/', views.get_order_details, name='get_order_details'),
    path('orders/<int:user_id>/cancel/<int:order_id>/', views.cancel_order, name='cancel_order'),
]
