-- ========================================================
-- DATABASE SCHEMA UPDATES FOR AUTH REFACTORING
-- Run this script in your Supabase SQL Editor
-- ========================================================

-- 1. Add the username column to public.users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS username text;

-- 2. Update the handle_new_user trigger function to copy username from auth metadata
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, username)
  VALUES (
    new.id, 
    new.email, 
    COALESCE(new.raw_user_meta_data->>'username', '')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Trigger function to call the send-welcome-email Edge Function using pg_net
CREATE OR REPLACE FUNCTION public.trigger_send_welcome_email()
RETURNS trigger AS $$
DECLARE
  v_host text;
  v_apikey text;
BEGIN
  -- Attempt to get host and apikey from request headers (works if triggered via REST API)
  BEGIN
    v_host := current_setting('request.headers', true)::jsonb->>'host';
    v_apikey := current_setting('request.headers', true)::jsonb->>'apikey';
  EXCEPTION WHEN OTHERS THEN
    v_host := NULL;
    v_apikey := NULL;
  END;

  -- Fallback to hardcoded project ref if request headers are not available (e.g. during background Auth signup)
  IF v_host IS NULL OR v_host = '' THEN
    v_host := 'izlahmslmpmfeecpgkav.supabase.co';
  END IF;

  IF v_apikey IS NULL OR v_apikey = '' THEN
    -- A dummy key is sufficient because our Edge Function does not enforce JWT authentication
    v_apikey := 'dummy_key';
  END IF;

  PERFORM
    net.http_post(
      url := 'https://' || v_host || '/functions/v1/send-welcome-email',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || v_apikey
      ),
      body := jsonb_build_object('record', row_to_json(new))
    );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Create trigger on public.users table
CREATE OR REPLACE TRIGGER on_public_user_created
  AFTER INSERT ON public.users
  FOR EACH ROW EXECUTE PROCEDURE public.trigger_send_welcome_email();
