# Shaaka - Multi-User Platform

A Flutter application with Django backend supporting Customer, Vendor, and Women Merchant user types.

## Features

- User Registration with OTP Verification
- Login/Authentication
- Three separate home pages for different user categories
- User Profile Management
- Neon PostgreSQL Database Integration
- Django REST API Backend

## Project Structure

```
shaaka/
├── backend/              # Django backend
│   ├── shaaka_backend/   # Django project settings
│   ├── users/            # User app with models, views, serializers
│   ├── requirements.txt  # Python dependencies
│   └── manage.py        # Django management script
├── lib/                  # Flutter app
│   ├── models/          # Data models
│   ├── services/        # API and storage services
│   ├── pages/           # UI pages
│   └── main.dart        # App entry point
└── android/             # Android configuration
```

## Setup Instructions

### Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd backend
   ```

2. **Create virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Create `.env` file**:
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` with your Neon DB credentials:
   ```
   SECRET_KEY=your-secret-key-here
   DEBUG=True
   DB_NAME=your-neon-db-name
   DB_USER=your-neon-db-user
   DB_PASSWORD=your-neon-db-password
   DB_HOST=your-neon-db-host.neon.tech
   DB_PORT=5432
   ```

5. **OTP Storage**:
   OTP is now stored in-memory (no database table needed). OTPs expire after 5 minutes.

6. **Run migrations** (for OTP table):
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

7. **Start the server**:
   ```bash
   python manage.py runserver
   ```

   The API will be available at `http://localhost:8000/api/`

### Flutter App Setup

1. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

2. **Update API base URL** (if needed):
   Edit `lib/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'http://localhost:8000/api';
   // For production: 'https://your-backend.onrender.com/api'
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## API Endpoints

- `POST /api/auth/request-otp/` - Request OTP for registration
  - Body: `{"mobile_number": "1234567890"}`
  - OTP will be displayed in terminal

- `POST /api/auth/verify-otp/` - Verify OTP
  - Body: `{"mobile_number": "1234567890", "otp_code": "123456"}`

- `POST /api/auth/register/` - Register new user (after OTP verification)
  - Body: User profile data

- `POST /api/auth/login/` - Login user
  - Body: `{"mobile_number": "1234567890", "password": "password"}`

- `GET /api/profile/<user_id>/` - Get user profile

- `PUT /api/profile/<user_id>/update/` - Update user profile

## User Flow

1. **Registration**:
   - User enters mobile number
   - OTP is sent (displayed in terminal)
   - User verifies OTP
   - User completes registration form
   - User is redirected to appropriate home page based on category

2. **Login**:
   - User enters mobile number and password
   - User is authenticated and redirected to appropriate home page

3. **Home Pages**:
   - Customer → `HomeCustomerPage`
   - Vendor → `HomeVendorPage`
   - Women Merchant → `HomeWomenMerchantPage`

4. **Profile**:
   - All users can view and edit their profile
   - Profile page accessible from home page

## Deployment

See `DEPLOYMENT.md` for detailed instructions on deploying to Render.

## Notes

- OTP is displayed in the terminal/console for development purposes
- OTP is stored in-memory (no database table needed)
- The `user_profiles` table should already exist in your Neon DB
- Update CORS settings in `backend/shaaka_backend/settings.py` for production

## Troubleshooting

1. **Database Connection Issues**:
   - Verify Neon DB credentials in `.env`
   - Check if SSL mode is required
   - Ensure database allows connections from your IP

2. **OTP Not Working**:
   - Check if `otp_verification` table exists
   - Check terminal/console for OTP code
   - Verify OTP hasn't expired (5 minutes)

3. **CORS Errors**:
   - Update `CORS_ALLOWED_ORIGINS` in settings.py
   - Ensure `django-cors-headers` is installed

## License

This project is for educational purposes.
