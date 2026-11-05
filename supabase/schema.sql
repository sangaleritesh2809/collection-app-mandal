-- ==============================================================================
-- VARGANI COLLECTION - COMPLETE MANDAL MANAGEMENT DATABASE SCHEMA
-- PostgreSQL & Supabase Database Architecture
-- ==============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 1. PROFILES (Linked to Supabase auth.users)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE,
    mobile_number TEXT UNIQUE,
    avatar_url TEXT,
    is_super_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Index on mobile number and email
CREATE INDEX IF NOT EXISTS idx_profiles_mobile ON public.profiles(mobile_number);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- Trigger to create profile on signup (gracefully handles existing mobile/email)
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
    -- If mobile number already belongs to another user, insert profile without conflicting mobile number
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

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- 2. MANDALS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.mandals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id TEXT UNIQUE NOT NULL, -- e.g. MD-2026-001
    name TEXT NOT NULL,
    description TEXT,
    logo_url TEXT,
    address TEXT,
    village TEXT,
    taluka TEXT,
    district TEXT,
    state TEXT DEFAULT 'Maharashtra',
    contact_number TEXT,
    email TEXT,
    establishment_date DATE,
    invitation_code TEXT UNIQUE NOT NULL, -- e.g. VG2026A
    qr_code_url TEXT,                     -- Photo of official payment QR code (PhonePe/GPay standee)
    upi_id TEXT,                          -- Mandal's UPI ID (e.g. mandal@upi)
    upi_payee_name TEXT,                  -- Beneficiary Name on UPI
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_mandals_invitation_code ON public.mandals(invitation_code);
CREATE INDEX IF NOT EXISTS idx_mandals_active ON public.mandals(is_active);

-- Helper to generate unique invitation code
CREATE OR REPLACE FUNCTION public.generate_unique_invitation_code(p_prefix TEXT DEFAULT 'VG')
RETURNS TEXT AS $$
DECLARE
    v_code TEXT;
    v_exists BOOLEAN;
BEGIN
    LOOP
        v_code := p_prefix || TO_CHAR(NOW(), 'YY') || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4));
        SELECT EXISTS(SELECT 1 FROM public.mandals WHERE invitation_code = v_code) INTO v_exists;
        IF NOT v_exists THEN
            RETURN v_code;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ==============================================================================
-- 3. ROLES & PERMISSIONS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE, -- NULL for system-wide default roles
    name TEXT NOT NULL, -- 'Super Admin', 'Mandal Admin', 'Treasurer', 'Collector', 'Member'
    description TEXT,
    is_system_role BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Unique index to prevent duplicate roles (System roles & per-mandal roles)
CREATE UNIQUE INDEX IF NOT EXISTS idx_roles_system_unique ON public.roles(name) WHERE mandal_id IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_roles_mandal_unique ON public.roles(name, mandal_id) WHERE mandal_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL, -- e.g. 'view_dashboard', 'manage_mandal', etc.
    name TEXT NOT NULL,
    module TEXT NOT NULL, -- 'dashboard', 'mandal', 'family', 'collection', 'deposit', 'expense', 'reports'
    description TEXT
);

