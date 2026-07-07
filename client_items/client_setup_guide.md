# 📧 iLikeIt Email Setup & Configuration Guide

This guide describes how to configure the email templates, custom Zoho SMTP, logo hosting, and triggers for welcome emails in your Supabase project.

---

## 🛠️ Step 1: Host the App Logo
To display the logo inside your email templates, you need to upload it to your Supabase Storage.

1. Open your **[Supabase Dashboard](https://supabase.com/dashboard)** and navigate to **Storage**.
2. Click **New Bucket**.
3. Set the **Bucket Name** as: `assets`.
4. Toggle **Public Bucket** to **Enabled** (this ensures the logo is visible to recipients).
5. Click **Create bucket**.
6. Open the newly created `assets` bucket, click **Upload**, and select the logo image:
   * File to upload: `client_items/App iconn.png`
   * **Important:** Rename the uploaded file to **`logo.png`** inside the bucket.
7. Get your **Project Reference ID** (found in your Supabase project settings URL, e.g., if your URL is `https://supabase.com/dashboard/project/abcde`, your Project Ref is `abcde`).

---

## 🛠️ Step 2: Update Placeholders in Templates
Before deploying the templates and edge function, you must replace the placeholder `YOUR_SUPABASE_PROJECT_REF` with your actual **Project Reference ID** in the following files:

1. Open these 3 files in a text editor (like Notepad):
   * `client_items/Verification Email_iLikeIt.html`
   * `client_items/Reset_Pass_iLikeIt.html`
   * `client_items/Welcome_Email_iLikeIt.html`
2. Search for the text `YOUR_SUPABASE_PROJECT_REF` (found in the logo image tag: `<img src="https://YOUR_SUPABASE_PROJECT_REF.supabase.co/...`) and replace it with your actual **Project Reference ID**.
3. Save the files.

---

## 📧 Step 3: Configure Custom SMTP (Zoho Mail)
This routes all your transactional emails (signups, passwords) through `support@ilikeit.co.in` instead of Supabase's default address.

1. Go to your **Supabase Dashboard > Project Settings > Authentication**.
2. Scroll down to the **SMTP Settings** section.
3. Enable **SMTP Enabled**.
4. Configure SMTP with these values:
   * **Sender Email:** `support@ilikeit.co.in`
   * **Sender Name:** `iLikeIt Support`
   * **Host:** `smtp.zoho.in`
   * **Port:** `465`
   * **User:** `support@ilikeit.co.in`
   * **Password:** *Enter the App Password generated from Zoho Mail Security Settings* (Do not use your standard Zoho login password; use an **App Password**).
5. Click **Save**.

---

## 📝 Step 4: Set Up Custom Email Templates
Customize the layout of the default emails sent by Supabase.

1. Go to **Supabase Dashboard > Project Settings > Authentication > Email Templates**.
2. Configure these two templates:

### A. Confirm Signup (OTP Email)
* **Template Title:** `Confirm Signup`
* **Subject:** `Verify your email for iLikeIt`
* **Body:** Open the modified `client_items/Verification Email_iLikeIt.html`, copy all text, and paste it into the **Body** field.

### B. Reset Password
* **Template Title:** `Reset Password`
* **Subject:** `Reset Your Password`
* **Body:** Open the modified `client_items/Reset_Pass_iLikeIt.html`, copy all text, and paste it into the **Body** field.

Click **Save** after pasting each template.

---

## ⚡ Step 5: Deploy the Welcome Email Edge Function
The welcome email is sent automatically using a Supabase Edge Function when a new user registers.

### Prerequisites:
Make sure you have the [Supabase CLI installed](https://supabase.com/docs/guides/cli) on your machine.

1. Open a terminal in the root directory of this repository.
2. Log in to your Supabase CLI:
   ```bash
   supabase login
   ```
3. Link the repository to your remote Supabase project:
   ```bash
   supabase link --project-ref <your-project-ref>
   ```
4. Set the SMTP and Gemini secrets in your remote project:
   ```bash
   supabase secrets set SMTP_USER="support@ilikeit.co.in" SMTP_PASS="your_zoho_app_password" GEMINI_API_KEY="your_gemini_api_key"
   ```
5. Deploy the Edge Function:
   ```bash
   supabase functions deploy send-welcome-email --no-verify-jwt
   supabase functions deploy classify-folders --no-verify-jwt
   ```

---

## 🗄️ Step 6: Enable Database Triggers
Run the SQL script that detects when a new user registers and triggers the welcome email.

1. Go to **Supabase Dashboard > SQL Editor**.
2. Click **New Query**.
3. Open the file `project-backend/auth_schema_updates.sql` in a text editor, copy all content, and paste it into the editor.
4. **Action Required:** Change the project ref fallback on **line 41** to match your project URL:
   ```sql
   v_host := '<your-project-ref>.supabase.co';
   ```
5. Click **Run**.

---

### 🎉 Setup Complete!
Once these steps are completed, all users will receive styled, branded emails for email verification, password resets, and registrations.
