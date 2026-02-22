import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'shaaka_backend.settings')
django.setup()

from products.models import Product
from django.test import RequestFactory
from products.views import ProductListCreateView

factory = RequestFactory()
request = factory.get('/products/?search=snacks')
view = ProductListCreateView.as_view()
response = view(request)
# Depending on how the view is set up, response.data holds the results
print("Results for 'snacks':", len(response.data))

# Test another synonym
request2 = factory.get('/products/?search=veg')
response2 = view(request2)
print("Results for 'veg':", len(response2.data))
