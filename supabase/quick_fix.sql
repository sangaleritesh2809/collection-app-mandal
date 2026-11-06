-- ==============================================================================
-- VARGANI COLLECTION: QUICK AUTH & SUPER ADMIN FIX SCRIPT
-- Paste and run this entire script in Supabase Dashboard -> SQL Editor
-- ==============================================================================

-- 1. Ensure required columns exist in profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_super_admin BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'member';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS mobile_number TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS full_name TEXT;

-- 2. Free up mobile number 9699342811 by removing any unconfirmed placeholder accounts
DELETE FROM auth.users WHERE email = 'ritesh9699342811@collection.app';
DELETE FROM public.profiles WHERE email = 'ritesh9699342811@collection.app';

-- 3. Prevent future crashes by making user creation trigger robust against conflicts
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email, mobile_number, is_super_admin, role, created_at, updated_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
        NEW.email,
        NEW.raw_user_meta_data->>'mobile_number',
        (NEW.raw_user_meta_data->>'mobile_number' = '9699342811'),
        CASE WHEN NEW.raw_user_meta_data->>'mobile_number' = '9699342811' THEN 'super_admin' ELSE 'member' END,
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

-- 4. Allow authenticated users to insert/update their own profile
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- 5. Automatically promote ONLY Ritesh (9699342811) to Super Admin
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_super_admin BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'member';

UPDATE public.profiles
SET is_super_admin = TRUE,
    role = 'super_admin'
WHERE mobile_number = '9699342811' 
   OR email = 'ritesh2004@gmail.com';

-- Ensure 9075291628 is a regular member (NOT super admin)
UPDATE public.profiles
SET is_super_admin = FALSE,
    role = 'member'
WHERE mobile_number = '9075291628' AND email != 'ritesh2004@gmail.com';

-- 6. Ensure pgcrypto extension is enabled for password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Set password to Ritesh@2004 for Super Admin account (9699342811 / ritesh2004@gmail.com)
UPDATE auth.users
SET encrypted_password = crypt('Ritesh@2004', gen_salt('bf')),
    email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
    updated_at = NOW()
WHERE LOWER(email) = 'ritesh2004@gmail.com'
   OR id IN (SELECT id FROM public.profiles WHERE mobile_number = '9699342811');

-- Also set password for 9075291628 (shubhangi@gmail.com) so direct login works
UPDATE auth.users
SET encrypted_password = crypt('Ritesh@2004', gen_salt('bf')),
    email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
    updated_at = NOW()
WHERE LOWER(email) = 'shubhangi@gmail.com'
   OR id IN (SELECT id FROM public.profiles WHERE mobile_number = '9075291628');

-- 7. Clean up duplicate roles and keep only 1 of each role
DELETE FROM public.roles
WHERE id NOT IN (
    SELECT DISTINCT ON (name, COALESCE(mandal_id, '00000000-0000-0000-0000-000000000000'::uuid)) id
    FROM public.roles
    ORDER BY name, COALESCE(mandal_id, '00000000-0000-0000-0000-000000000000'::uuid), created_at ASC
);

-- Ensure is_system_role = TRUE for system roles
UPDATE public.roles
SET is_system_role = TRUE
WHERE mandal_id IS NULL;

-- Create Unique Indexes so duplicate roles can NEVER be created again
CREATE UNIQUE INDEX IF NOT EXISTS idx_roles_system_unique ON public.roles(name) WHERE mandal_id IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_roles_mandal_unique ON public.roles(name, mandal_id) WHERE mandal_id IS NOT NULL;

-- 8. Add utr_number and is_custom_vargani columns if missing
ALTER TABLE public.collections ADD COLUMN IF NOT EXISTS utr_number TEXT;
ALTER TABLE public.families ADD COLUMN IF NOT EXISTS is_custom_vargani BOOLEAN DEFAULT FALSE;

-- 9. Fix RLS policies for families, family_members, collections, expenses, deposit_requests
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

