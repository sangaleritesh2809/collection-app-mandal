-- ==============================================================================
-- VARGANI COLLECTION: QUICK AUTH & SUPER ADMIN FIX SCRIPT
-- Paste and run this script in your Supabase Dashboard -> SQL Editor
-- ==============================================================================

-- 1. Free up mobile number 9699342811 by removing the unconfirmed placeholder account
DELETE FROM auth.users WHERE email = 'ritesh9699342811@collection.app';
DELETE FROM public.profiles WHERE email = 'ritesh9699342811@collection.app' OR mobile_number = '9699342811';

-- 2. Prevent future 500 crashes by making user creation trigger robust against conflicts
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email, mobile_number, created_at, updated_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
        NEW.email,
        NEW.raw_user_meta_data->>'mobile_number',
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        email = EXCLUDED.email,
        mobile_number = COALESCE(EXCLUDED.mobile_number, public.profiles.mobile_number),
        updated_at = NOW();
    RETURN NEW;
EXCEPTION WHEN unique_violation THEN
    -- If mobile number or email already belongs to another user, insert profile safely
    INSERT INTO public.profiles (id, full_name, email, created_at, updated_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
        NEW.email,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        email = EXCLUDED.email,
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Allow authenticated users to insert their own profile
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- 4. Automatically promote Ritesh to Super Admin
UPDATE public.profiles
SET is_super_admin = TRUE
WHERE mobile_number = '9699342811' 
   OR email = 'singaleritesh2809@gmail.com' 
   OR email = 'sangaleritesh2809@gmail.com';

-- 5. Clean up duplicate roles and keep only 1 of each role
DELETE FROM public.roles
WHERE id NOT IN (
    SELECT DISTINCT ON (name, COALESCE(mandal_id, '00000000-0000-0000-0000-000000000000'::uuid)) id
    FROM public.roles
    ORDER BY name, COALESCE(mandal_id, '00000000-0000-0000-0000-000000000000'::uuid), created_at ASC
);

-- Ensure is_system_role = TRUE for the 5 system roles
UPDATE public.roles
SET is_system_role = TRUE
WHERE mandal_id IS NULL;

-- Create Unique Indexes so duplicate roles can NEVER be created again
CREATE UNIQUE INDEX IF NOT EXISTS idx_roles_system_unique ON public.roles(name) WHERE mandal_id IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_roles_mandal_unique ON public.roles(name, mandal_id) WHERE mandal_id IS NOT NULL;


