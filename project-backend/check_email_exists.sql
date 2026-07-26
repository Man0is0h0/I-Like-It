-- ========================================================
-- FUNCTION TO CHECK IF EMAIL EXISTS BEFORE SIGNUP
-- Run this script in your Supabase SQL Editor
-- ========================================================

CREATE OR REPLACE FUNCTION public.check_email_exists(email_to_check text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $fn$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM auth.users
    WHERE email = email_to_check
      AND email_confirmed_at IS NOT NULL
  );
END;
$fn$;
