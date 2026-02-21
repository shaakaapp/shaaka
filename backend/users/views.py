from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import UserProfile
from .serializers import (
    UserProfileSerializer, LoginSerializer,
    OTPSerializer, OTPRequestSerializer,
    UserAddressSerializer
)
from .models import UserProfile, UserAddress
import random
import string
from django.utils import timezone
from datetime import timedelta
import cloudinary
import cloudinary.uploader
from decouple import config
from drf_spectacular.utils import extend_schema, OpenApiTypes
from rest_framework import serializers

class UploadImageSerializer(serializers.Serializer):
    image = serializers.FileField()
    type = serializers.CharField(required=False, default='profile')

# Configure Cloudinary
cloudinary.config(
    cloud_name=config('CLOUDINARY_CLOUD_NAME', default=''),
    api_key=config('CLOUDINARY_API_KEY', default=''),
    api_secret=config('CLOUDINARY_API_SECRET', default='')
)

# In-memory OTP storage
# Format: {mobile_number: {'otp': '123456', 'created_at': datetime, 'is_verified': False}}
otp_storage = {}


def generate_otp():
    """Generate a 6-digit OTP."""
    return ''.join(random.choices(string.digits, k=6))


def cleanup_expired_otps():
    """Remove expired OTPs (older than 5 minutes)."""
    current_time = timezone.now()
    expired_numbers = []
    for mobile_number, otp_data in otp_storage.items():
        if current_time - otp_data['created_at'] > timedelta(minutes=5):
            expired_numbers.append(mobile_number)
    for number in expired_numbers:
        del otp_storage[number]


