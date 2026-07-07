-- ========================================================
-- DIAGNOSTIC: Check why links are not syncing
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor)
-- ========================================================

-- 1. Check the foreign key constraints on the links table
SELECT 
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'links';

-- 2. Check the links table columns
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'links'
ORDER BY ordinal_position;

-- 3. Check the folders table columns  
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'folders'
ORDER BY ordinal_position;

-- 4. Check if there are any rows in links
SELECT COUNT(*) as link_count FROM public.links;

-- 5. Check if there are any rows in folders
SELECT COUNT(*) as folder_count FROM public.folders;

-- 6. Check RLS policies on links table
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'links';

-- 7. Check RLS policies on folders table
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'folders';

-- 8. Check if the users table has the correct user
SELECT id, email, role, username FROM public.users LIMIT 10;

-- 9. Try a test insert into folders (you can delete this after)
-- This will fail if there's a schema issue
-- INSERT INTO public.folders (user_id, name, updated_at)
-- SELECT id, 'Test Folder', now() FROM public.users LIMIT 1;
