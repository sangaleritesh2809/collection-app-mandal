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

-- ==============================================================================
-- 9. ALLOW SUPER ADMIN & MANDAL ADMIN TO PROCESS DEPOSIT REQUESTS
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.process_deposit_request(
    p_request_id UUID,
    p_action TEXT, -- 'approved' or 'rejected'
    p_rejection_reason TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_req RECORD;
    v_is_authorized BOOLEAN := FALSE;
    v_is_super_admin BOOLEAN := FALSE;
BEGIN
    -- Validate action
    IF p_action NOT IN ('approved', 'rejected') THEN
        RAISE EXCEPTION 'Invalid action: must be approved or rejected';
    END IF;

    -- Lock the deposit request row
    SELECT * INTO v_req
    FROM public.deposit_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Deposit request not found';
    END IF;

    -- Enforce: Only pending requests can be decided
    IF v_req.status <> 'pending' THEN
        RAISE EXCEPTION 'Cannot modify request that has already been %', v_req.status;
    END IF;

    -- Check if user is Super Admin
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = v_user_id AND (is_super_admin IS TRUE OR role = 'super_admin' OR mobile_number = '9699342811')
    ) INTO v_is_super_admin;

    -- Authorization check: Super Admin OR designated treasurer OR Mandal Admin
    IF v_is_super_admin THEN
        v_is_authorized := TRUE;
    ELSIF v_req.designated_treasurer_id = v_user_id THEN
        v_is_authorized := TRUE;
    ELSE
        SELECT EXISTS (
            SELECT 1 FROM public.mandal_memberships mm
            JOIN public.roles r ON mm.role_id = r.id
            WHERE mm.mandal_id = v_req.mandal_id 
              AND mm.user_id = v_user_id
              AND (r.name = 'Mandal Admin' OR r.name = 'Super Admin')
        ) INTO v_is_authorized;
    END IF;

    IF NOT v_is_authorized THEN
        RAISE EXCEPTION 'Not authorized: only the designated treasurer, mandal admin, or super admin may process this request';
    END IF;

    -- Reject reason check
    IF p_action = 'rejected' AND (p_rejection_reason IS NULL OR TRIM(p_rejection_reason) = '') THEN
        RAISE EXCEPTION 'A reason is required to reject a deposit request';
    END IF;

    -- Update deposit request status
    UPDATE public.deposit_requests
    SET status = p_action,
        decided_by = v_user_id,
        decision_date = NOW(),
        rejection_reason = CASE WHEN p_action = 'rejected' THEN p_rejection_reason ELSE NULL END,
        updated_at = NOW()
    WHERE id = p_request_id;

    -- If approved, mark all un-deposited collections by this collector in this mandal as deposited
    IF p_action = 'approved' THEN
        UPDATE public.collections
        SET is_deposited = TRUE,
            deposit_request_id = p_request_id,
            updated_at = NOW()
        WHERE mandal_id = v_req.mandal_id
          AND collector_id = v_req.collector_id
          AND is_deposited = FALSE;
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'request_id', p_request_id,
        'status', p_action
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.process_deposit_request(UUID, TEXT, TEXT) TO authenticated, service_role;

-- Update RLS policies to allow Super Admin and Mandal Admin to view & update deposit requests
DROP POLICY IF EXISTS "Deposit requests select" ON public.deposit_requests;
CREATE POLICY "Deposit requests select" ON public.deposit_requests FOR SELECT USING (
    public.is_mandal_member(mandal_id) OR public.is_super_admin()
);

DROP POLICY IF EXISTS "Deposit requests update" ON public.deposit_requests;
CREATE POLICY "Deposit requests update" ON public.deposit_requests FOR UPDATE USING (
    auth.uid() = designated_treasurer_id OR public.is_mandal_member(mandal_id) OR public.is_super_admin()
);

-- ==============================================================================
-- 10. RPC TO MANUALLY ADD A MEMBER TO A MANDAL (WITH CUSTOM/DEFAULT PASSWORD)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.add_manual_member(
    p_mandal_id UUID,
    p_full_name TEXT,
    p_mobile_number TEXT,
    p_role_name TEXT DEFAULT 'Collector',
    p_password TEXT DEFAULT 'Mandal@123'
)
RETURNS JSONB AS $$
DECLARE
    v_clean_mobile TEXT;
    v_target_user_id UUID;
    v_target_email TEXT;
    v_target_password TEXT;
    v_role_id UUID;
