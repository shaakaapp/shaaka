from django.db import models
from django.utils import timezone
from users.models import UserProfile
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.db.models import Avg, Count

class Product(models.Model):
    CATEGORY_CHOICES = [
        ('Fruits', 'Fruits'),
        ('Vegetables', 'Vegetables'),
        ('Dairy', 'Dairy'),
        ('Grains', 'Grains'),
        ('Spices', 'Spices'),
        ('Veg starters', 'Veg starters'),
        ('Non Veg starters', 'Non Veg starters'),
        ('Biryani', 'Biryani'),
        ('Pulao', 'Pulao'),
        ('Veg thali', 'Veg thali'),
        ('Non veg Thali', 'Non veg Thali'),
        ('Sweets', 'Sweets'),
        ('Snacks', 'Snacks'),
        ('Dry fruits', 'Dry fruits'),
        ('Tiffins', 'Tiffins'),
        ('Drinks', 'Drinks'),
        ('Desserts', 'Desserts'),
        ('Millets', 'Millets'),
        ('Pulses', 'Pulses'),
        ('Flours', 'Flours'),
        ('Tea Powders', 'Tea Powders'),
        ('Rice', 'Rice'),
        ('Oils', 'Oils'),
        ('Others', 'Others'),
    ]

    id = models.BigAutoField(primary_key=True)
    vendor = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='products')
    name = models.CharField(max_length=255)
    description = models.TextField()
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    unit = models.CharField(max_length=50)
    stock_quantity = models.DecimalField(max_digits=10, decimal_places=3, default=0)
    
    # Denormalized rating fields for performance
    average_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0.00)
    rating_count = models.IntegerField(default=0)

    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'products'

    def __str__(self):
        return self.name

class ProductImage(models.Model):
    id = models.BigAutoField(primary_key=True)
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='images')
    image_url = models.TextField()
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'product_images'

class ProductVariant(models.Model):
    id = models.BigAutoField(primary_key=True)
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='variants')
    quantity = models.DecimalField(max_digits=10, decimal_places=3)
    unit = models.CharField(max_length=50)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    stock_quantity = models.DecimalField(max_digits=10, decimal_places=3, default=0)

    class Meta:
        db_table = 'product_variants'

class ProductReview(models.Model):
    id = models.BigAutoField(primary_key=True)
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='reviews')
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='reviews')
    rating = models.IntegerField()  # 1 to 5
    comment = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'product_reviews'
        unique_together = ('product', 'user')  # One review per user per product

# Signals to update Product stats
@receiver(post_save, sender=ProductReview)
@receiver(post_delete, sender=ProductReview)
def update_product_rating(sender, instance, **kwargs):
    product = instance.product
    stats = product.reviews.aggregate(
        avg_rating=Avg('rating'),
        count=Count('id')
    )
    product.average_rating = stats['avg_rating'] or 0.0
    product.rating_count = stats['count'] or 0
    product.save(update_fields=['average_rating', 'rating_count'])

class AutoScrollImages(models.Model):
    id = models.BigAutoField(primary_key=True)
    image = models.CharField(max_length=100)
    title = models.CharField(max_length=255, blank=True, null=True)
    is_active = models.BooleanField()
    order = models.IntegerField()
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()
    placement = models.CharField(max_length=20)

    class Meta:
        managed = False
        db_table = 'auto_scroll_images'

