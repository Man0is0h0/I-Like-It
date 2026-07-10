-- 1. Ensure the username column exists in public.users
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS username text;

-- 2. Update the handle_new_user trigger to extract BOTH username and mobile number
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, username, mobile_number)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'username', new.raw_user_meta_data->>'mobile_number');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
