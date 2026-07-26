-- ========================================================
-- BULLETPROOF SIGNUP AND DATABASE RECOVERY SCRIPT
-- Run this script in your Production Supabase SQL Editor
-- ========================================================

-- 1. Ensure columns exist on public.users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS username text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS mobile_number text;

-- 2. Drop the UNIQUE constraint on username if it exists
-- This allows multiple users to register with the same username
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_username_key;

-- 3. Bulletproof handle_new_user trigger function
-- Only inserts into public.users once email/OTP verification is completed (email_confirmed_at IS NOT NULL)
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger AS $fn$
BEGIN
  IF NEW.email_confirmed_at IS NOT NULL THEN
    INSERT INTO public.users (id, email, username, mobile_number)
    VALUES (
      new.id, 
      new.email, 
      COALESCE(new.raw_user_meta_data->>'username', ''), 
      COALESCE(new.raw_user_meta_data->>'mobile_number', '')
    )
    ON CONFLICT (id) DO UPDATE 
    SET email = EXCLUDED.email,
        username = EXCLUDED.username,
        mobile_number = EXCLUDED.mobile_number;
  END IF;
  RETURN new;
END;
$fn$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 4. Bulletproof welcome email trigger function
-- Wrapped in a try-catch block so that edge function failures NEVER block user signup
CREATE OR REPLACE FUNCTION public.trigger_send_welcome_email()
RETURNS trigger AS $fn$
DECLARE
  v_host text;
  v_apikey text;
BEGIN
  -- Attempt to extract request metadata safely
  BEGIN
    v_host := current_setting('request.headers', true)::jsonb->>'host';
    v_apikey := current_setting('request.headers', true)::jsonb->>'apikey';
  EXCEPTION WHEN OTHERS THEN
    v_host := NULL;
    v_apikey := NULL;
  END;

  -- Fallbacks for background tasks
  IF v_host IS NULL OR v_host = '' THEN
    v_host := 'baelekmfmvlyglowofab.supabase.co';
  END IF;

  IF v_apikey IS NULL OR v_apikey = '' THEN
    v_apikey := 'dummy_key';
  END IF;

  -- HTTP call wrapped in exception block so errors never bubble up to abort signup
  BEGIN
    PERFORM
      net.http_post(
        url := 'https://' || v_host || '/functions/v1/send-welcome-email',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || v_apikey
        ),
        body := jsonb_build_object('record', row_to_json(new))
      );
  EXCEPTION WHEN OTHERS THEN
    -- Log warning locally and let the insert complete successfully
    RAISE WARNING 'Welcome email notification failed: %', SQLERRM;
  END;

  RETURN new;
END;
$fn$ LANGUAGE plpgsql SECURITY DEFINER;
