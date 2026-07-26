# QA Testing Diagnostics: Root Causes & Solutions

This document analyzes and solves the two issues reported by the QA team:
1. The signup failure error (`Database error saving new user`).
2. The download issue where standard assets and icons are shown in the photo gallery.

---

## 🛠️ Issue 1: "Database error saving new user" during Signup

### 🔍 Root Cause
When a new user signs up in the app, Supabase inserts a row into `auth.users`, which triggers the database function `handle_new_user()`. This function inserts the user profile details into our `public.users` table.

This trigger failed with a generic database error because of one of two things:
1. **Duplicate Usernames:** We recently added a `UNIQUE` constraint to the `username` column in our database schema (`enforce_unique_usernames.sql`). If a QA tester attempts to sign up with a username that is already registered (e.g. `soham`), PostgreSQL throws a duplicate key violation and crashes the signup trigger.
2. **Missing Database Columns:** If the database updates (`fix_username.sql` and `add_mobile_number.sql`) were not applied to your live Supabase Production instance, the `public.users` table won't have the `username` or `mobile_number` columns. When the trigger tries to insert those columns, it throws a database error.

### 🚀 Solution Implemented
1.  **Client-Side Username Pre-Checking:** We updated `initial_setup_screen.dart` to check if a username is already taken *before* attempting the signup API call using the `check_username_exists` RPC function.
    *   *Result:* Users are now greeted with a friendly warning: `"This username is already taken. Please choose another one."` instead of a cryptic crash.
2.  **Action Item (Action Required):** Make sure you run the migrations in your live **Production Supabase SQL Editor** in this order:
    1. `project-backend/add_mobile_number.sql`
    2. `project-backend/fix_username.sql`
    3. `project-backend/enforce_unique_usernames.sql`

---

## 📱 Issue 2: APK Installation Blocked & "Random Images" in Gallery

### 🔍 Root Cause
1.  **Installation Blocked (Play Protect):**
    *   Since the app is not yet published on the Google Play Store, Android's Google Play Protect flags any manually shared APK as an "Unknown App."
    *   *Solution:* This is completely normal for pre-launch apps. Testers must click "Install Anyway" or temporarily disable Play Protect scans to perform local testing. Once published on the Play Store, this warning will disappear.
2.  **"Random Images" in Gallery / Failed Downloads:**
    *   When the QA tester downloaded the `.apk` file, their phone's file manager or browser treated the `.apk` file as a `.zip` archive (which it technically is) and **extracted it** instead of running the installer.
    *   Because the APK was extracted to public storage (like the `/sdcard/Download` folder), all internal app images, icons, logo shapes, and templates were extracted as individual PNGs.
    *   Android's background Media Scanner automatically scanned the folder, detected 2000+ tiny app graphics, and loaded them into the phone's **photo gallery / Recent Images**!
    *   *Result:* The app didn't download random images—the phone simply unzipped the app's internal resources into the user's gallery.

### 🚀 How to Prevent & Guide QA Testers
To ensure QA testers can install the APK cleanly without extracting it:
1.  **Send the File Properly:** Send the file as a **Document** in WhatsApp rather than a Media file to prevent WhatsApp from converting or handling it incorrectly.
2.  **Use a Secure Beta Channel (Recommended):** Instead of manually sharing APKs over WhatsApp, upload the `.aab` file to Google Play Console's **Internal Testing** or **Closed Beta** track. This lets you add your QA testers by email, and they can download it directly from the Google Play Store securely with automatic updates and no warnings.
3.  **Install via File Manager:** Tell the QA tester to:
    *   Locate the downloaded `.apk` file in their file manager.
    *   Tap on the file and choose **"Package Installer"** or **"Install"** instead of "Extract" or "View Archive".
