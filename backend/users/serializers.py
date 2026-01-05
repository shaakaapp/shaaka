from rest_framework import serializers
from .models import UserProfile


class UserProfileSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False)
    
    class Meta:
        model = UserProfile
        fields = [
            'id', 'full_name', 'mobile_number', 'password',
            'gender', 'category', 'address_line', 'city',
            'state', 'country', 'pincode', 'latitude', 'longitude',
            'profile_pic_url', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def create(self, validated_data):
        password = validated_data.pop('password', None)
        user = UserProfile(**validated_data)
        if password:
            user.set_password(password)
        user.save()
        return user


class LoginSerializer(serializers.Serializer):
    mobile_number = serializers.CharField(max_length=20)
    password = serializers.CharField(write_only=True)


class OTPSerializer(serializers.Serializer):
    mobile_number = serializers.CharField(max_length=20)
    otp_code = serializers.CharField(max_length=6)


class OTPRequestSerializer(serializers.Serializer):
    mobile_number = serializers.CharField(max_length=20)