BEGIN
    -- 1. Clean mobile number to 10 digits
    v_clean_mobile := REGEXP_REPLACE(p_mobile_number, '\D', '', 'g');
    IF LENGTH(v_clean_mobile) > 10 THEN
        v_clean_mobile := RIGHT(v_clean_mobile, 10);
    END IF;

    IF LENGTH(v_clean_mobile) <> 10 THEN
        RAISE EXCEPTION 'Invalid mobile: must be 10 digits';
    END IF;

    IF p_full_name IS NULL OR TRIM(p_full_name) = '' THEN
        RAISE EXCEPTION 'Name is required';
    END IF;

    v_target_password := COALESCE(NULLIF(TRIM(p_password), ''), 'Mandal@123');

    -- 2. Find profile by mobile
    SELECT id INTO v_target_user_id FROM public.profiles WHERE mobile_number = v_clean_mobile LIMIT 1;

    -- If not found, create in auth.users & profiles
    IF v_target_user_id IS NULL THEN
        v_target_email := 'user_' || v_clean_mobile || '@vargani.app';
        SELECT id INTO v_target_user_id FROM auth.users WHERE LOWER(email) = LOWER(v_target_email) LIMIT 1;

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
                crypt(v_target_password, gen_salt('bf')),
                NOW(),
                '{"provider":"email","providers":["email"]}'::jsonb,
                jsonb_build_object('full_name', TRIM(p_full_name), 'mobile_number', v_clean_mobile),
                NOW(),
                NOW()
            );
        ELSE
            UPDATE auth.users
            SET encrypted_password = crypt(v_target_password, gen_salt('bf')),
                updated_at = NOW()
            WHERE id = v_target_user_id;
        END IF;

        INSERT INTO public.profiles (id, full_name, email, mobile_number, is_super_admin, role, created_at, updated_at)
        VALUES (v_target_user_id, TRIM(p_full_name), v_target_email, v_clean_mobile, (v_clean_mobile = '9699342811'), CASE WHEN v_clean_mobile = '9699342811' THEN 'super_admin' ELSE 'member' END, NOW(), NOW())
        ON CONFLICT (id) DO UPDATE
        SET full_name = EXCLUDED.full_name, mobile_number = EXCLUDED.mobile_number, updated_at = NOW();
    ELSE
        -- Update password for existing user if custom password supplied
        UPDATE auth.users
        SET encrypted_password = crypt(v_target_password, gen_salt('bf')),
            updated_at = NOW()
        WHERE id = v_target_user_id;
    END IF;

    -- 3. Find Role ID
    SELECT id INTO v_role_id FROM public.roles WHERE name = p_role_name LIMIT 1;
    IF v_role_id IS NULL THEN
        SELECT id INTO v_role_id FROM public.roles WHERE name = 'Collector' LIMIT 1;
    END IF;

    -- 4. Insert or update membership
    INSERT INTO public.mandal_memberships (mandal_id, user_id, role_id, status, joined_at)
    VALUES (p_mandal_id, v_target_user_id, v_role_id, 'active', NOW())
    ON CONFLICT (mandal_id, user_id) DO UPDATE
    SET role_id = EXCLUDED.role_id, status = 'active';

    RETURN jsonb_build_object(
        'success', TRUE,
        'user_id', v_target_user_id,
        'full_name', TRIM(p_full_name),
        'mobile_number', v_clean_mobile,
        'role_name', p_role_name
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.add_manual_member(UUID, TEXT, TEXT, TEXT, TEXT) TO authenticated, service_role;

-- ==============================================================================
-- 11. RPC FOR MEMBERS TO SET THEIR OWN PASSWORD (FIRST-TIME OR RESET)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.set_member_password(
    p_mobile_number TEXT,
    p_new_password TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_clean_mobile TEXT;
    v_user_id UUID;
    v_email TEXT;
BEGIN
    v_clean_mobile := REGEXP_REPLACE(p_mobile_number, '\D', '', 'g');
    IF LENGTH(v_clean_mobile) > 10 THEN
        v_clean_mobile := RIGHT(v_clean_mobile, 10);
    END IF;

    IF LENGTH(v_clean_mobile) <> 10 THEN
        RETURN jsonb_build_object('success', false, 'error', 'कृपया वैध १०-अंकी मोबाईल नंबर टाका.');
    END IF;

    IF p_new_password IS NULL OR LENGTH(TRIM(p_new_password)) < 6 THEN
        RETURN jsonb_build_object('success', false, 'error', 'पासवर्ड किमान ६ अक्षरांचा असावा.');
    END IF;

    -- 1. Find profile by mobile number
    SELECT id, email INTO v_user_id, v_email FROM public.profiles WHERE mobile_number = v_clean_mobile LIMIT 1;

    -- 2. If not in profiles, check auth.users by email
    IF v_user_id IS NULL THEN
        v_email := 'user_' || v_clean_mobile || '@vargani.app';
        SELECT id INTO v_user_id FROM auth.users WHERE LOWER(email) = LOWER(v_email) LIMIT 1;
    END IF;

    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'मोबाईल नंबर ' || v_clean_mobile || ' कोणत्याही मंडळात आढळला नाही. कृपया ॲडमिनने तुम्हाला जोडले आहे का ते तपासा किंवा नवीन नोंदणी करा.');
    END IF;

    -- 3. Update password in auth.users
    UPDATE auth.users
    SET encrypted_password = crypt(TRIM(p_new_password), gen_salt('bf')),
        email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'email', v_email,
        'message', 'पासवर्ड यशस्वीपणे सेट झाला आहे!'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.set_member_password(TEXT, TEXT) TO anon, authenticated, service_role;

-- ==============================================================================
-- 12. ADMOB BANNER ADS CONFIGURATION TABLE & RLS POLICIES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.ad_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    is_ads_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    is_test_mode BOOLEAN NOT NULL DEFAULT TRUE,
    app_id_android TEXT NOT NULL DEFAULT 'ca-app-pub-3940256099942544~3347511713',
    banner_ad_unit_id_android TEXT NOT NULL DEFAULT 'ca-app-pub-3940256099942544/6300978111',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by UUID REFERENCES public.profiles(id)
);

