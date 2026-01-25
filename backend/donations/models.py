from django.db import models
from django.utils import timezone
from users.models import UserProfile

class Donation(models.Model):
    DONATION_TYPES = [
        ('Food', 'Food'),
        ('Clothes', 'Clothes'),
        ('Money', 'Money'),
        ('Education', 'Education'),
    ]

    STATUS_CHOICES = [
        ('Pending', 'Pending'),
        ('Approved', 'Approved'),
        ('Received', 'Received'),
        ('Rejected', 'Rejected'),
    ]

    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='donations')
    donation_type = models.CharField(max_length=20, choices=DONATION_TYPES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Pending')
    created_at = models.DateTimeField(default=timezone.now)

    # Fields for Food/Clothes
    item_name = models.CharField(max_length=255, blank=True, null=True) # Also used for Education Name
    description = models.TextField(blank=True, null=True)
    quantity = models.CharField(max_length=100, blank=True, null=True) # e.g., "5 kg", "2 bags"
    item_image = models.ImageField(upload_to='donations/items/', blank=True, null=True)
    pickup_address = models.TextField(blank=True, null=True)
    contact_number = models.CharField(max_length=20, blank=True, null=True)
    email = models.CharField(max_length=255, blank=True, null=True)

    # Fields for Money
    amount = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    payment_screenshot = models.ImageField(upload_to='donations/payments/', blank=True, null=True)
    message = models.TextField(blank=True, null=True) # Message for money donation
    
    # Fields for Education
    profession = models.CharField(max_length=255, blank=True, null=True)
    subject = models.CharField(max_length=255, blank=True, null=True)
    time_slot = models.DateTimeField(blank=True, null=True)
    duration = models.CharField(max_length=100, blank=True, null=True)

    class Meta:
        db_table = 'donations'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.full_name} - {self.donation_type} ({self.status})"
