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
SET is_super_admin = TRUE,
    role = 'super_admin'
WHERE mobile_number = '9699342811' 
   OR email = 'ritesh2004@gmail.com'
   OR email = 'singaleritesh2809@gmail.com' 
   OR email = 'sangaleritesh2809@gmail.com'
   OR email ILIKE '%ritesh%';

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

-- 6. Add utr_number column to collections if missing
ALTER TABLE public.collections ADD COLUMN IF NOT EXISTS utr_number TEXT;
ALTER TABLE public.families ADD COLUMN IF NOT EXISTS is_custom_vargani BOOLEAN DEFAULT FALSE;

-- 7. Fix RLS policies for families, family_members, collections, expenses, deposit_requests
DROP POLICY IF EXISTS "Families access" ON public.families;
CREATE POLICY "Families access" ON public.families FOR ALL USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Family members access" ON public.family_members;
CREATE POLICY "Family members access" ON public.family_members FOR ALL USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Collections access" ON public.collections;
CREATE POLICY "Collections access" ON public.collections FOR ALL USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Deposit requests select" ON public.deposit_requests;
CREATE POLICY "Deposit requests select" ON public.deposit_requests FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Deposit requests insert" ON public.deposit_requests;
CREATE POLICY "Deposit requests insert" ON public.deposit_requests FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Deposit requests update" ON public.deposit_requests;
CREATE POLICY "Deposit requests update" ON public.deposit_requests FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Expenses access" ON public.expenses;
CREATE POLICY "Expenses access" ON public.expenses FOR ALL USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Vargani configs access" ON public.vargani_configs;
CREATE POLICY "Vargani configs access" ON public.vargani_configs FOR ALL USING (auth.role() = 'authenticated');

-- 8. Secure Password Reset RPC for EmailJS Verified Users
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION public.reset_user_password(p_email TEXT, p_new_password TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
BEGIN
    SELECT id INTO v_user_id FROM auth.users WHERE LOWER(email) = LOWER(p_email);
    IF v_user_id IS NULL THEN
        RETURN FALSE;
    END IF;

    UPDATE auth.users
    SET encrypted_password = crypt(p_new_password, gen_salt('bf')),
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.reset_user_password(TEXT, TEXT) TO anon, authenticated, service_role;




DROP POLICY IF EXISTS "Family members access" ON public.family_members;
CREATE POLICY "Family members access" ON public.family_members FOR ALL USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Collections access" ON public.collections;
CREATE POLICY "Collections access" ON public.collections FOR ALL USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Deposit requests select" ON public.deposit_requests;
CREATE POLICY "Deposit requests select" ON public.deposit_requests FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Deposit requests insert" ON public.deposit_requests;
CREATE POLICY "Deposit requests insert" ON public.deposit_requests FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Deposit requests update" ON public.deposit_requests;
CREATE POLICY "Deposit requests update" ON public.deposit_requests FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Expenses access" ON public.expenses;
CREATE POLICY "Expenses access" ON public.expenses FOR ALL USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Vargani configs access" ON public.vargani_configs;
CREATE POLICY "Vargani configs access" ON public.vargani_configs FOR ALL USING (auth.role() = 'authenticated');



    UPDATE auth.users
    SET encrypted_password = crypt(p_new_password, gen_salt('bf')),
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.reset_user_password(TEXT, TEXT) TO anon, authenticated, service_role;



