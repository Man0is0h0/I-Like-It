-- SUPABASE DATABASE SCHEMA MASTER EXPORT
-- This file contains EVERYTHING needed to recreate the backend:
-- Extensions, Tables, RLS, Triggers, RPCs, and Cron Jobs.

-- 1. Enable Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_net";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- 2. Create Tables

-- Users Table (Extends Supabase Auth)
CREATE TABLE IF NOT EXISTS public.users (
  id uuid REFERENCES auth.users NOT NULL PRIMARY KEY,
  email text,
  username text,
  role text DEFAULT 'user',
  encrypted_recovery_code text,
  recovery_hash text,
  last_seen_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Folders Table
CREATE TABLE IF NOT EXISTS public.folders (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  icon text DEFAULT 'folder',
  is_smart boolean DEFAULT false,
  order_index integer DEFAULT 0,
  system_category text DEFAULT 'other',
  is_deleted boolean DEFAULT false,
  updated_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Links Table
CREATE TABLE IF NOT EXISTS public.links (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  folder_id uuid REFERENCES public.folders(id) ON DELETE CASCADE NOT NULL,
  url text NOT NULL,
  title text,
  description text,
  image_url text,
  is_favorite boolean DEFAULT false,
  user_id uuid REFERENCES public.users(id),
  updated_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Debug Logs
CREATE TABLE IF NOT EXISTS public.debug_logs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  message text,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- Email OTPs
CREATE TABLE IF NOT EXISTS public.email_otps (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  email text,
  otp_code text,
  created_at timestamptz DEFAULT now()
);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debug_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_otps ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS Policies

-- Users
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users manage own, Admins manage all" ON public.users FOR ALL USING (auth.uid() = id OR (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');

-- Folders
CREATE POLICY "Users manage own folders, Admins manage all" ON public.folders FOR ALL USING (user_id = auth.uid() OR (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');

-- Links
CREATE POLICY "Users manage own links, Admins manage all" ON public.links FOR ALL USING (user_id = auth.uid() OR (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');

-- Logs & OTPs (Service Role / Admin only)
CREATE POLICY "Admins can view debug logs" ON public.debug_logs FOR SELECT USING (auth.jwt()->>'role' = 'service_role' OR (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');
CREATE POLICY "Service Role manages OTPs" ON public.email_otps FOR ALL USING (auth.jwt()->>'role' = 'service_role');

-- 5. RPC Functions

-- Handle New User Trigger Function
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, username)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'username');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Request Recovery OTP
CREATE OR REPLACE FUNCTION public.request_recovery_otp(p_email text)
RETURNS jsonb AS $$
DECLARE
    v_otp text;
BEGIN
    -- Generate 6-digit OTP
    v_otp := lpad(floor(random() * 1000000)::text, 6, '0');
    
    INSERT INTO public.email_otps (email, otp_code)
    VALUES (p_email, v_otp);
    
    RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify Recovery OTP
CREATE OR REPLACE FUNCTION public.verify_recovery_otp(p_email text, p_code text)
RETURNS jsonb AS $$
DECLARE
    v_exists boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.email_otps 
        WHERE email = p_email 
        AND otp_code = p_code 
        AND created_at > now() - interval '15 minutes'
    ) INTO v_exists;
    
    RETURN jsonb_build_object('success', v_exists);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Edge Function Trigger Handler
CREATE OR REPLACE FUNCTION public.trigger_send_otp_final()
RETURNS trigger AS $$
BEGIN
  PERFORM
    net.http_post(
      url := 'https://' || current_setting('request.headers')::jsonb->>'host' || '/functions/v1/send-otp',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('request.headers')::jsonb->>'apikey'
      ),
      body := jsonb_build_object('record', row_to_json(new))
    );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Triggers
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

CREATE TRIGGER on_auth_otp_request
  AFTER INSERT ON public.email_otps
  FOR EACH ROW EXECUTE PROCEDURE public.trigger_send_otp_final();

-- 7. Scheduled Jobs (Cron)
-- Note: Replace placeholders with real URL/Keys manually or during setup env
SELECT cron.schedule(
  'classify-folders-every-30-mins',
  '*/30 * * * *',
  $$
  SELECT
    net.http_post(
      url := 'https://izlahmslmpmfeecpgkav.supabase.co/functions/v1/classify-folders',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer SERVICE_ROLE_KEY"}'::jsonb,
      body := '{}'::jsonb
    );
  $$
);

-- 8. Indexes
CREATE INDEX IF NOT EXISTS folders_user_id_idx ON public.folders(user_id);
CREATE INDEX IF NOT EXISTS links_folder_id_idx ON public.links(folder_id);
CREATE INDEX IF NOT EXISTS email_otps_email_idx ON public.email_otps(email);
