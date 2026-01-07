from rest_framework import serializers
from .models import Donation

class DonationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Donation
        fields = [
            'id', 'user', 'donation_type', 'status', 'created_at',
            'item_name', 'description', 'quantity', 'item_image', 'pickup_address', 'contact_number', 'email',
            'amount', 'payment_screenshot', 'message'
        ]
        read_only_fields = ['id', 'user', 'status', 'created_at']

    def validate(self, data):
        donation_type = data.get('donation_type')

        if donation_type in ['Food', 'Clothes']:
            if not data.get('item_name'):
                raise serializers.ValidationError({"item_name": "This field is required for Food/Clothes donation."})
            if not data.get('pickup_address'):
                raise serializers.ValidationError({"pickup_address": "This field is required for Food/Clothes donation."})
        
        elif donation_type == 'Money':
            if not data.get('amount'):
                raise serializers.ValidationError({"amount": "This field is required for Money donation."})
            if not data.get('payment_screenshot'):
                raise serializers.ValidationError({"payment_screenshot": "Payment screenshot is required."})
        
        return data
