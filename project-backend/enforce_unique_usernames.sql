-- ========================================================
-- ENFORCE UNIQUE USERNAMES & ADD RPC CHECK
-- Run this script in your Supabase SQL Editor
-- ========================================================

-- 1. Ensure the username column exists (just in case)
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS username text;

-- 2. Clean up existing duplicates safely
-- This appends a unique suffix to any duplicate usernames so the UNIQUE constraint doesn't fail.
UPDATE public.users 
SET username = username || '_' || substr(id::text, 1, 6)
WHERE username IN (
  SELECT username 
  FROM public.users 
  GROUP BY username 
  HAVING COUNT(*) > 1
);

-- 3. Apply the UNIQUE constraint to the username column
-- Using lower(username) ensures case-insensitive uniqueness at the database level if preferred,
-- but standard UNIQUE is applied here for simplicity. Our RPC will handle case-insensitivity.
DO $$
BEGIN
  IF NOT EXISTS (
      SELECT 1 
      FROM pg_constraint 
      WHERE conname = 'users_username_key'
  ) THEN
      ALTER TABLE public.users ADD CONSTRAINT users_username_key UNIQUE (username);
  END IF;
END $$;

-- 4. Create RPC for fast frontend lookups
-- This allows the Flutter app to rapidly check if a username exists
-- It uses lower() for case-insensitive matching to prevent "John" and "john"
CREATE OR REPLACE FUNCTION public.check_username_exists(username_to_check text) 
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM public.users 
    WHERE lower(username) = lower(username_to_check)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
