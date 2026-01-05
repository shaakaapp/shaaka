# Quick Start Guide

## Backend Setup (5 minutes)

1. **Go to backend folder**:
   ```bash
   cd backend
   ```

2. **Create and activate virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   ```

3. **Install packages**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Create `.env` file** (copy from `.env.example` and fill in your Neon DB details):
   ```bash
   # Copy the example file
   # Then edit .env with your Neon DB credentials
   ```

5. **Run migrations** (optional, only if needed):
   ```bash
   python manage.py makemigrations users
   python manage.py migrate
   ```

7. **Start server**:
   ```bash
   python manage.py runserver
   ```

   ✅ Backend running at `http://localhost:8000`

## Flutter App Setup (2 minutes)

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the app**:
   ```bash
   flutter run
   ```

## Test the Flow

1. **Open the app** → You'll see the Login page
2. **Click "Register"** → Go to registration page
3. **Enter mobile number** → Click "Send OTP"
4. **Check terminal** → OTP will be printed (e.g., `OTP for 1234567890: 123456`)
5. **Enter OTP** → Click "Verify OTP"
6. **Fill registration form** → Select category (Customer/Vendor/Women Merchant)
7. **Click Register** → You'll be redirected to the appropriate home page
8. **Click profile icon** → View/edit your profile
9. **Logout** → Test login with your credentials

## Important Notes

- **OTP appears in terminal/console**, not via SMS (for development)
- **User profiles table** must already exist in Neon DB
- **OTP table** needs to be created (use the SQL script)
- **Update API URL** in `lib/services/api_service.dart` when deploying

## Troubleshooting

**Can't connect to database?**
- Check `.env` file has correct Neon DB credentials
- Verify database allows connections from your IP

**OTP not working?**
- OTP is stored in-memory (no database table needed)
- Check terminal for OTP code (not SMS)
- OTP expires after 5 minutes

**App can't reach backend?**
- Ensure backend is running on `http://localhost:8000`
- Check `baseUrl` in `lib/services/api_service.dart`

