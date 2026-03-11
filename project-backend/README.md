# I Like It - Backend Project Setup

This folder contains the complete Supabase backend configuration, including the database schema, security policies, and edge functions.

## 🛠️ Step-by-Step Installation

### 1. Supabase Project Setup
1. Create a new project at [database.supabase.com](https://database.supabase.com).
2. Go to the **SQL Editor** in your Supabase dashboard.
3. Open `schema.sql` from this folder, copy its content, and **Run** it. This will create all tables, triggers, and security policies.

### 2. Edge Function Deployment
You will need the [Supabase CLI](https://supabase.com/docs/guides/cli/getting-started) and [Docker](https://www.docker.com/) installed.

1. **Login to Supabase CLI:**
   ```bash
   npx supabase login
   ```
2. **Link this folder to your project:**
   ```bash
   npx supabase link --project-ref <your-project-id>
   ```
3. **Set your Gemini API Key:**
   ```bash
   npx supabase secrets set GEMINI_API_KEY="your-gemini-api-key"
   ```
4. **Deploy the Function:**
   ```bash
   npx supabase functions deploy classify-folders
   ```

### 3. Authentication & Resend SMTP Setup
1. In the Supabase Dashboard, go to **Authentication > Providers > Email**.
2. Set **Confirm Email** to **ON**.
3. **Configure Resend SMTP:**
   - Go to **Authentication > SMTP Settings**.
   - Enable SMTP.
   - **Host:** `smtp.resend.com`
   - **Port:** `465` or `587`
   - **User:** `resend`
   - **Password:** Your Resend API Key.
   - **Sender Email:** The email verified in your Resend dashboard.
4. Under **Authentication > Email Templates**, ensure your templates use `{{ .Token }}` for OTP verification codes.

## 📁 Folder Structure
- `schema.sql`: Full database structure and RLS policies.
- `.env.example`: Template for required secrets.
- `supabase/`:
  - `config.toml`: Local CLI configuration.
  - `functions/`: Source code for Edge Functions.