@extend_schema(request=UploadImageSerializer, responses={200: OpenApiTypes.OBJECT})
@api_view(['POST'])
def upload_image(request):
    """Upload image to Cloudinary."""
    if 'image' not in request.FILES:
        return Response(
            {'error': 'No image file provided'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        image_file = request.FILES['image']
        
        upload_type = request.data.get('type', 'profile')
        
        if upload_type == 'product':
            folder = 'shaaka/products'
            transformation = [
                {'quality': 'auto'},
                {'fetch_format': 'auto'}
            ]
        else:
            folder = 'shaaka/profile_pics'
            transformation = [
                {'width': 400, 'height': 400, 'crop': 'fill', 'gravity': 'face'},
                {'quality': 'auto'},
                {'format': 'jpg'}
            ]

        # Upload to Cloudinary
        upload_result = cloudinary.uploader.upload(
            image_file,
            folder=folder,
            resource_type='image',
            transformation=transformation
        )
        
        return Response({
            'success': True,
            'url': upload_result['secure_url'],
            'public_id': upload_result['public_id']
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': f'Failed to upload image: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@extend_schema(request=OTPRequestSerializer, responses={200: OpenApiTypes.OBJECT})
@api_view(['POST'])
def request_otp(request):
    """Request OTP for registration."""
    serializer = OTPRequestSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    mobile_number = serializer.validated_data['mobile_number']
    
    # Cleanup expired OTPs
    cleanup_expired_otps()
    
    # Check if user already exists
    try:
        UserProfile.objects.get(mobile_number=mobile_number)
        return Response(
            {'error': 'User with this mobile number already exists'},
            status=status.HTTP_400_BAD_REQUEST
        )
    except UserProfile.DoesNotExist:
        pass
    
    # Generate OTP
    otp_code = generate_otp()
    
    # Store OTP in memory
    otp_storage[mobile_number] = {
        'otp': otp_code,
        'created_at': timezone.now(),
        'is_verified': False
    }
    
    # Print OTP to terminal (for development)
    print("\n" + "="*60)
    print(" " * 15 + "OTP VERIFICATION")
    print("="*60)
    print(f"Mobile Number: {mobile_number}")
    print(f"OTP Code: {otp_code}")
    print(f"Valid for: 5 minutes")
    print("="*60)
    print("⚠️  IMPORTANT: Check this terminal/console for the OTP")
    print("="*60 + "\n")
    
    return Response({
        'message': 'OTP sent successfully',
        'mobile_number': mobile_number
    }, status=status.HTTP_200_OK)


@extend_schema(request=OTPSerializer, responses={200: OpenApiTypes.OBJECT})
@api_view(['POST'])
def verify_otp(request):
    """Verify OTP and register user."""
    serializer = OTPSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    mobile_number = serializer.validated_data['mobile_number']
    otp_code = serializer.validated_data['otp_code']
    
    # Cleanup expired OTPs
    cleanup_expired_otps()
    
    # Check if OTP exists in memory
    if mobile_number not in otp_storage:
        return Response(
            {'error': 'OTP not found. Please request a new OTP'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    otp_data = otp_storage[mobile_number]
    
    # Check if OTP is expired (5 minutes)
    if timezone.now() - otp_data['created_at'] > timedelta(minutes=5):
        del otp_storage[mobile_number]
        return Response(
            {'error': 'OTP has expired'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Check if OTP matches
    if otp_data['otp'] != otp_code:
        return Response(
            {'error': 'Invalid OTP'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Check if already verified
    if otp_data['is_verified']:
        return Response(
            {'error': 'OTP already verified'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Mark OTP as verified
    otp_data['is_verified'] = True
    
    return Response({
        'message': 'OTP verified successfully',
        'mobile_number': mobile_number
    }, status=status.HTTP_200_OK)


@extend_schema(request=UserProfileSerializer, responses={201: UserProfileSerializer})
@api_view(['POST'])
def register(request):
    """Register a new user."""
    data = request.data.copy()
    
    # Check if OTP was verified
    mobile_number = data.get('mobile_number')
    if not mobile_number:
        return Response(
            {'error': 'Mobile number is required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Cleanup expired OTPs
    cleanup_expired_otps()
    
    # Check if OTP exists and is verified
    if mobile_number not in otp_storage:
        return Response(
            {'error': 'Please verify OTP first'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    otp_data = otp_storage[mobile_number]
    
    if not otp_data['is_verified']:
        return Response(
            {'error': 'Please verify OTP first'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Check if user already exists
    try:
        UserProfile.objects.get(mobile_number=mobile_number)
        # Remove OTP from storage
        del otp_storage[mobile_number]
        return Response(
            {'error': 'User already exists'},
            status=status.HTTP_400_BAD_REQUEST
        )
    except UserProfile.DoesNotExist:
        pass
    
    serializer = UserProfileSerializer(data=data)
    if serializer.is_valid():
        user = serializer.save()
        # Delete OTP from storage after successful registration
        if mobile_number in otp_storage:
            del otp_storage[mobile_number]
        return Response(
            UserProfileSerializer(user).data,
            status=status.HTTP_201_CREATED
        )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@extend_schema(request=LoginSerializer, responses={200: OpenApiTypes.OBJECT})
@api_view(['POST'])
def login(request):
    """Login user."""
    serializer = LoginSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    mobile_number = serializer.validated_data['mobile_number']
    password = serializer.validated_data['password']
    
    try:
        user = UserProfile.objects.get(mobile_number=mobile_number)
        if user.check_password(password):
            return Response({
                'message': 'Login successful',
                'user': UserProfileSerializer(user).data
            }, status=status.HTTP_200_OK)
        else:
            return Response(
                {'error': 'Invalid credentials'},
                status=status.HTTP_401_UNAUTHORIZED
            )
    except UserProfile.DoesNotExist:
        return Response(
            {'error': 'User not found'},
            status=status.HTTP_404_NOT_FOUND
        )


@extend_schema(responses={200: UserProfileSerializer})
@api_view(['GET'])
def get_profile(request, user_id):
    """Get user profile."""
    try:
        user = UserProfile.objects.get(id=user_id)
        return Response(
            UserProfileSerializer(user).data,
            status=status.HTTP_200_OK
        )
    except UserProfile.DoesNotExist:
        return Response(
            {'error': 'User not found'},
            status=status.HTTP_404_NOT_FOUND
        )


@extend_schema(request=UserProfileSerializer, responses={200: UserProfileSerializer})
@api_view(['PUT', 'PATCH'])
def update_profile(request, user_id):
    """Update user profile."""
    try:
        user = UserProfile.objects.get(id=user_id)
        serializer = UserProfileSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            # Handle password update
            if 'password' in request.data:
                user.set_password(request.data['password'])
            serializer.save()
            return Response(
                UserProfileSerializer(user).data,
                status=status.HTTP_200_OK
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except UserProfile.DoesNotExist:
        return Response(
            {'error': 'User not found'},
            status=status.HTTP_404_NOT_FOUND
        )

@extend_schema(request=OpenApiTypes.OBJECT, responses={200: OpenApiTypes.OBJECT})
@api_view(['POST'])
def change_password(request, user_id):
    """Change user password securely."""
    try:
        user = UserProfile.objects.get(id=user_id)
        current_password = request.data.get('current_password')
        new_password = request.data.get('new_password')

        if not current_password or not new_password:
            return Response(
                {'error': 'Both current and new passwords are required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not user.check_password(current_password):
            return Response(
                {'error': 'Incorrect current password'},
                status=status.HTTP_400_BAD_REQUEST
            )

        user.set_password(new_password)
        user.save()

        return Response(
            {'message': 'Password changed successfully'},
            status=status.HTTP_200_OK
        )

    except UserProfile.DoesNotExist:
        return Response(
            {'error': 'User not found'},
            status=status.HTTP_404_NOT_FOUND
        )

@extend_schema(methods=['GET'], responses={200: OpenApiTypes.OBJECT})
@extend_schema(methods=['POST'], request=UserAddressSerializer, responses={201: UserAddressSerializer})
@api_view(['GET', 'POST'])
def user_addresses_list_create(request, user_id):
    try:
        user = UserProfile.objects.get(id=user_id)
    except UserProfile.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        # Return profile address (as a special entry) + saved addresses
        addresses = UserAddress.objects.filter(user=user).order_by('-is_default', '-created_at')
        serializer = UserAddressSerializer(addresses, many=True)
        
        # Add Profile Address manually if it exists
        profile_address = {
            'id': 'profile', # Special ID
            'name': 'Profile Address (Default)',
            'address_line': user.address_line,
            'city': user.city,
            'state': user.state,
            'country': user.country or 'India',
            'pincode': user.pincode,
            'is_default': True # Treat as default usually, or based on logic
        }
        
        # You might want to merge them or just return the saved ones
        # For now, let's return only saved addresses here, but frontend can manage merging.
        # Actually, let's include profile address in the response if user wants all options.
        
        return Response({
            'profile_address': profile_address,
            'saved_addresses': serializer.data
        })
    
    elif request.method == 'POST':
        serializer = UserAddressSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@extend_schema(methods=['PUT'], request=UserAddressSerializer, responses={200: UserAddressSerializer})
@extend_schema(methods=['DELETE'], responses={204: None})
@api_view(['PUT', 'DELETE'])
def user_address_detail(request, user_id, address_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        address = UserAddress.objects.get(id=address_id, user=user)
    except (UserProfile.DoesNotExist, UserAddress.DoesNotExist):
        return Response({'error': 'Address not found'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'PUT':
        serializer = UserAddressSerializer(address, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        address.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
