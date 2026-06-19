-- ==========================================
-- SUPABASE STORAGE SETUP: LEGAL DOCUMENTS
-- Run this script in your Supabase SQL Editor
-- ==========================================

-- 1. Create the 'legal-docs' bucket if it doesn't already exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'legal-docs', 
  'legal-docs', 
  true, -- Make it public
  5242880, -- 5MB limit
  ARRAY['text/html'] -- Only allow HTML files
)
ON CONFLICT (id) DO NOTHING;

-- 2. Enable Row-Level Security (RLS) on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Policy: Allow anyone (public/anon) to read files from this bucket
CREATE POLICY "Allow public read access to legal-docs" ON storage.objects
  FOR SELECT USING (bucket_id = 'legal-docs');

-- 4. Policy: Allow service_role or authenticated Admins to manage files
CREATE POLICY "Allow admins to manage legal-docs" ON storage.objects
  FOR ALL USING (
    bucket_id = 'legal-docs' 
    AND (
      auth.role() = 'service_role' 
      OR EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
      )
    )
  );
