-- 1. Create a security definer helper function to check if current user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$;

-- Grant execution permission to anon and authenticated roles
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- 2. Drop and recreate policies on public.users
DROP POLICY IF EXISTS "Users manage own, Admins manage all" ON public.users;
CREATE POLICY "Users manage own, Admins manage all" ON public.users
  FOR ALL
  TO authenticated
  USING (auth.uid() = id OR public.is_admin());

-- 3. Drop and recreate policies on public.folders
DROP POLICY IF EXISTS "Users manage own folders, Admins manage all" ON public.folders;
CREATE POLICY "Users manage own folders, Admins manage all" ON public.folders
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

-- 4. Drop and recreate policies on public.links
DROP POLICY IF EXISTS "Users manage own links, Admins manage all" ON public.links;
CREATE POLICY "Users manage own links, Admins manage all" ON public.links
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

-- 5. Drop and recreate policies on public.debug_logs
DROP POLICY IF EXISTS "Admins can view debug logs" ON public.debug_logs;
CREATE POLICY "Admins can view debug logs" ON public.debug_logs
  FOR SELECT
  TO authenticated
  USING (
    (auth.jwt() ->> 'role'::text = 'service_role'::text) 
    OR public.is_admin()
  );
