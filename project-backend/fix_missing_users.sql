-- ========================================================
-- FIX: SYNC MISSING USERS FROM AUTH TO PUBLIC
-- Run this script in your Supabase SQL Editor
-- ========================================================

-- 1. Make sure the username column exists (just in case)
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS username text;

-- 2. Ensure the trigger function is correct and up to date
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, username)
  VALUES (
    new.id, 
    new.email, 
    COALESCE(new.raw_user_meta_data->>'username', '')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Ensure the trigger itself exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 4. FORCE FIX: Manually copy any users that got missed!
INSERT INTO public.users (id, email, username)
SELECT 
  id, 
  email, 
  COALESCE(raw_user_meta_data->>'username', '')
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.users)
ON CONFLICT (id) DO NOTHING;
