-- ========================================================
-- COMPLETE FIX: Links not syncing to database
-- Run this ENTIRE script in your Supabase SQL Editor
-- Dashboard > SQL Editor > New Query > Paste this > Run
-- ========================================================

-- STEP 1: Check current state of the foreign key constraint
-- This will show you what tables the links.folder_id references
SELECT 
    tc.constraint_name, 
    tc.table_name AS source_table,
    kcu.column_name AS source_column, 
    ccu.table_name AS references_table,
    ccu.column_name AS references_column
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'links'
  AND tc.table_schema = 'public';

-- STEP 2: Drop the INCORRECT foreign key (references links instead of folders)
ALTER TABLE public.links DROP CONSTRAINT IF EXISTS links_folder_id_fkey;

-- STEP 3: Add the CORRECT foreign key (references folders)
ALTER TABLE public.links 
  ADD CONSTRAINT links_folder_id_fkey 
  FOREIGN KEY (folder_id) 
  REFERENCES public.folders(id) 
  ON DELETE CASCADE;

-- STEP 4: Verify the fix worked
SELECT 
    tc.constraint_name, 
    tc.table_name AS source_table,
    kcu.column_name AS source_column, 
    ccu.table_name AS references_table,
    ccu.column_name AS references_column
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'links'
  AND tc.table_schema = 'public';

-- STEP 5: Show current data counts
SELECT 'users' as table_name, COUNT(*) as row_count FROM public.users
UNION ALL
SELECT 'folders', COUNT(*) FROM public.folders
UNION ALL
SELECT 'links', COUNT(*) FROM public.links;

-- STEP 6: Show all RLS policies on links (to verify auth access)
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual::text
FROM pg_policies 
WHERE tablename = 'links' AND schemaname = 'public';
