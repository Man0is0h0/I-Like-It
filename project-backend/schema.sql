-- SUPABASE DATABASE SCHEMA EXPORT
-- Generated on: 2026-03-12

-- 1. Enable Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS pg_net SCHEMA extensions;

-- 2. Create Tables

-- Users Table (Extends Supabase Auth)
CREATE TABLE IF NOT EXISTS public.users (
  id uuid REFERENCES auth.users NOT NULL PRIMARY KEY,
  email text,
  username text,
  role text DEFAULT 'user',
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
  created_at timestamptz DEFAULT now()
);

-- Debug Logs (Optional)
CREATE TABLE IF NOT EXISTS public.debug_logs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  message text,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- Email OTPs (Optional Tracking)
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

-- Folders
CREATE POLICY "Users can view own folders" ON public.folders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own folders" ON public.folders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own folders" ON public.folders FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own folders" ON public.folders FOR DELETE USING (auth.uid() = user_id);

-- Links
CREATE POLICY "Users can manage own links" ON public.links USING (
  EXISTS (
    SELECT 1 FROM public.folders 
    WHERE folders.id = links.folder_id AND folders.user_id = auth.uid()
  )
);

-- Strict Access for Logs & OTPs (Service Role only)
CREATE POLICY "Admins can view debug logs" ON public.debug_logs FOR SELECT USING (auth.jwt()->>'role' = 'service_role');
CREATE POLICY "Service Role manages OTPs" ON public.email_otps FOR ALL USING (auth.jwt()->>'role' = 'service_role');

-- 5. Triggers
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, username)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'username');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 6. Indexes
CREATE INDEX IF NOT EXISTS folders_user_id_idx ON public.folders(user_id);
CREATE INDEX IF NOT EXISTS links_folder_id_idx ON public.links(folder_id);
