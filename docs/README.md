# 🌟 I Like It

**A collaborative and personal folder-based bookmark and link management app with offline support and cloud sync.**

## 📌 Features
- 📂 **Folder Management:** Organize your links into custom folders with unique AI-assigned icons.
- 🔗 **Smart Link Saving:** Automatically extracts high-quality thumbnails, titles, and descriptions from pasted URLs (including YouTube video thumbnails!).
- ☁️ **Cloud Sync & Offline Mode:** Built-first for offline usage with seamless background sync to Supabase.
- 📧 **Passwordless Authentication:** Secure Email & OTP-based login flow.
- 🌓 **Theming:** Sleek, modern Glassmorphism UI with Light, Dark, and System theme support.
- 🚀 **Native Sharing:** Share your curated links directly via native iOS/Android share sheets.

## 🛠 Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.10.7+)
- [Supabase CLI](https://supabase.com/docs/guides/cli) (Optional, for backend local development)
- Android Studio / Xcode for platform builds.

## 🚀 Quick Setup (1-2-3)
1. **Clone & Install**
   ```bash
   git clone <your-repo-url>
   cd i_like_it
   flutter pub get
   ```
2. **Environment Configuration**
   Copy `.env.example` to `.env` in the `i_like_it` folder and populate your Supabase URLs and Anon Keys.
3. **Run the App**
   ```bash
   flutter run
   ```

## 🔐 Environment Variables
> **⚠️ WARNING:** Never commit your `.env` file or your `SERVICE_ROLE` keys to version control!

| Variable | Location | Safe for Client? | Description |
|----------|----------|------------------|-------------|
| `SUPABASE_URL` | `i_like_it/.env` | ✅ Yes | Your public Supabase Project URL. |
| `SUPABASE_ANON_KEY` | `i_like_it/.env` | ✅ Yes | Your public Supabase Anonymous Key. |
| `GMAIL_EMAIL` | Edge Function Setup | ❌ No | Backend SMTP email address for OTPs (if using Gmail). |
| `GMAIL_PASSWORD` | Edge Function Setup | ❌ No | App password for Gmail SMTP (stored in Supabase Secrets). |
| `RESEND_API_KEY` | Edge Function Setup | ❌ No | API key for production emails (if using Resend). |

## 📂 Project Structure
```text
📦 project-root
 ┣ 📂 i_like_it/               # Flutter Frontend Code
 ┃ ┣ 📂 lib/
 ┃ ┃ ┣ 📂 core/                # Database, Theme, Sync, Auth managers
 ┃ ┃ ┣ 📂 features/            # UI organized by feature (folders, links, settings)
 ┃ ┃ ┗ 📜 main.dart            # App Entrypoint
 ┃ ┗ 📜 pubspec.yaml
 ┗ 📂 project-backend/         # Supabase Backend
   ┣ 📂 supabase/functions/    # Deno Edge Functions (send-otp)
   ┗ 📜 schema.sql             # PostgreSQL schema & RLS policies
```
