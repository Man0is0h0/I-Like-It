# 🌟 I Like It - Advanced Bookmark & Folder Manager

**A robust, collaborative, and entirely offline-first folder-based bookmark and link management application. Built natively with Flutter, backed by a powerful Supabase cloud infrastructure, and designed primarily for instant, sub-millisecond offline performance.**

---

## 📌 Executive Summary & Core Philosophy

"I Like It" is not just another link saver. It is engineered from the ground up to solve the latency problems inherent in cloud-only mobile applications. Our architecture dictates that the local SQLite database is the master visual state. When a user pastes a URL, it is instantly written to the local disk, its metadata is scraped asynchronously, and the UI responds immediately. Background queues seamlessly synchronize these changes to the Supabase Postgres instance whenever network connectivity becomes available.

## 🚀 Key Features

### 📂 Dynamic Folder Management
- Organize an infinite number of bookmarked URLs into distinctly customizable folders.
- Assign unique icons and vibrant color palettes (managed via extensive built-in asset libraries) to each folder to visually categorize technical documentation, design resources, video playlists, or news articles.
- Protect folders locally, preventing accidental deletions with UI-level safety guards and cloud-level referential integrity.

### 🔗 Smart, AI-Assisted Link Saving & Scraping
- Simply paste a raw URL into the app, and the internal metadata extractor handles the rest.
- Bypasses standard CDN anti-bot blocks to scrape the highest quality `og:image`, `<title>`, and description metatags.
- Includes a dedicated scraping routine specifically designed to bypass YouTube blocks and pull high-res video thumbnails gracefully.

### ☁️ True Offline-First Cloud Sync
- Operates 100% independently of network status. You can view, edit, move, or delete bookmarked links while entirely disconnected from the internet.
- Utilizes an intelligent background sync manager that continuously monitors the application lifecycle to push local `dirty` flags to the cloud and pull down mutations performed on secondary devices.

### 📧 Passwordless, OTP Authentication
- Frictionless email-based authentication pipeline.
- Relies on custom Deno Edge Functions hosted on Supabase to send secure One-Time Passwords (OTPs) via verified SMTP providers (Resend or Gmail), preventing unauthorized access or credential leakages on the mobile client.

### 🌓 Premium Glassmorphism Theming
- Implements a truly modern visual language.
- Relies heavily on frosty, translucent `BackdropFilter` widgets, providing an elegant, premium feel unachievable by standard flat Material Design.
- Seamless, deeply integrated support for Dark Mode, Light Mode, and System Default overrides.

### 📤 Native OS Sharing Integration
- Deep integration with iOS and Android native share sheets.
- Share your saved content from the app directly into iMessage, WhatsApp, Twitter, or Slack without awkwardly copying strings to your clipboard.

---

## 🛠 Complete Technology Stack

| Component | Technology Used | Version/Details |
|-----------|-----------------|-----------------|
| **Frontend Framework** | [Flutter](https://docs.flutter.dev/) | 3.10.7+ |
| **Language** | [Dart](https://dart.dev/) | 3.0+ |
| **Local Database** | [SQLite](https://pub.dev/packages/sqflite) | Real-time, file-based offline storage |
| **State Management** | Provider / Custom Singletons | Efficient rebuilds scoped to modular features |
| **Backend / Database** | [Supabase](https://supabase.com/) | Managed PostgreSQL 15 |
| **Serverless Functions**| [Deno](https://deno.com/) | Typescript-based edge workers for Auth |
| **Authentication** | Supabase Auth (OTP) | JWT, Row Level Security (RLS) enforcement |
| **Email Delivery** | [Resend](https://resend.com) / Gmail | Bound entirely server-side in the Deno Edge Function |

---

## 🚀 Quick Setup (1-2-3)

Follow these immediate steps to boot the developer environment. For a significantly deeper dive into environment variables, schema setup, and Edge Function deployment, please reference our extensive `docs/QUICKSTART.md`.

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/your-username/i-like-it.git
   cd i_like_it
   ```

2. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment File:**
   Copy the provided `.env.example` to `.env` inside the `i_like_it` directory. Populate it with your active Supabase Project URL and Anonymous Public Key.
   ```env
   SUPABASE_URL=https://your-project-url.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJI...
   ```

4. **Run the Application:**
   Select your connected device or local emulator.
   ```bash
   flutter run
   ```

---

## 🔐 Crucial Security & Environment Variables Warning

> **⚠️ WARNING:** Never, under any circumstances, commit your `.env` file, your `SERVICE_ROLE` keys, or your Edge Function SMTP passwords to version control! The project is pre-configured with a `.gitignore` to prevent this, but extreme caution must be exercised when modifying build scripts.

If you rotate your Supabase API keys, you must instantly update your local `.env` and force a clean rebuild via `flutter clean` to ensure the previous environment variables are cleared from the compiled Dart constants.

---

## 📂 Project & Module Structure Overview

The repository is logically separated between the Flutter frontend implementation and the Supabase backend configuration. It relies heavily on feature-first domain routing.

```text
📦 project-root
 ┣ 📂 docs/                    # Extensive technical documentation (Deployment, Quickstarts)
 ┣ 📂 i_like_it/               # 📱 Complete Flutter Frontend Codebase
 ┃ ┣ 📂 lib/                   
 ┃ ┃ ┣ 📂 core/                # Global Singletons: DatabaseHelper, ThemeManager, SyncManager
 ┃ ┃ ┣ 📂 features/            # Isolated UI logic: Folders, Links, Settings, Admin, Onboarding
 ┃ ┃ ┣ 📂 theme/               # Global Typography and Color Palette definitions
 ┃ ┃ ┗ 📜 main.dart            # Flutter Engine Entrypoint & Router
 ┃ ┣ 📂 android/               # Native Android configurations & Kotlin handlers
 ┃ ┣ 📂 ios/                   # Native iOS configurations & Swift handlers
 ┃ ┗ 📜 pubspec.yaml           # Flutter dependencies and asset registrations
 ┗ 📂 project-backend/         # ☁️ Supabase Backend Configuration
   ┣ 📂 supabase/functions/    # TypeScript Deno Edge Functions (send-otp)
   ┗ 📜 schema.sql             # Executable PostgreSQL schema & strict RLS policies
```

## 🤝 Contribution Guidelines
When submitting PRs, ensure you have read the `docs/INFO.md` guide. Do not alter the core glassmorphism theme components without approval, and ensure all new data structures strictly obey the Offline-First paradigm via the `DatabaseHelper` before hitting the `RemoteDatasource`.
