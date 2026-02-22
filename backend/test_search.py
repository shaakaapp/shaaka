import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'shaaka_backend.settings')
django.setup()

from products.models import Product
print("Total products:", Product.objects.count())
print("Categories:", set(Product.objects.values_list('category', flat=True)))
print("Products with 'snacks' in category:", Product.objects.filter(category__icontains='snacks').count())
print("Products with 'snacks' in name:", Product.objects.filter(name__icontains='snacks').count())
print("Products with 'snacks' in description:", Product.objects.filter(description__icontains='snacks').count())