-- Ensure a single default row exists
INSERT INTO public.ad_settings (
    is_ads_enabled,
    is_test_mode,
    app_id_android,
    banner_ad_unit_id_android,
    updated_at
)
SELECT TRUE, TRUE, 'ca-app-pub-3940256099942544~3347511713', 'ca-app-pub-3940256099942544/6300978111', NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.ad_settings);

-- RLS Configuration
ALTER TABLE public.ad_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone authenticated can view ad settings" ON public.ad_settings;
CREATE POLICY "Anyone authenticated can view ad settings" ON public.ad_settings
FOR SELECT USING (auth.role() = 'authenticated' OR public.is_super_admin());

DROP POLICY IF EXISTS "Super Admin can update ad settings" ON public.ad_settings;
CREATE POLICY "Super Admin can update ad settings" ON public.ad_settings
FOR UPDATE USING (public.is_super_admin());

DROP POLICY IF EXISTS "Super Admin can insert ad settings" ON public.ad_settings;
CREATE POLICY "Super Admin can insert ad settings" ON public.ad_settings
FOR INSERT WITH CHECK (public.is_super_admin());

-- ==============================================================================
-- 15. Bank Transactions Table for Automated Real-Time SMS Listener Verification
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.bank_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL,
    utr_number TEXT NOT NULL,
    sender_info TEXT,
    bank_name TEXT,
    raw_sms TEXT,
    is_claimed BOOLEAN DEFAULT FALSE,
    claimed_by_receipt TEXT,
    claimed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bank_transactions_mandal_utr ON public.bank_transactions(mandal_id, utr_number);
CREATE INDEX IF NOT EXISTS idx_bank_transactions_utr ON public.bank_transactions(utr_number);

ALTER TABLE public.bank_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Bank transactions access" ON public.bank_transactions;
CREATE POLICY "Bank transactions access" ON public.bank_transactions
FOR ALL USING (auth.role() = 'authenticated' OR auth.role() = 'anon');
