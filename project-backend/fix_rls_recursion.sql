-- ========================================================
-- FIX: Infinite recursion detected in RLS policies
-- Run this script in your Supabase SQL Editor
-- Dashboard > SQL Editor > New Query > Paste this > Run
-- ========================================================

-- 1. Create a security definer helper to check if a user is an admin.
-- Since this is SECURITY DEFINER, it bypasses RLS checks on public.users
-- and solves the infinite recursion issue.
CREATE OR REPLACE FUNCTION public.is_admin(user_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = user_id AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Drop and recreate policies for public.users
DROP POLICY IF EXISTS "Users manage own, Admins manage all" ON public.users;
CREATE POLICY "Users manage own, Admins manage all" ON public.users 
  FOR ALL USING (auth.uid() = id OR public.is_admin(auth.uid()));

-- 3. Drop and recreate policies for public.folders
DROP POLICY IF EXISTS "Users manage own folders, Admins manage all" ON public.folders;
CREATE POLICY "Users manage own folders, Admins manage all" ON public.folders 
  FOR ALL USING (user_id = auth.uid() OR public.is_admin(auth.uid()));

-- 4. Drop and recreate policies for public.links
DROP POLICY IF EXISTS "Users manage own links, Admins manage all" ON public.links;
CREATE POLICY "Users manage own links, Admins manage all" ON public.links 
  FOR ALL USING (user_id = auth.uid() OR public.is_admin(auth.uid()));

-- 5. Drop and recreate policies for public.debug_logs
DROP POLICY IF EXISTS "Admins can view debug logs" ON public.debug_logs;
CREATE POLICY "Admins can view debug logs" ON public.debug_logs 
  FOR SELECT USING (auth.jwt()->>'role' = 'service_role' OR public.is_admin(auth.uid()));
