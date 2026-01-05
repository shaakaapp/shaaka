# Shaaka Backend

Django REST API backend for Shaaka application.

## Setup

1. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Create a `.env` file:
```bash
# The .env file has already been created with your Neon DB credentials
# If you need to recreate it, copy from .env.example:
cp .env.example .env
```

**Note**: The `.env` file is already configured with your Neon DB credentials. OTP is now stored in-memory (no database table needed).

5. Run the server:
```bash
python manage.py runserver
```

The API will be available at `http://localhost:8000/api/`

## API Endpoints

- `POST /api/auth/request-otp/` - Request OTP for registration
- `POST /api/auth/verify-otp/` - Verify OTP
- `POST /api/auth/register/` - Register new user (after OTP verification)
- `POST /api/auth/login/` - Login user
- `GET /api/profile/<user_id>/` - Get user profile
- `PUT /api/profile/<user_id>/update/` - Update user profile

## Deployment to Render

See `render.yaml` for deployment configuration.

