-- ========================================================
-- FUNCTION TO CHECK IF EMAIL EXISTS BEFORE SIGNUP
-- Run this script in your Supabase SQL Editor
-- ========================================================

CREATE OR REPLACE FUNCTION public.check_email_exists(email_to_check text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM auth.users
    WHERE email = email_to_check
  );
END;
$$;
