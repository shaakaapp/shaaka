from rest_framework import status
from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from users.models import UserProfile
from .serializers import DonationSerializer

@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def create_donation(request, user_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        serializer = DonationSerializer(data=request.data)
        
        if serializer.is_valid():
            serializer.save(user=user)
            return Response({'success': True, 'data': serializer.data}, status=status.HTTP_201_CREATED)
        else:
             return Response({'success': False, 'error': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
             
    except UserProfile.DoesNotExist:
        return Response({'success': False, 'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
