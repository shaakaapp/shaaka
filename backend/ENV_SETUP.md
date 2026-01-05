# Environment Setup

The `.env` file has been created with your Neon DB credentials. 

If you need to recreate it, create a file named `.env` in the `backend/` directory with the following content:

```
SECRET_KEY=django-insecure-change-this-to-a-secure-key-in-production
DEBUG=True
DB_NAME=neondb
DB_USER=neondb_owner
DB_PASSWORD=npg_ZPjzbf7Nx6Kv
DB_HOST=ep-bold-bonus-a1abfgjo-pooler.ap-southeast-1.aws.neon.tech
DB_PORT=5432
```

**Important**: 
- The `.env` file is in `.gitignore` and won't be committed to git
- Change the `SECRET_KEY` to a secure random string for production
- Set `DEBUG=False` when deploying to production

