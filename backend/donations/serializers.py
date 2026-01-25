from rest_framework import serializers
from .models import Donation

class DonationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Donation
        fields = [
            'id', 'user', 'donation_type', 'status', 'created_at',
            'item_name', 'description', 'quantity', 'item_image', 'pickup_address', 'contact_number', 'email',
            'amount', 'payment_screenshot', 'message',
            'profession', 'subject', 'time_slot', 'duration'
        ]
        read_only_fields = ['id', 'user', 'status', 'created_at']

    def validate(self, data):
        donation_type = data.get('donation_type')

        if donation_type in ['Food', 'Clothes']:
            # item_name validation already covered by generic requirement if needed, but here we enforce it for Food/Clothes
            if not data.get('item_name'):
                raise serializers.ValidationError({"item_name": "This field is required for Food/Clothes donation."})
            if not data.get('pickup_address'):
                raise serializers.ValidationError({"pickup_address": "This field is required for Food/Clothes donation."})
        
        elif donation_type == 'Money':
            if not data.get('amount'):
                raise serializers.ValidationError({"amount": "This field is required for Money donation."})
            if not data.get('payment_screenshot'):
                raise serializers.ValidationError({"payment_screenshot": "Payment screenshot is required."})

        elif donation_type == 'Education':
             if not data.get('item_name'): # We use item_name for Name
                 raise serializers.ValidationError({"item_name": "Name is required."})
             if not data.get('profession'):
                 raise serializers.ValidationError({"profession": "Profession is required."})
             if not data.get('subject'):
                 raise serializers.ValidationError({"subject": "Subject is required."})
             if not data.get('time_slot'):
                 raise serializers.ValidationError({"time_slot": "Time Slot is required."})
             if not data.get('duration'):
                 raise serializers.ValidationError({"duration": "Duration is required."})
        
        return data
