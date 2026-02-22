from django.urls import path
from .views import (
    ProductListCreateView, 
    VendorProductListView, 
    ProductDetailView,
    ProductReviewListCreateView,
    ProductReviewDetailView,
    AutoScrollImageListView,
    WishlistListView,
    WishlistToggleView,
    WishlistCheckView
)

urlpatterns = [
    path('products/', ProductListCreateView.as_view(), name='product-list-create'),
    path('products/auto-scroll-images/', AutoScrollImageListView.as_view(), name='auto-scroll-image-list'),
    path('products/<int:pk>/', ProductDetailView.as_view(), name='product-detail'),
    path('products/vendor/<int:vendor_id>/', VendorProductListView.as_view(), name='vendor-product-list'),
    path('products/<int:product_id>/reviews/', ProductReviewListCreateView.as_view(), name='product-review-list-create'),
    path('reviews/<int:pk>/', ProductReviewDetailView.as_view(), name='product-review-detail'),
    
    path('wishlist/<int:user_id>/', WishlistListView.as_view(), name='wishlist-list'),
    path('wishlist/toggle/<int:user_id>/', WishlistToggleView.as_view(), name='wishlist-toggle'),
    path('wishlist/check/<int:user_id>/<int:product_id>/', WishlistCheckView.as_view(), name='wishlist-check'),
]
