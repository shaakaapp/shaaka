from django.db import models
from django.utils import timezone
import bcrypt


class UserProfile(models.Model):
    CATEGORY_CHOICES = [
        ('Customer', 'Customer'),
        ('Vendor', 'Vendor'),
        ('Women Merchant', 'Women Merchant'),
    ]

    id = models.BigAutoField(primary_key=True)
    full_name = models.CharField(max_length=255)
    mobile_number = models.CharField(max_length=20, unique=True)
    password_hash = models.TextField()
    gender = models.CharField(max_length=20, blank=True, null=True)
    category = models.CharField(max_length=30, choices=CATEGORY_CHOICES)
    address_line = models.TextField(blank=True, null=True)
    city = models.CharField(max_length=120, blank=True, null=True)
    state = models.CharField(max_length=120, blank=True, null=True)
    country = models.CharField(max_length=120, blank=True, null=True)
    pincode = models.CharField(max_length=10, blank=True, null=True)
    latitude = models.FloatField(blank=True, null=True)
    longitude = models.FloatField(blank=True, null=True)
    profile_pic_url = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'user_profiles'
        managed = False  # Since table already exists in Neon DB

    def set_password(self, raw_password):
        """Hash and set the password."""
        salt = bcrypt.gensalt()
        self.password_hash = bcrypt.hashpw(raw_password.encode('utf-8'), salt).decode('utf-8')

    def check_password(self, raw_password):
        """Check if the provided password matches the hash."""
        return bcrypt.checkpw(raw_password.encode('utf-8'), self.password_hash.encode('utf-8'))

    def save(self, *args, **kwargs):
        self.updated_at = timezone.now()
        super().save(*args, **kwargs)


class UserAddress(models.Model):
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='addresses')
    name = models.CharField(max_length=255, help_text="Label for address e.g., Home, Work")
    address_line = models.TextField()
    city = models.CharField(max_length=120)
    state = models.CharField(max_length=120)
    country = models.CharField(max_length=120, default='India')
    pincode = models.CharField(max_length=10)
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'user_addresses'

    def __str__(self):
        return f"{self.name} - {self.user.full_name}"
