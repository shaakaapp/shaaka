import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'shaaka_backend.settings')
django.setup()

from products.views import ProductListCreateView
from django.test import RequestFactory

factory = RequestFactory()
view = ProductListCreateView.as_view()

queries = ['dal', 'grocery', 'atta', 'tiffin', 'dinner', 'dessert']
for q in queries:
    request = factory.get(f'/products/?search={q}')
    response = view(request)
    print(f"Results for '{q}': {len(response.data)}")
