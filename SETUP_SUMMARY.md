# Setup Summary - Cloudinary & Google Maps Integration

## ✅ What Has Been Implemented

### Backend (Django)
1. **Cloudinary Integration**
   - Added `cloudinary` and `Pillow` to requirements.txt
   - Created image upload endpoint: `POST /api/upload/image/`
   - Images are automatically optimized (400x400, face detection, auto quality)
   - Images stored in `shaaka/profile_pics` folder on Cloudinary

2. **Updated Models & Views**
   - Profile picture URL stored in `profile_pic_url` field
   - Location URL stored in `location_url` field (Google Maps link format)

### Flutter App
1. **Profile Picture Upload**
   - Image picker integrated in registration page
   - Image picker integrated in profile page (when editing)
   - Images uploaded to Cloudinary automatically
   - Preview shown before upload

2. **Location Picker**
   - Google Maps integration
   - Interactive map to select location
   - Current location detection
   - Draggable marker
   - Location coordinates saved as Google Maps URL

3. **New Dependencies Added**
   - `image_picker` - For selecting images from gallery
   - `google_maps_flutter` - For map display
   - `geolocator` - For getting current location
   - `permission_handler` - For location permissions

## 📋 What You Need to Provide

### 1. Cloudinary Credentials
Get these from https://cloudinary.com/ dashboard:

- **Cloud Name**: Your cloud name (e.g., `my-cloud-name`)
- **API Key**: Your API key (e.g., `123456789012345`)
- **API Secret**: Your API secret (e.g., `abcdefghijklmnopqrstuvwxyz`)

**Add to `backend/.env` file:**
```env
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
```

### 2. Google Maps API Key
Get this from https://console.cloud.google.com/:

1. Create a project (or use existing)
2. Enable "Maps SDK for Android" and "Maps SDK for iOS"
3. Create an API Key
4. Copy the API key

**Add to `android/app/src/main/AndroidManifest.xml`:**
Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key (line 36)

**For iOS** (if deploying to iOS):
Add to `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps

// In application function:
GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

## 🚀 Next Steps

### 1. Install Backend Dependencies
```bash
cd backend
pip install -r requirements.txt
```

### 2. Update Environment Variables
Edit `backend/.env` and add your Cloudinary credentials

### 3. Update AndroidManifest.xml
Edit `android/app/src/main/AndroidManifest.xml` and replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your Google Maps API key

### 4. Install Flutter Dependencies
```bash
flutter pub get
```

### 5. Run the App
```bash
# Terminal 1: Start backend
cd backend
python manage.py runserver

# Terminal 2: Run Flutter app
flutter run
```

## 📱 Features Available

### Registration Page
- ✅ Upload profile picture (camera icon on profile picture)
- ✅ Select location on map (button after pincode field)
- ✅ All other registration fields

### Profile Page
- ✅ Upload/change profile picture (when editing)
- ✅ Update location on map (when editing)
- ✅ Edit all profile information

## 🔧 How It Works

1. **Profile Picture Flow**:
   - User taps camera icon
   - Image picker opens gallery
   - User selects image
   - Image is uploaded to Cloudinary
   - Cloudinary URL is saved to database
   - Image displays in app

2. **Location Flow**:
   - User taps "Select Location on Map" button
   - Map opens with current location (if permission granted)
   - User can drag marker or tap map to select location
   - Coordinates are saved as Google Maps URL
   - Location is saved to database

## 📝 Important Notes

1. **Cloudinary Free Tier**: 
   - 25 GB storage
   - 25 GB monthly bandwidth
   - 25,000 monthly transformations
   - Perfect for development and small apps

2. **Google Maps Free Tier**:
   - $200 credit per month
   - Covers most small to medium apps
   - Monitor usage in Google Cloud Console

3. **Security**:
   - Never commit `.env` file (already in `.gitignore`)
   - Never commit API keys
   - Restrict Google Maps API key to your app package name

## 🐛 Troubleshooting

### Images not uploading?
- Check Cloudinary credentials in `.env` file
- Check backend logs for errors
- Verify Cloudinary account is active

### Map not loading?
- Check Google Maps API key in AndroidManifest.xml
- Verify API key is enabled for Maps SDK
- Check location permissions are granted

### Location not working?
- Grant location permissions in app settings
- Check if location services are enabled on device
- Verify Google Maps API key is correct

## 📚 Documentation

- Cloudinary Setup: See `CLOUDINARY_SETUP.md`
- Deployment: See `DEPLOYMENT.md`
- Quick Start: See `QUICK_START.md`