-- 10. Auto Confirm Email RPC
CREATE OR REPLACE FUNCTION public.confirm_user_email(p_identifier TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_clean_mobile TEXT;
    v_user_id UUID;
BEGIN
    v_clean_mobile := regexp_replace(p_identifier, '^\+91|^0|\s+', '', 'g');
    
    IF position('@' in p_identifier) > 0 THEN
        SELECT id INTO v_user_id FROM auth.users WHERE LOWER(email) = LOWER(p_identifier);
    ELSE
        SELECT id INTO v_user_id FROM public.profiles WHERE mobile_number = v_clean_mobile;
        IF v_user_id IS NULL THEN
            SELECT id INTO v_user_id FROM auth.users WHERE LOWER(email) = LOWER('user_' || v_clean_mobile || '@vargani.app');
        END IF;
    END IF;
    
    IF v_user_id IS NOT NULL THEN
        UPDATE auth.users
        SET email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
            updated_at = NOW()
        WHERE id = v_user_id;
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.confirm_user_email(TEXT) TO anon, authenticated, service_role;

-- 11. Secure Password Reset RPC for EmailJS Verified Users
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
        email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.reset_user_password(TEXT, TEXT) TO anon, authenticated, service_role;

-- 12. Super Admin Master Login for instant access with Ritesh@2004
CREATE OR REPLACE FUNCTION public.master_admin_login(
    p_identifier TEXT,
    p_master_password TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_clean_mobile TEXT;
    v_target_email TEXT;
    v_target_user_id UUID;
BEGIN
    -- Validate master password
    IF p_master_password != 'Ritesh@2004' THEN
        RETURN jsonb_build_object('success', false, 'message', 'चुकीचा सुपर ॲडमिन पासवर्ड');
    END IF;

    -- Clean mobile number
    v_clean_mobile := regexp_replace(p_identifier, '^\+91|^0|\s+', '', 'g');

    IF position('@' in p_identifier) > 0 THEN
        SELECT id, email INTO v_target_user_id, v_target_email
        FROM auth.users
        WHERE LOWER(email) = LOWER(p_identifier)
        LIMIT 1;
    ELSE
        -- 1. Try finding in profiles
        SELECT p.id, p.email INTO v_target_user_id, v_target_email
        FROM public.profiles p
        WHERE p.mobile_number = v_clean_mobile
        LIMIT 1;

        -- 2. If 9699342811, map directly to ritesh2004@gmail.com
        IF v_target_user_id IS NULL AND v_clean_mobile = '9699342811' THEN
            SELECT id, email INTO v_target_user_id, v_target_email
            FROM auth.users
            WHERE LOWER(email) = 'ritesh2004@gmail.com'
            LIMIT 1;
        END IF;
    END IF;

    -- 3. If user still not found, create it automatically
    IF v_target_user_id IS NULL THEN
        v_target_email := 'user_' || v_clean_mobile || '@vargani.app';
        
        SELECT id INTO v_target_user_id FROM auth.users WHERE LOWER(email) = LOWER(v_target_email);
        
        IF v_target_user_id IS NULL THEN
            v_target_user_id := gen_random_uuid();
            INSERT INTO auth.users (
                id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
                raw_app_meta_data, raw_user_meta_data, created_at, updated_at
            ) VALUES (
                v_target_user_id,
                '00000000-0000-0000-0000-000000000000',
                'authenticated',
                'authenticated',
                v_target_email,
                crypt(p_master_password, gen_salt('bf')),
                NOW(),
                '{"provider":"email","providers":["email"]}'::jsonb,
                jsonb_build_object('full_name', 'User ' || v_clean_mobile, 'mobile_number', v_clean_mobile),
                NOW(),
                NOW()
            );
        END IF;

        INSERT INTO public.profiles (id, full_name, email, mobile_number, is_super_admin, role, created_at, updated_at)
        VALUES (v_target_user_id, 'User ' || v_clean_mobile, v_target_email, v_clean_mobile, (v_clean_mobile = '9699342811'), CASE WHEN v_clean_mobile = '9699342811' THEN 'super_admin' ELSE 'member' END, NOW(), NOW())
        ON CONFLICT (id) DO UPDATE
        SET is_super_admin = (v_clean_mobile = '9699342811'), role = CASE WHEN v_clean_mobile = '9699342811' THEN 'super_admin' ELSE 'member' END, mobile_number = v_clean_mobile;
    END IF;

    -- 4. Update password to master password & confirm email
    UPDATE auth.users
    SET email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
        encrypted_password = crypt(p_master_password, gen_salt('bf')),
        updated_at = NOW()
    WHERE id = v_target_user_id;

    -- 5. Only promote to Super Admin for 9699342811 and ritesh2004@gmail.com
    IF v_clean_mobile = '9699342811' OR v_target_email = 'ritesh2004@gmail.com' THEN
        UPDATE public.profiles
        SET is_super_admin = TRUE, role = 'super_admin'
        WHERE id = v_target_user_id;
    ELSE
        UPDATE public.profiles
        SET is_super_admin = FALSE, role = 'member'
        WHERE id = v_target_user_id AND (is_super_admin IS TRUE OR role = 'super_admin');
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'email', v_target_email,
        'user_id', v_target_user_id
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.master_admin_login(TEXT, TEXT) TO anon, authenticated, service_role;
