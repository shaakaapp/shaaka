from django.urls import path
from . import views

urlpatterns = [
    path('create/<int:user_id>/', views.create_donation, name='create_donation'),
]
