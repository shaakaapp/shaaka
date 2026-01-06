from django.urls import path
from .views import (
    ProductListCreateView, 
    VendorProductListView, 
    ProductDetailView,
    ProductReviewListCreateView
)

urlpatterns = [
    path('products/', ProductListCreateView.as_view(), name='product-list-create'),
    path('products/<int:pk>/', ProductDetailView.as_view(), name='product-detail'),
    path('products/vendor/<int:vendor_id>/', VendorProductListView.as_view(), name='vendor-product-list'),
    path('products/<int:product_id>/reviews/', ProductReviewListCreateView.as_view(), name='product-review-list-create'),
]
