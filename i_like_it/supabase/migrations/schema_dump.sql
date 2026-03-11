-- 1. Enable UUID extension
create extension if not exists "uuid-ossp";

-- 2. Create Tables

-- Users Table (Extends Supabase Auth)
create table if not exists public.users (
  id uuid references auth.users not null primary key,
  email text,
  username text,
  role text default 'user', -- 'admin' or 'user'
  created_at timestamptz default now()
);

-- Folders Table
create table if not exists public.folders (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  name text not null,
  icon text default 'folder',
  is_smart boolean default false,
  order_index integer default 0,
  created_at timestamptz default now()
);

-- Links Table
create table if not exists public.links (
  id uuid default gen_random_uuid() primary key,
  folder_id uuid references public.folders(id) on delete cascade not null,
  url text not null,
  title text,
  description text,
  image_url text,
  is_favorite boolean default false,
  created_at timestamptz default now()
);

-- 3. Enable Row Level Security (RLS)
alter table public.users enable row level security;
alter table public.folders enable row level security;
alter table public.links enable row level security;

-- 4. Create RLS Policies

-- Users
create policy "Users can view own profile" 
  on public.users for select 
  using (auth.uid() = id);

create policy "Users can update own profile" 
  on public.users for update 
  using (auth.uid() = id);

-- Folders
create policy "Users can view own folders" 
  on public.folders for select 
  using (auth.uid() = user_id);

create policy "Users can insert own folders" 
  on public.folders for insert 
  with check (auth.uid() = user_id);

create policy "Users can update own folders" 
  on public.folders for update 
  using (auth.uid() = user_id);

create policy "Users can delete own folders" 
  on public.folders for delete 
  using (auth.uid() = user_id);

-- Links
create policy "Users can view own links" 
  on public.links for select 
  using (
    exists (
      select 1 from public.folders 
      where folders.id = links.folder_id 
      and folders.user_id = auth.uid()
    )
  );

create policy "Users can insert own links" 
  on public.links for insert 
  with check (
    exists (
      select 1 from public.folders 
      where folders.id = links.folder_id 
      and folders.user_id = auth.uid()
    )
  );

create policy "Users can update own links" 
  on public.links for update 
  using (
    exists (
      select 1 from public.folders 
      where folders.id = links.folder_id 
      and folders.user_id = auth.uid()
    )
  );

create policy "Users can delete own links" 
  on public.links for delete 
  using (
    exists (
      select 1 from public.folders 
      where folders.id = links.folder_id 
      and folders.user_id = auth.uid()
    )
  );

-- 5. Create Triggers (Auto-create user profile)
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.users (id, email, username)
  values (new.id, new.email, new.raw_user_meta_data->>'username');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 6. Indexes for Performance
create index if not exists folders_user_id_idx on public.folders(user_id);
create index if not exists links_folder_id_idx on public.links(folder_id);
