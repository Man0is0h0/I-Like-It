# Project Backend: Setup Guide

This folder contains a complete "literal clone" of the project's backend. Follow these steps to set up a new Supabase project with exactly the same tables, functions, and settings.

## 🚀 Setup Instructions

### 1. Database Schema
1. Go to your **Supabase Dashboard**.
2. Open the **SQL Editor**.
3. Create a new query and paste the contents of [`schema.sql`](./schema.sql).
4. Run the query. This will:
    - Enable extensions (`pg_net`, `pg_cron`, etc.).
    - Create all tables (`users`, `folders`, `links`, etc.).
    - Set up RLS policies.
    - Create RPC functions and database triggers.

### 2. Edge Functions
Deploy the functions using the Supabase CLI:
1. Initialize Supabase in this directory if you haven't: `supabase init`.
2. Deploy the functions:
   ```bash
   supabase functions deploy classify-folders
   supabase functions deploy send-otp
   ```

### 3. Required Secrets
You **MUST** set the following secrets in your Supabase project for the functions to work:

```bash
supabase secrets set GEMINI_API_KEY=your_gemini_key
supabase secrets set RESEND_API_KEY=your_resend_api_key
```

### 4. Scheduled Jobs (Cron)
The database setup automatically schedules a job to run `classify-folders` every 30 minutes. 
**Note**: You must manually update the `Authorization` header in the `cron.schedule` call in [schema.sql](./schema.sql) (line 172) with your actual `SERVICE_ROLE_KEY`.

## 📁 Project Structure
- `supabase/functions/`: Source code for all Edge Functions.
- `supabase/config.toml`: Local development settings.
- `schema.sql`: Master database dump.
- `.env.example`: Template for required environment variables.

## 🛡️ Security
Ensure you review the RLS policies in `schema.sql` to match your specific access requirements. By default, it follows a strict "User owns their data" policy with an "Admin" role override.
