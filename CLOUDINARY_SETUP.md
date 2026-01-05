# Cloudinary and Google Maps Setup Guide

## Cloudinary Setup

### 1. Create a Cloudinary Account
1. Go to https://cloudinary.com/
2. Sign up for a free account
3. After signing up, you'll be taken to your dashboard

### 2. Get Your Cloudinary Credentials
1. In your Cloudinary dashboard, you'll see your account details
2. You need these three values:
   - **Cloud Name**: Found in the dashboard (e.g., `your-cloud-name`)
   - **API Key**: Found in the dashboard (e.g., `123456789012345`)
   - **API Secret**: Found in the dashboard (e.g., `abcdefghijklmnopqrstuvwxyz`)

### 3. Add Credentials to Backend `.env` File
Add these lines to your `backend/.env` file:

```env
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
```

**Important**: Never commit your `.env` file to git! It's already in `.gitignore`.

### 4. Install Cloudinary Package
The package is already in `requirements.txt`. Just run:
```bash
cd backend
pip install -r requirements.txt
```

## Google Maps Setup

### 1. Get Google Maps API Key
1. Go to https://console.cloud.google.com/
2. Create a new project or select an existing one
3. Enable the following APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Geocoding API** (optional, for reverse geocoding)

### 2. Create API Key
1. Go to "Credentials" in the Google Cloud Console
2. Click "Create Credentials" → "API Key"
3. Copy your API key
4. (Recommended) Restrict the API key to only the APIs you need

### 3. Add API Key to Flutter App

#### For Android:
1. Open `android/app/src/main/AndroidManifest.xml`
2. Add this inside the `<application>` tag:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

#### For iOS:
1. Open `ios/Runner/AppDelegate.swift`
2. Add this import at the top:
```swift
import GoogleMaps
```
3. In the `application` function, add:
```swift
GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

### 4. Update Flutter Code (Optional)
If you want to use the API key in code, you can add it to a config file:
```dart
// lib/config/app_config.dart
class AppConfig {
  static const String googleMapsApiKey = 'YOUR_API_KEY_HERE';
}
```

## What You Need to Provide

### Required:
1. **Cloudinary Cloud Name** - From your Cloudinary dashboard
2. **Cloudinary API Key** - From your Cloudinary dashboard
3. **Cloudinary API Secret** - From your Cloudinary dashboard
4. **Google Maps API Key** - From Google Cloud Console

### Steps to Complete Setup:

1. **Backend Setup**:
   ```bash
   cd backend
   # Edit .env file and add Cloudinary credentials
   nano .env  # or use your preferred editor
   ```

2. **Flutter Setup**:
   - Add Google Maps API key to AndroidManifest.xml
   - Add Google Maps API key to iOS AppDelegate.swift
   - Run `flutter pub get` to install new packages

3. **Test**:
   - Start the backend server
   - Run the Flutter app
   - Try uploading a profile picture
   - Try selecting a location on the map

## Troubleshooting

### Cloudinary Issues:
- **"Invalid credentials"**: Check your `.env` file has correct values
- **"Upload failed"**: Make sure your Cloudinary account is active
- **"Folder not found"**: The folder `shaaka/profile_pics` will be created automatically

### Google Maps Issues:
- **"Maps not loading"**: Check API key is correctly added to AndroidManifest.xml
- **"Location permission denied"**: Make sure location permissions are granted in app settings
- **"API key invalid"**: Verify the API key in Google Cloud Console

## Notes

- Cloudinary free tier includes:
  - 25 GB storage
  - 25 GB monthly bandwidth
  - 25,000 monthly transformations

- Google Maps free tier includes:
  - $200 credit per month
  - Enough for most small to medium apps

## Security Best Practices

1. **Never commit API keys to git**
2. **Use environment variables for sensitive data**
3. **Restrict Google Maps API key** to your app's package name
4. **Enable billing alerts** in Google Cloud Console
5. **Monitor usage** in both Cloudinary and Google Cloud Console

