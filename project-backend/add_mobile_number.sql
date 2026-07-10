-- 1. Add the mobile_number column to public.users
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS mobile_number text;

-- 2. Update the handle_new_user trigger to extract the mobile number
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, mobile_number)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'mobile_number');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
