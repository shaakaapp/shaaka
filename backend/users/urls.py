from django.urls import path
from . import views

urlpatterns = [
    path('auth/request-otp/', views.request_otp, name='request_otp'),
    path('auth/verify-otp/', views.verify_otp, name='verify_otp'),
    path('auth/register/', views.register, name='register'),
    path('auth/login/', views.login, name='login'),
    path('upload/image/', views.upload_image, name='upload_image'),
    path('profile/<int:user_id>/', views.get_profile, name='get_profile'),
    path('profile/<int:user_id>/update/', views.update_profile, name='update_profile'),
    path('users/<int:user_id>/addresses/', views.user_addresses_list_create, name='user_addresses_list_create'),
    path('users/<int:user_id>/addresses/<int:address_id>/', views.user_address_detail, name='user_address_detail'),
]