CREATE TABLE IF NOT EXISTS public.role_permissions (
    role_id UUID REFERENCES public.roles(id) ON DELETE CASCADE,
    permission_id UUID REFERENCES public.permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- ==============================================================================
-- 4. MANDAL MEMBERSHIPS (Multi-tenant link between Users and Mandals)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.mandal_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID NOT NULL REFERENCES public.mandals(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES public.roles(id) ON DELETE RESTRICT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    joined_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE (mandal_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_memberships_user ON public.mandal_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_memberships_mandal ON public.mandal_memberships(mandal_id);

-- ==============================================================================
-- 5. VARGANI CONFIGURATIONS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.vargani_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID NOT NULL REFERENCES public.mandals(id) ON DELETE CASCADE,
    name TEXT NOT NULL, -- e.g. 'गणेशोत्सव २०२६ वर्गणी'
    financial_year TEXT NOT NULL, -- e.g. '2026-2027'
    calculation_type TEXT NOT NULL DEFAULT 'per_member' CHECK (calculation_type IN ('per_member', 'per_family', 'fixed')),
    per_member_amount NUMERIC(12,2) DEFAULT 0.00 NOT NULL,
    fixed_amount NUMERIC(12,2) DEFAULT 0.00 NOT NULL,
    start_date DATE,
    end_date DATE,
    due_date DATE,
    discount NUMERIC(12,2) DEFAULT 0.00,
    special_contribution NUMERIC(12,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_vargani_configs_mandal ON public.vargani_configs(mandal_id);

-- ==============================================================================
-- 6. FAMILIES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.families (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID NOT NULL REFERENCES public.mandals(id) ON DELETE CASCADE,
    family_code TEXT NOT NULL, -- e.g. FAM-001
    family_name TEXT NOT NULL,
    family_head_name TEXT NOT NULL,
    house_number TEXT,
    address TEXT,
    village TEXT,
    mobile_number TEXT,
    total_members INTEGER DEFAULT 1 NOT NULL,
    vargani_config_id UUID REFERENCES public.vargani_configs(id) ON DELETE SET NULL,
    total_vargani NUMERIC(12,2) DEFAULT 0.00 NOT NULL,
    paid_amount NUMERIC(12,2) DEFAULT 0.00 NOT NULL,
    pending_amount NUMERIC(12,2) DEFAULT 0.00 NOT NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE (mandal_id, family_code)
);

CREATE INDEX IF NOT EXISTS idx_families_mandal ON public.families(mandal_id);
CREATE INDEX IF NOT EXISTS idx_families_head ON public.families(family_head_name);

-- ==============================================================================
-- 7. FAMILY MEMBERS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.family_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    mandal_id UUID NOT NULL REFERENCES public.mandals(id) ON DELETE CASCADE,
    member_name TEXT NOT NULL,
    mobile_number TEXT,
    age INTEGER,
    gender TEXT CHECK (gender IN ('Male', 'Female', 'Other')),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'archived')),
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_family_members_fam ON public.family_members(family_id);

-- ==============================================================================
-- 8. DEPOSIT REQUESTS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.deposit_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_number TEXT UNIQUE NOT NULL, -- e.g. DEP-2026-0001
    mandal_id UUID NOT NULL REFERENCES public.mandals(id) ON DELETE CASCADE,
    collector_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    designated_treasurer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payment_mode TEXT NOT NULL DEFAULT 'cash' CHECK (payment_mode IN ('cash', 'upi', 'bank_transfer', 'cheque', 'other')),
    request_date DATE DEFAULT CURRENT_DATE NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    decided_by UUID REFERENCES public.profiles(id),
    decision_date TIMESTAMPTZ,
    rejection_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_deposit_requests_mandal ON public.deposit_requests(mandal_id);
CREATE INDEX IF NOT EXISTS idx_deposit_requests_treasurer ON public.deposit_requests(designated_treasurer_id);
CREATE INDEX IF NOT EXISTS idx_deposit_requests_collector ON public.deposit_requests(collector_id);

-- ==============================================================================
-- 9. COLLECTIONS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID NOT NULL REFERENCES public.mandals(id) ON DELETE CASCADE,
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE RESTRICT,
    collector_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    vargani_config_id UUID REFERENCES public.vargani_configs(id),
    transaction_number TEXT UNIQUE NOT NULL, -- TXN-2026-000001
    receipt_number TEXT UNIQUE NOT NULL,     -- RCT-2026-000001
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payment_mode TEXT NOT NULL DEFAULT 'cash' CHECK (payment_mode IN ('cash', 'upi', 'bank_transfer', 'cheque', 'other')),
    collection_date DATE DEFAULT CURRENT_DATE NOT NULL,
    notes TEXT,
    utr_number TEXT,
    receipt_url TEXT,
    is_deposited BOOLEAN DEFAULT FALSE NOT NULL,
    deposit_request_id UUID REFERENCES public.deposit_requests(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_collections_mandal ON public.collections(mandal_id);
CREATE INDEX IF NOT EXISTS idx_collections_family ON public.collections(family_id);
CREATE INDEX IF NOT EXISTS idx_collections_collector ON public.collections(collector_id);
CREATE INDEX IF NOT EXISTS idx_collections_date ON public.collections(collection_date);

-- ==============================================================================
-- 10. EXPENSES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID NOT NULL REFERENCES public.mandals(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN (
        'Decoration', 'Sound System', 'Lighting', 'Food', 'Transport', 
        'Electricity', 'Event Management', 'Pooja Sahitya', 'Prize & Gifts', 'Other'
    )),
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    expense_date DATE DEFAULT CURRENT_DATE NOT NULL,
    paid_by TEXT NOT NULL,
    paid_to TEXT NOT NULL,
    payment_mode TEXT NOT NULL DEFAULT 'cash' CHECK (payment_mode IN ('cash', 'upi', 'bank_transfer', 'cheque', 'other')),
    description TEXT,
    bill_image_url TEXT,
    receipt_image_url TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    approval_status TEXT NOT NULL DEFAULT 'approved' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    approval_date TIMESTAMPTZ,
    rejection_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_expenses_mandal ON public.expenses(mandal_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON public.expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON public.expenses(expense_date);

-- ==============================================================================
-- 11. AUDIT LOGS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    module TEXT NOT NULL,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_mandal ON public.audit_logs(mandal_id);

-- ==============================================================================
-- 12. NOTIFICATIONS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT DEFAULT 'general',
    is_read BOOLEAN DEFAULT FALSE NOT NULL,
    data JSONB,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, is_read);

-- ==============================================================================
-- 13. BUSINESS LOGIC TRIGGERS & RE-CALCULATIONS
-- ==============================================================================

-- A. Auto recalculate active family members & expected vargani
CREATE OR REPLACE FUNCTION public.recalculate_family_totals()
RETURNS TRIGGER AS $$
DECLARE
    v_family_id UUID;
    v_active_count INTEGER;
    v_config RECORD;
    v_total_vargani NUMERIC(12,2) := 0;
    v_total_paid NUMERIC(12,2) := 0;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_family_id := OLD.family_id;
    ELSE
        v_family_id := NEW.family_id;
    END IF;

    -- Count active members
    SELECT COUNT(*) INTO v_active_count
    FROM public.family_members
    WHERE family_id = v_family_id AND status = 'active';

    -- Fetch family's current vargani config (strictly matching family's mandal_id)
    SELECT c.* INTO v_config
    FROM public.families f
    JOIN public.vargani_configs c ON (
        (f.vargani_config_id IS NOT NULL AND c.id = f.vargani_config_id AND c.mandal_id = f.mandal_id)
        OR
        (f.vargani_config_id IS NULL AND c.mandal_id = f.mandal_id AND c.is_active = TRUE)
    )
    WHERE f.id = v_family_id
    ORDER BY c.is_active DESC, c.created_at DESC
    LIMIT 1;

    -- Calculate total vargani
    IF v_config.id IS NOT NULL THEN
        IF v_config.calculation_type = 'per_member' THEN
            v_total_vargani := (v_active_count * v_config.per_member_amount) - COALESCE(v_config.discount, 0) + COALESCE(v_config.special_contribution, 0);
        ELSIF v_config.calculation_type = 'fixed' OR v_config.calculation_type = 'per_family' THEN
            v_total_vargani := v_config.fixed_amount - COALESCE(v_config.discount, 0) + COALESCE(v_config.special_contribution, 0);
        END IF;
    END IF;

    -- Calculate total already paid
    SELECT COALESCE(SUM(amount), 0) INTO v_total_paid
    FROM public.collections
    WHERE family_id = v_family_id;

    -- Update family record
    UPDATE public.families
    SET vargani_config_id = COALESCE(vargani_config_id, v_config.id),
        total_members = GREATEST(v_active_count, 1),
        total_vargani = GREATEST(v_total_vargani, 0),
        paid_amount = v_total_paid,
        pending_amount = GREATEST(v_total_vargani - v_total_paid, 0),
        updated_at = NOW()
    WHERE id = v_family_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_family_members_recalc ON public.family_members;
CREATE TRIGGER trg_family_members_recalc
    AFTER INSERT OR UPDATE OR DELETE ON public.family_members
    FOR EACH ROW EXECUTE FUNCTION public.recalculate_family_totals();

-- B. Auto-apply Mandal Vargani Config changes strictly to families of that specific Mandal ONLY
CREATE OR REPLACE FUNCTION public.apply_vargani_config_to_mandal_families()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_active = TRUE THEN
        -- Deactivate older configs for THIS specific mandal only
        UPDATE public.vargani_configs
        SET is_active = FALSE
        WHERE mandal_id = NEW.mandal_id 
          AND id <> NEW.id 
          AND is_active = TRUE;

        -- Recalculate families belonging ONLY to this specific mandal
        UPDATE public.families f
        SET vargani_config_id = NEW.id,
            total_vargani = CASE 
                WHEN NEW.calculation_type = 'per_member' THEN 
                    (GREATEST(f.total_members, 1) * NEW.per_member_amount) - COALESCE(NEW.discount, 0) + COALESCE(NEW.special_contribution, 0)
                ELSE 
                    NEW.fixed_amount - COALESCE(NEW.discount, 0) + COALESCE(NEW.special_contribution, 0)
            END,
            pending_amount = GREATEST(
                (CASE 
                    WHEN NEW.calculation_type = 'per_member' THEN 
                        (GREATEST(f.total_members, 1) * NEW.per_member_amount) - COALESCE(NEW.discount, 0) + COALESCE(NEW.special_contribution, 0)
                    ELSE 
                        NEW.fixed_amount - COALESCE(NEW.discount, 0) + COALESCE(NEW.special_contribution, 0)
                END) - f.paid_amount, 0
            ),
            updated_at = NOW()
        WHERE f.mandal_id = NEW.mandal_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_vargani_config_apply ON public.vargani_configs;
CREATE TRIGGER trg_vargani_config_apply
    AFTER INSERT OR UPDATE OF per_member_amount, fixed_amount, calculation_type, discount, special_contribution, is_active
    ON public.vargani_configs
    FOR EACH ROW
    EXECUTE FUNCTION public.apply_vargani_config_to_mandal_families();

-- B. Auto update family paid and pending amounts upon collection insertion/update/deletion
CREATE OR REPLACE FUNCTION public.recalculate_family_collections()
RETURNS TRIGGER AS $$
DECLARE
    v_family_id UUID;
    v_total_paid NUMERIC(12,2) := 0;
    v_total_vargani NUMERIC(12,2) := 0;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_family_id := OLD.family_id;
    ELSE
        v_family_id := NEW.family_id;
    END IF;

    SELECT COALESCE(SUM(amount), 0) INTO v_total_paid
    FROM public.collections
    WHERE family_id = v_family_id;

    SELECT total_vargani INTO v_total_vargani
    FROM public.families
    WHERE id = v_family_id;

    UPDATE public.families
    SET paid_amount = v_total_paid,
        pending_amount = GREATEST(v_total_vargani - v_total_paid, 0),
        updated_at = NOW()
    WHERE id = v_family_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_collections_recalc ON public.collections;
CREATE TRIGGER trg_collections_recalc
    AFTER INSERT OR UPDATE OR DELETE ON public.collections
    FOR EACH ROW EXECUTE FUNCTION public.recalculate_family_collections();

-- ==============================================================================
-- 14. ATOMIC DEPOSIT REQUEST APPROVAL / REJECTION FUNCTION
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

    -- Authorization check: caller must be designated treasurer OR Mandal Admin
    IF v_req.designated_treasurer_id = v_user_id THEN
        v_is_authorized := TRUE;
    ELSE
        -- Check if user is Mandal Admin
        SELECT EXISTS (
            SELECT 1 FROM public.mandal_memberships mm
            JOIN public.roles r ON mm.role_id = r.id
            WHERE mm.mandal_id = v_req.mandal_id 
              AND mm.user_id = v_user_id
              AND (r.name = 'Mandal Admin' OR r.name = 'Super Admin')
        ) INTO v_is_authorized;
    END IF;

    IF NOT v_is_authorized THEN
        RAISE EXCEPTION 'Not authorized: only the designated treasurer or mandal admin may process this request';
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

    -- If approved, mark collector's collections as deposited up to this request
    IF p_action = 'approved' THEN
        UPDATE public.collections
        SET is_deposited = TRUE,
            deposit_request_id = p_request_id,
            updated_at = NOW()
        WHERE mandal_id = v_req.mandal_id
          AND collector_id = v_req.collector_id
          AND is_deposited = FALSE;
    END IF;

    -- Insert Audit Log
    INSERT INTO public.audit_logs (mandal_id, user_id, action, module, details)
    VALUES (
        v_req.mandal_id,
        v_user_id,
        'DEPOSIT_REQUEST_' || UPPER(p_action),
        'deposit',
        jsonb_build_object(
            'request_id', p_request_id,
            'request_number', v_req.request_number,
            'amount', v_req.amount,
            'collector_id', v_req.collector_id,
            'reason', p_rejection_reason
        )
    );

    -- Send notification to the collector
    INSERT INTO public.notifications (mandal_id, user_id, title, body, type, data)
    VALUES (
        v_req.mandal_id,
        v_req.collector_id,
        CASE WHEN p_action = 'approved' THEN 'ठेव विनंती मंजूर झाली!' ELSE 'ठेव विनंती नाकारली गेली' END,
        CASE WHEN p_action = 'approved' 
             THEN 'तुमची ₹' || v_req.amount || ' ची ठेव विनंती खजिनदाराने मंजूर केली आहे.'
             ELSE 'तुमची ₹' || v_req.amount || ' ची ठेव विनंती नाकारण्यात आली. कारण: ' || COALESCE(p_rejection_reason, 'कोणतेही नाही')
        END,
        'deposit_status',
        jsonb_build_object('request_id', p_request_id, 'status', p_action)
    );

    RETURN jsonb_build_object(
        'success', TRUE,
        'status', p_action,
        'request_id', p_request_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- 15. SEED SYSTEM ROLES & DEFAULT PERMISSIONS
-- ==============================================================================

-- Insert standard permissions
INSERT INTO public.permissions (code, name, module, description) VALUES
    ('view_dashboard', 'डॅशबोर्ड पहा', 'dashboard', 'डॅशबोर्डवरील आर्थिक आकडेवारी पाहणे'),
    ('manage_mandal', 'मंडळ व्यवस्थापन', 'mandal', 'मंडळ माहिती बदलणे आणि सेटिंग्स'),
    ('add_family', 'कुटुंब जोडा', 'family', 'नवीन कुटुंब नोंदणी'),
    ('edit_family', 'कुटुंब संपादित करा', 'family', 'कुटुंबाची माहिती बदलणे'),
    ('delete_family', 'कुटुंब हटवा', 'family', 'कुटुंब दप्तरबंद / हटवणे'),
    ('add_member', 'सदस्य जोडा', 'family', 'कुटुंब सदस्य जोडणे'),
    ('edit_member', 'सदस्य संपादित करा', 'family', 'कुटुंब सदस्य बदलणे'),
    ('view_collection', 'वर्गणी पहा', 'collection', 'वर्गणी नोंदी पाहणे'),
    ('add_collection', 'वर्गणी जमा करा', 'collection', 'नवीन वर्गणी पावती फाडणे'),
    ('edit_collection', 'वर्गणी संपादित करा', 'collection', 'वर्गणी पावती दुरुस्ती'),
    ('create_deposit_request', 'ठेव विनंती करा', 'deposit', 'खजिनदाराकडे गोळा केलेली रक्कम जमा करणे'),
    ('approve_deposit_request', 'ठेव विनंती मंजूर करा', 'deposit', 'खजिनदार म्हणून रक्कम स्वीकारणे'),
    ('reject_deposit_request', 'ठेव विनंती नाकारा', 'deposit', 'रक्कम स्वीकारणे नाकारणे'),
    ('add_expense', 'खर्च नोंदवा', 'expense', 'नवीन खर्चाची नोंद करणे'),
    ('approve_expense', 'खर्च मंजूर करा', 'expense', 'खर्च मंजूर करणे'),
    ('view_reports', 'अहवाल पहा', 'reports', 'आर्थिक अहवाल पाहणे'),
    ('export_reports', 'अहवाल डाउनलोड करा', 'reports', 'PDF आणि Excel अहवाल डाउनलोड करणे'),
    ('manage_users', 'वापरकर्ते व्यवस्थापन', 'users', 'मंडळ सदस्य व कार्यकर्ते व्यवस्थापन'),
    ('manage_roles', 'भूमिका व्यवस्थापन', 'roles', 'भूमिका आणि अधिकार ठरवणे')
ON CONFLICT (code) DO NOTHING;

-- Insert System Roles (idempotent with partial unique index)
INSERT INTO public.roles (name, description, is_system_role) VALUES
    ('Super Admin', 'प्लॅटफॉर्म सुपर ॲडमिन', TRUE),
    ('Mandal Admin', 'मंडळ प्रमुख / अध्यक्ष', TRUE),
    ('Treasurer', 'खजिनदार', TRUE),
    ('Collector', 'वर्गणी गोळा करणारा कार्यकर्ता', TRUE),
    ('Member', 'सर्वसाधारण सदस्य', TRUE)
ON CONFLICT (name) WHERE mandal_id IS NULL DO NOTHING;

-- Map permissions for default roles
DO $$
DECLARE
    r_admin UUID;
    r_treasurer UUID;
    r_collector UUID;
    r_member UUID;
BEGIN
    SELECT id INTO r_admin FROM public.roles WHERE name = 'Mandal Admin' AND is_system_role = TRUE LIMIT 1;
    SELECT id INTO r_treasurer FROM public.roles WHERE name = 'Treasurer' AND is_system_role = TRUE LIMIT 1;
    SELECT id INTO r_collector FROM public.roles WHERE name = 'Collector' AND is_system_role = TRUE LIMIT 1;
    SELECT id INTO r_member FROM public.roles WHERE name = 'Member' AND is_system_role = TRUE LIMIT 1;

    -- Mandal Admin gets all permissions
    IF r_admin IS NOT NULL THEN
        INSERT INTO public.role_permissions (role_id, permission_id)
        SELECT r_admin, id FROM public.permissions
        ON CONFLICT DO NOTHING;
    END IF;

    -- Treasurer permissions
    IF r_treasurer IS NOT NULL THEN
        INSERT INTO public.role_permissions (role_id, permission_id)
        SELECT r_treasurer, id FROM public.permissions
        WHERE code IN (
            'view_dashboard', 'view_collection', 'add_collection',
            'approve_deposit_request', 'reject_deposit_request',
            'add_expense', 'approve_expense', 'view_reports', 'export_reports'
        )
        ON CONFLICT DO NOTHING;
    END IF;

    -- Collector permissions
    IF r_collector IS NOT NULL THEN
        INSERT INTO public.role_permissions (role_id, permission_id)
        SELECT r_collector, id FROM public.permissions
        WHERE code IN (
            'view_dashboard', 'add_family', 'edit_family', 'add_member',
            'view_collection', 'add_collection', 'create_deposit_request', 'view_reports'
        )
        ON CONFLICT DO NOTHING;
    END IF;

    -- Member permissions
    IF r_member IS NOT NULL THEN
        INSERT INTO public.role_permissions (role_id, permission_id)
        SELECT r_member, id FROM public.permissions
        WHERE code IN ('view_dashboard', 'view_collection')
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- ==============================================================================
-- 16. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mandals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mandal_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vargani_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deposit_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Helper check if user is a member of the mandal (optimized with STABLE PARALLEL SAFE for fast RLS checks)
CREATE OR REPLACE FUNCTION public.is_mandal_member(p_mandal_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.mandal_memberships
        WHERE mandal_id = p_mandal_id AND user_id = auth.uid() AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE PARALLEL SAFE;

-- High-performance composite indexes for instant sub-millisecond query execution
CREATE INDEX IF NOT EXISTS idx_memberships_lookup ON public.mandal_memberships(mandal_id, user_id, status);
CREATE INDEX IF NOT EXISTS idx_collections_mandal_date ON public.collections(mandal_id, collection_date DESC, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_mandal_date ON public.expenses(mandal_id, expense_date DESC);
CREATE INDEX IF NOT EXISTS idx_deposit_requests_mandal_created ON public.deposit_requests(mandal_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_families_mandal_code ON public.families(mandal_id, status, family_code ASC);
CREATE INDEX IF NOT EXISTS idx_family_members_fam_active ON public.family_members(family_id, status);
CREATE INDEX IF NOT EXISTS idx_vargani_configs_active ON public.vargani_configs(mandal_id, is_active);

-- Profiles
DROP POLICY IF EXISTS "Public profiles are viewable" ON public.profiles;
CREATE POLICY "Public profiles are viewable" ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Mandals
DROP POLICY IF EXISTS "View mandal if member or code lookup" ON public.mandals;
CREATE POLICY "View mandal if member or code lookup" ON public.mandals FOR SELECT USING (
    is_active = TRUE OR public.is_mandal_member(id)
);

DROP POLICY IF EXISTS "Authenticated users can create mandal" ON public.mandals;
CREATE POLICY "Authenticated users can create mandal" ON public.mandals FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
);

DROP POLICY IF EXISTS "Mandal admin can update mandal" ON public.mandals;
CREATE POLICY "Mandal admin can update mandal" ON public.mandals FOR UPDATE USING (
    public.is_mandal_member(id)
);

-- Roles and Permissions
DROP POLICY IF EXISTS "Roles read by authenticated" ON public.roles;
CREATE POLICY "Roles read by authenticated" ON public.roles FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Permissions read by authenticated" ON public.permissions;
CREATE POLICY "Permissions read by authenticated" ON public.permissions FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Role permissions read by authenticated" ON public.role_permissions;
CREATE POLICY "Role permissions read by authenticated" ON public.role_permissions FOR SELECT USING (auth.role() = 'authenticated');

-- Mandal Memberships
DROP POLICY IF EXISTS "View memberships for own mandals" ON public.mandal_memberships;
CREATE POLICY "View memberships for own mandals" ON public.mandal_memberships FOR SELECT USING (
    user_id = auth.uid() OR public.is_mandal_member(mandal_id)
);

DROP POLICY IF EXISTS "Insert membership" ON public.mandal_memberships;
CREATE POLICY "Insert membership" ON public.mandal_memberships FOR INSERT WITH CHECK (
    auth.uid() = user_id OR public.is_mandal_member(mandal_id)
);

DROP POLICY IF EXISTS "Update membership" ON public.mandal_memberships;
CREATE POLICY "Update membership" ON public.mandal_memberships FOR UPDATE USING (
    public.is_mandal_member(mandal_id)
);

-- Vargani Configs
DROP POLICY IF EXISTS "Vargani configs access" ON public.vargani_configs;
CREATE POLICY "Vargani configs access" ON public.vargani_configs FOR ALL USING (public.is_mandal_member(mandal_id));

-- Families
DROP POLICY IF EXISTS "Families access" ON public.families;
CREATE POLICY "Families access" ON public.families FOR ALL USING (public.is_mandal_member(mandal_id));

-- Family Members
DROP POLICY IF EXISTS "Family members access" ON public.family_members;
CREATE POLICY "Family members access" ON public.family_members FOR ALL USING (public.is_mandal_member(mandal_id));

-- Collections
DROP POLICY IF EXISTS "Collections access" ON public.collections;
CREATE POLICY "Collections access" ON public.collections FOR ALL USING (public.is_mandal_member(mandal_id));

-- Deposit Requests
DROP POLICY IF EXISTS "Deposit requests select" ON public.deposit_requests;
CREATE POLICY "Deposit requests select" ON public.deposit_requests FOR SELECT USING (public.is_mandal_member(mandal_id));

DROP POLICY IF EXISTS "Deposit requests insert" ON public.deposit_requests;
CREATE POLICY "Deposit requests insert" ON public.deposit_requests FOR INSERT WITH CHECK (
    auth.uid() = collector_id AND public.is_mandal_member(mandal_id)
);

DROP POLICY IF EXISTS "Deposit requests update" ON public.deposit_requests;
CREATE POLICY "Deposit requests update" ON public.deposit_requests FOR UPDATE USING (
    auth.uid() = designated_treasurer_id OR public.is_mandal_member(mandal_id)
);

-- Expenses
DROP POLICY IF EXISTS "Expenses access" ON public.expenses;
CREATE POLICY "Expenses access" ON public.expenses FOR ALL USING (public.is_mandal_member(mandal_id));

-- Audit Logs
DROP POLICY IF EXISTS "Audit logs select" ON public.audit_logs;
CREATE POLICY "Audit logs select" ON public.audit_logs FOR SELECT USING (public.is_mandal_member(mandal_id));

DROP POLICY IF EXISTS "Audit logs insert" ON public.audit_logs;
CREATE POLICY "Audit logs insert" ON public.audit_logs FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Notifications
DROP POLICY IF EXISTS "Notifications own user" ON public.notifications;
CREATE POLICY "Notifications own user" ON public.notifications FOR ALL USING (auth.uid() = user_id);

-- ==============================================================================
-- 17. STORAGE BUCKETS SETUP
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public) VALUES 
    ('mandal_logos', 'mandal_logos', true),
    ('receipts', 'receipts', true),
    ('expense_bills', 'expense_bills', true),
    ('qr_codes', 'qr_codes', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public read for mandal_logos" ON storage.objects;
CREATE POLICY "Public read for mandal_logos" ON storage.objects FOR SELECT USING (bucket_id = 'mandal_logos');

DROP POLICY IF EXISTS "Auth upload for mandal_logos" ON storage.objects;
CREATE POLICY "Auth upload for mandal_logos" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'mandal_logos' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Public read for receipts" ON storage.objects;
CREATE POLICY "Public read for receipts" ON storage.objects FOR SELECT USING (bucket_id = 'receipts');

DROP POLICY IF EXISTS "Auth upload for receipts" ON storage.objects;
CREATE POLICY "Auth upload for receipts" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'receipts' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Public read for expense_bills" ON storage.objects;
CREATE POLICY "Public read for expense_bills" ON storage.objects FOR SELECT USING (bucket_id = 'expense_bills');

DROP POLICY IF EXISTS "Auth upload for expense_bills" ON storage.objects;
CREATE POLICY "Auth upload for expense_bills" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'expense_bills' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Public read for qr_codes" ON storage.objects;
CREATE POLICY "Public read for qr_codes" ON storage.objects FOR SELECT USING (bucket_id = 'qr_codes');

DROP POLICY IF EXISTS "Auth upload for qr_codes" ON storage.objects;
CREATE POLICY "Auth upload for qr_codes" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'qr_codes' AND auth.role() = 'authenticated');

-- ==============================================================================
-- 18. SUPPORT TICKETS & MANDAL ISSUE REPORTING SYSTEM
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    user_mobile TEXT,
    user_email TEXT,
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE SET NULL,
    mandal_name TEXT NOT NULL,
    mandal_code TEXT,
    mandal_location TEXT,
    user_role TEXT,
    category TEXT NOT NULL DEFAULT 'technical',
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    screenshot_url TEXT,
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    admin_reply TEXT,
    admin_reply_at TIMESTAMPTZ,
    replied_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_support_tickets_mandal ON public.support_tickets(mandal_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_user ON public.support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON public.support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created ON public.support_tickets(created_at DESC);

-- Enable RLS
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- Helper check if authenticated user is a super admin
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_super_admin = TRUE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE PARALLEL SAFE;

-- RLS Policies for support_tickets
DROP POLICY IF EXISTS "Users can insert support tickets" ON public.support_tickets;
CREATE POLICY "Users can insert support tickets" ON public.support_tickets 
FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Users or super admins can view support tickets" ON public.support_tickets;
CREATE POLICY "Users or super admins can view support tickets" ON public.support_tickets 
FOR SELECT USING (auth.uid() = user_id OR public.is_super_admin());

DROP POLICY IF EXISTS "Users or super admins can update support tickets" ON public.support_tickets;
CREATE POLICY "Users or super admins can update support tickets" ON public.support_tickets 
FOR UPDATE USING (auth.uid() = user_id OR public.is_super_admin());

-- Storage Bucket for Support Attachments
INSERT INTO storage.buckets (id, name, public) VALUES 
    ('support_attachments', 'support_attachments', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public read for support_attachments" ON storage.objects;
CREATE POLICY "Public read for support_attachments" ON storage.objects FOR SELECT USING (bucket_id = 'support_attachments');

DROP POLICY IF EXISTS "Auth upload for support_attachments" ON storage.objects;
CREATE POLICY "Auth upload for support_attachments" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'support_attachments' AND auth.role() = 'authenticated');



