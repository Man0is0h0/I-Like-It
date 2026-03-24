# ⚡ Quickstart & Setup Guide

This guide walks you through setting up the **I Like It** backend services, database migrations, and edge functions.

## 1️⃣ Supabase Project Setup
1. Create a new project on [Supabase.com](https://supabase.com).
2. Go to **Authentication > Providers** and ensure **Email** is enabled. Disable "Confirm email" if you are strictly using custom OTP workflows, though Supabase handles OTP natively.
3. Retrieve your `Project URL` and `anon public key` from **Settings > API**.

## 2️⃣ Database Setup & Migrations
You can run the provided SQL scripts directly in the Supabase **SQL Editor** to bootstrap your database.
1. Copy the contents of `project-backend/schema.sql`.
2. Paste and run it in the Supabase SQL Editor. This will:
   - Create `users`, `folders`, and `links` tables.
   - Set up Row Level Security (RLS) policies.
   - Create the `handle_new_user` trigger.
   - Register the `get_user_id_by_email` function for auth flows.

## 3️⃣ Edge Function (OTP Emailer) Setup
The app uses a Supabase Edge Function to deliver OTP emails natively. You can choose either **Gmail SMTP** or **Resend**.

### Option A: Gmail SMTP (Free)
1. Go to your **Google Account Settings** > **Security**. Ensure 2-Step Verification is enabled.
2. Search for **App passwords** (or go to Security > 2-Step Verification > App passwords).
3. Create a new app password (e.g., "Supabase Auth") and copy the 16-character code.
4. Set your environment secrets inside Supabase:
   ```bash
   supabase secrets set GMAIL_EMAIL="your-email@gmail.com"
   supabase secrets set GMAIL_PASSWORD="your-16-char-app-password"
   ```

### Option B: Resend API (Recommended for Production)
1. Create an account on [Resend.com](https://resend.com) and generate an API Key.
2. Set your environment secret inside Supabase:
   ```bash
   supabase secrets set RESEND_API_KEY="re_123456789..."
   ```

### Deploy the Function
Open a terminal in the `project-backend/` directory and deploy:
```bash
supabase functions deploy send-otp --no-verify-jwt
```

## 4️⃣ Frontend `.env` File
Create a file named `.env` inside the `i_like_it/` directory:
```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR...
```

## 5️⃣ First-Time Admin Setup
To make a user an Admin (grants access to the Admin Dashboard in settings):
1. Sign up normally via the app using your email.
2. Go to your Supabase **SQL Editor** and run:
   ```sql
   UPDATE users SET role = 'admin' WHERE email = 'your-email@gmail.com';
   ```

## ✅ Success Checklist
- [ ] Database tables (`folders`, `links`, `users`) are created.
- [ ] `.env` file exists in the Flutter directory.
- [ ] `flutter pub get` completed successfully.
- [ ] Edge Function `send-otp` is deployed and secrets are set.
- [ ] You can log in via OTP and create a folder!

## 🆘 Troubleshooting
- **OTP emails not arriving?** If using Gmail, verify your `GMAIL_PASSWORD` is an **App Password** (not your standard password) and that 2FA is enabled on your Google account. If using Resend, check your API logs. Ensure the Edge Function deployed successfully.
- **Images not loading for links?** Certain sites (like YouTube) block bots with a 429 error. The extractor has a built-in YouTube bypass, but network blocks can still occur for heavily protected sites.
