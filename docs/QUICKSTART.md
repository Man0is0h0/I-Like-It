# ⚡ Comprehensive Quickstart & Setup Guide

Welcome to the detailed setup guide for the **I Like It** application. This document will walk you through the entire process of getting your local environment running, configuring the backend services (Supabase), deploying edge functions, and launching the app on your device or emulator.

---

## 🏗️ 1. Development Environment Setup

Before touching the codebase, assure your machine meets the requirements for Flutter development.

### Prerequisites
- **Flutter SDK:** Version 3.10.7 or later. Verify with `flutter --version`.
- **Dart SDK:** Bundled with Flutter.
- **IDE:** Visual Studio Code (recommended with Flutter/Dart extensions) or Android Studio.
- **Git:** For version control and repository cloning.
- **Supabase CLI:** (Optional but recommended) For local edge function testing and database resets. Install via npm: `npm install -g supabase`.

### Cloning the Repository
1. Open your terminal and navigate to your preferred workspace.
2. Clone the repository: `git clone <repository-url> i-like-it`
3. Enter the project directory: `cd i-like-it`

---

## 🗄️ 2. Supabase Cloud Backend Setup

The application relies on Supabase for PostgreSQL, Authentication, and Edge Functions. 

### Creating the Project
1. Log in to your [Supabase Dashboard](https://supabase.com/dashboard).
2. Click **New Project**. Select your organization, provide a suitable name (e.g., "I Like It App"), and generate a secure database password. Ensure you save this password.
3. Choose a region closest to your target audience to reduce latency.
4. Wait a few minutes for the project provisioning to complete.

### Configuring Authentication
1. Navigate to **Authentication > Providers** in the Supabase sidebar.
2. Enable the **Email** provider.
3. *Crucial Step:* If you are handling OTPs strictly through the custom Edge Function, you can heavily customize the email templates, but standard Supabase OTPs work natively as well. 
4. Under **Authentication > URL Configuration**, set your `Site URL` if you plan to use deep-linking redirects for web or standard auth flows.

### Retrieving API Keys
1. Go to **Project Settings > API**.
2. Locate the `Project URL` and `anon public` key. 
3. *Note:* Treat these as your public access points. They are safe to include in the client app.

---

## 🗃️ 3. Database Schema & Migrations

The database structure relies on specific tables, Row Level Security (RLS) policies, and triggers.

### Running the Schema Script
1. Open the Supabase Dashboard and navigate to the **SQL Editor**.
2. Open the local file located at `project-backend/schema.sql` in your IDE.
3. Copy the entire contents of this file.
4. Paste it into a new query window in the Supabase SQL Editor and hit **Run**.

### What this script does:
- **`users` Table:** Stores user profiles tied directly to Supabase Auth (`auth.uid()`).
- **`folders` Table:** Organizes links. Includes RLS ensuring users only see their own folders.
- **`links` Table:** Stores the bookmarked URLs along with scraped metadata (title, icon, image).
- **Triggers & Functions:** Automatically creates a public profile row in `users` whenever a new identity is created in `auth.users`.

---

## ✉️ 4. Edge Function Configuration (OTP Emailer)

The application uses a Deno-based Edge Function to securely send OTP login emails without exposing SMTP credentials to the client.

### Option A: Gmail SMTP (Free Tier)
Perfect for development or small-scale usage.
1. Log into your Google Account and navigate to **Security**.
2. Ensure **2-Step Verification** is enabled.
3. Search for **App passwords**. Create a new app password named "Supabase Auth" and copy the 16-character string.
4. Set the secrets directly via the Supabase CLI in your terminal:
   ```bash
   supabase secrets set GMAIL_EMAIL="your-email@gmail.com"
   supabase secrets set GMAIL_PASSWORD="your-16-char-app-password"
   ```

### Option B: Resend API (Production Recommended)
Much higher reliability and better deliverability rates.
1. Create a free account at [Resend](https://resend.com/).
2. Add and verify your domain.
3. Generate an API Key in the Resend dashboard.
4. Insert the secret into Supabase:
   ```bash
   supabase secrets set RESEND_API_KEY="re_123456789..."
   ```

### Deploying the Function
1. Open a terminal at the project root.
2. Ensure you are logged into the CLI: `supabase login`.
3. Link your project: `supabase link --project-ref your-project-ref`.
4. Deploy the function:
   ```bash
   cd project-backend
   supabase functions deploy send-otp --no-verify-jwt
   ```

---

## 📱 5. Flutter App Configuration

Connect your mobile application to your newly provisioned backend.

### Setting up `.env`
1. Navigate to the frontend directory: `cd i_like_it`.
2. Duplicate `.env.example` and rename it to `.env`.
3. Fill in the variables with the keys you retrieved in Step 2:
   ```env
   SUPABASE_URL=https://your-project-ref.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR...
   ```
4. *Important:* The `.env` file is already in your `.gitignore` to prevent secret leaks.

### Installing Dependencies
Run the following command in the `i_like_it` directory to fetch all pub packages:
```bash
flutter pub get
```

---

## 👑 6. First-Time Admin Setup

Certain in-app settings and dashboards are locked behind an admin role. 

1. Launch the app and sign up normally using your email address and OTP.
2. Once logged in (you will see an empty folder screen), return to the Supabase Dashboard.
3. Open the **SQL Editor** and run the following command to elevate your account:
   ```sql
   UPDATE users SET role = 'admin' WHERE email = 'your-email@example.com';
   ```
4. Restart the app. The "Admin Settings" tile will now be visible in your profile menu.

---

## ✅ 7. Verification Sandbox

To assure everything went perfectly, verify these key functionalities:
1. **Authentication:** Attempt to sign out and sign back in. Did you receive the OTP email?
2. **Database Write:** Create a new folder named "My First Folder". Check the `folders` table in Supabase to verify the row exists.
3. **Link Scrape:** Add `https://flutter.dev` to your folder. The app should successfully scrape the Flutter logo and page title.

---

## 🆘 Troubleshooting & Common Issues

- **Build Failures on iOS:** Ensure CocoaPods is updated. Run `cd ios && pod install --repo-update`.
- **OTP Emails Not Sending:** Check your Edge Function logs in the Supabase Dashboard. If using Gmail, double-check that you used an *App Password* and not your standard login password.
- **Supabase Connection Errors:** Ensure your internal device emulator has network access. The `SUPABASE_URL` must exact-match without a trailing slash.
- **Link Scraper Fails (Timeout/429):** Some heavily protected sites block generic scraping user agents. The app has fallback handlers, but strict CDNs (like Cloudflare) may deny standard HTTP requests.

---
**Happy coding! You are now fully set up to develop and expand the app.**
