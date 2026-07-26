# Production Deployment & Update Checklist

This guide outlines a safe, systematic process (following senior engineering best practices) to pull changes from GitHub, switch to the production environment, verify all configurations, and generate the final release bundle for the Google Play Store.

---

## 🛠️ Step 1: Safely Pull the Changes from GitHub

To avoid losing any local build settings (like the keystore file and `key.properties` which are ignored by Git), we will use Git stash/pull:

1.  **Stash local changes (if any):**
    ```bash
    git stash
    ```
2.  **Pull latest changes from the repository:**
    ```bash
    git pull origin main
    ```
3.  **Restore local changes (to restore local properties/untracked configs):**
    ```bash
    git stash pop
    ```
    *(Note: If you had no uncommitted files, you can skip `git stash` and `git stash pop` and simply run `git pull origin main`).*

---

## 🔍 Step 2: Code & Configuration Audit (The "Senior Engineer" Review)

Before building, verify the following checks:
1.  **Check for Secret Leaks:** Verify that the other developer did not accidentally check in any private API keys, passwords, or the `service_role` key in the `lib/` directory.
2.  **Verify Package Name Consistency:** Ensure the package name remains `com.ilikeit.app` in `i_like_it/android/app/build.gradle.kts`.
3.  **Confirm Keystore is Active:** Ensure `key.properties` (in `i_like_it/android/`) and `upload-keystore.jks` (in `i_like_it/android/app/`) are still in place.
4.  **AI Code Audit:** Verify that the AI suggestions folder/feature code is correctly commented out as per the client's instructions and does not generate compilation warnings or errors.

---

## 🌐 Step 3: Switch & Lock the Production Environment

To guarantee the final app bundle connects to the live production Supabase instance and not the development one:

1.  Run the PowerShell script from the root workspace directory to copy the production environment settings:
    ```powershell
    ./switch_env.ps1 -env prod
    ```
2.  Open `i_like_it/.env` and verify it contains the production values:
    *   `SUPABASE_URL` = Production URL (`baelekmfmvlyglowofab.supabase.co`)
    *   `SUPABASE_ANON_KEY` = Production Anon/Public key

---

## 🗄️ Step 4: Synchronize Database Schemas (Crucial!)

If the developer added new features that require changes to the database structure (new tables, new columns, updated RLS policies, or functions):
1.  Verify if there are new SQL scripts in the `project-backend/` folder.
2.  **Do not run scripts blindly.** Review the changes.
3.  Open the **Supabase Dashboard** for the **Production** project.
4.  Navigate to the **SQL Editor** and run the new SQL schema updates to ensure the production database matches the new application code.

---

## 📦 Step 5: Clean Build & Compile

To ensure there are no cached development assets or outdated dependencies remaining in the build folders:

1.  **Clean the Flutter project:**
    ```bash
    cd i_like_it
    flutter clean
    ```
2.  **Resolve dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Build the production Android App Bundle (.aab):**
    ```bash
    flutter build appbundle --release
    ```

---

## 🚀 Step 6: Play Store Upload

Once the compilation completes successfully:
1.  Locate the final signed bundle at:
    `i_like_it/build/app/outputs/bundle/release/app-release.aab`
2.  Upload this bundle to the **Google Play Console** under the **Internal Testing**, **Closed Testing**, or **Production** tracks.
