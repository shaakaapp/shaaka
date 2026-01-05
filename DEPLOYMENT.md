# Deployment Guide for Shaaka Backend to Render

This guide will help you deploy your Django backend to Render.

## Prerequisites

1. A Render account (sign up at https://render.com)
2. Your Neon DB connection string
3. Git repository for your code

## Step 1: Prepare Your Backend

1. Make sure your `backend` folder contains all necessary files:
   - `requirements.txt`
   - `Procfile`
   - `render.yaml` (optional, for automated setup)
   - All Django project files

## Step 2: Update Environment Variables

Before deploying, update the `baseUrl` in `lib/services/api_service.dart`:

```dart
// Change this line in lib/services/api_service.dart
static const String baseUrl = 'https://your-backend-name.onrender.com/api';
```

## Step 3: Deploy to Render

### Option A: Using Render Dashboard

1. **Go to Render Dashboard**: https://dashboard.render.com
2. **Click "New +"** → **"Web Service"**
3. **Connect your repository** (GitHub/GitLab/Bitbucket)
4. **Configure the service**:
   - **Name**: `shaaka-backend` (or your preferred name)
   - **Environment**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn shaaka_backend.wsgi:application`
   - **Root Directory**: `backend`

5. **Add Environment Variables**:
   - `SECRET_KEY`: Generate a secure Django secret key
   - `DEBUG`: `False` (for production)
   - `DB_NAME`: Your Neon database name
   - `DB_USER`: Your Neon database user
   - `DB_PASSWORD`: Your Neon database password
   - `DB_HOST`: Your Neon database host (e.g., `ep-xxx-xxx.us-east-2.aws.neon.tech`)
   - `DB_PORT`: `5432`

6. **Click "Create Web Service"**

### Option B: Using render.yaml (Automated)

If you have `render.yaml` in your repository:

1. Go to Render Dashboard
2. Click "New +" → "Blueprint"
3. Connect your repository
4. Render will automatically detect and use `render.yaml`

## Step 4: OTP Storage

**Note**: OTP is now stored in-memory (no database table needed). OTPs automatically expire after 5 minutes.

## Step 5: Update CORS Settings

After deployment, update `backend/shaaka_backend/settings.py`:

```python
CORS_ALLOWED_ORIGINS = [
    "https://your-app-domain.com",  # Add your Flutter app domain
]

# Remove or set to False in production
CORS_ALLOW_ALL_ORIGINS = False
```

## Step 6: Run Migrations (if needed)

Migrations are optional since OTP is stored in-memory. Only run if you have other models to migrate:

```bash
python manage.py makemigrations
python manage.py migrate
```

## Step 7: Test Your Deployment

1. Visit your Render service URL: `https://your-backend-name.onrender.com`
2. Test the API endpoints:
   - `POST https://your-backend-name.onrender.com/api/auth/request-otp/`
   - `POST https://your-backend-name.onrender.com/api/auth/verify-otp/`
   - `POST https://your-backend-name.onrender.com/api/auth/register/`
   - `POST https://your-backend-name.onrender.com/api/auth/login/`

## Step 8: Update Flutter App

1. Update `lib/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'https://your-backend-name.onrender.com/api';
   ```

2. Rebuild your Flutter app:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Troubleshooting

### Common Issues:

1. **Database Connection Error**:
   - Verify your Neon DB credentials
   - Check if your Neon DB allows connections from Render's IPs
   - Ensure SSL mode is set correctly

2. **CORS Errors**:
   - Update `CORS_ALLOWED_ORIGINS` in settings.py
   - Make sure `django-cors-headers` is installed

3. **Static Files Not Loading**:
   - Add `whitenoise` to requirements.txt for static file serving
   - Update settings.py to use WhiteNoise

4. **OTP Not Working**:
   - OTP is stored in-memory (no database table needed)
   - Verify the OTP is being printed in Render logs
   - OTP expires after 5 minutes

## Additional Notes

- Render provides free tier with some limitations
- Your service may spin down after inactivity (free tier)
- Consider upgrading for production use
- Monitor your Render dashboard for logs and errors

## Security Recommendations

1. Never commit `.env` files
2. Use strong `SECRET_KEY` in production
3. Set `DEBUG=False` in production
4. Use HTTPS (Render provides this automatically)
5. Regularly update dependencies

