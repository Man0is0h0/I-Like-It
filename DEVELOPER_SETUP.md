# Developer Setup & Release Instructions

This document outlines the steps required to set up the project locally, build the production release, and maintain environment safety.

---

## ⚠️ Database Safety Guidelines (CRITICAL)
*   **Do not alter or run database migrations directly on the Production Supabase project.**
*   All testing, schema modifications, and feature experiments **must** be performed on your local database or the designated Development Supabase project.
*   The Production database is live; any structural modifications there must be coordinated and executed carefully via controlled migrations.

---

## 🛠️ Project Setup

### 1. Environment Configuration
Environment configuration files (`.env`) are gitignored for security. The repository includes two pre-configured files:
*   `i_like_it/.env.development` (Points to Development Supabase)
*   `i_like_it/.env.production` (Points to Production Supabase)

To switch between environments on your local machine, run the environment switcher script in PowerShell from the repository root:
*   **To use Development:**
    ```powershell
    ./switch_env.ps1 -env dev
    ```
*   **To use Production:**
    ```powershell
    ./switch_env.ps1 -env prod
    ```

---

## 🔑 Production Release Signing Setup
For security, the production keystore and credentials are not stored in the Git repository. To compile a signed production `.aab` or `.apk`, you must obtain the following files from the project owner:

1.  **`key.properties`**
2.  **`upload-keystore.jks`**

### Placement of Credentials:
Once you receive the files, place them in the following directories:
*   Place `key.properties` inside the `i_like_it/android/` directory.
*   Place `upload-keystore.jks` inside the `i_like_it/android/app/` directory.

### Credential reference (for key.properties):
```properties
storePassword=iLikeItApp2026!
keyPassword=iLikeItApp2026!
keyAlias=upload
storeFile=upload-keystore.jks
```

*Note: If these files are not present on your machine, the project's build configuration will automatically fall back to standard Android debug signing, allowing you to run and debug the app locally without issues.*

---

## 📦 Build Commands

### Build signed release APK (for local testing/sideloading):
```bash
cd i_like_it
flutter build apk --release
```
*Output Path:* `i_like_it/build/app/outputs/flutter-apk/app-release.apk`

### Build signed release Android App Bundle (for Play Store upload):
```bash
cd i_like_it
flutter build appbundle --release
```
*Output Path:* `i_like_it/build/app/outputs/bundle/release/app-release.aab`
