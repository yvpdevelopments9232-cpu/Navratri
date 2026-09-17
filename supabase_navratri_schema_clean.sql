-- ==============================================================================
-- NAVRATRI UTSAV MANDAL MANAGEMENT ERP - CLEAN DDL SCHEMA (NO SEED DATA)
-- Target Database: Supabase PostgreSQL (15+)
-- Features: 33 Tables, Auth Trigger, Functions, Ledger Triggers, Storage, RLS, Views
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. ENUMS & CUSTOM TYPES
DO $$ BEGIN
    CREATE TYPE user_role_type AS ENUM ('admin', 'president', 'secretary', 'treasurer', 'committee_member', 'volunteer');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE payment_mode_type AS ENUM ('Cash', 'UPI', 'Bank Transfer', 'Cheque', 'Other');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE status_type AS ENUM ('Active', 'Inactive', 'Pending', 'Approved', 'Rejected', 'Completed', 'Cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ==============================================================================
-- 3. CORE MANDAL PROFILE & SETTINGS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.mandals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL DEFAULT 'Shree Mataji Navratri Utsav Mandal',
    registration_number VARCHAR(100),
    address TEXT NOT NULL,
    city VARCHAR(100) DEFAULT 'Pune',
    state VARCHAR(100) DEFAULT 'Maharashtra',
    pincode VARCHAR(20),
    contact_number VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(150),
    festival_year VARCHAR(20) NOT NULL DEFAULT '2026',
    starting_date DATE,
    ending_date DATE,
    logo_url TEXT,
    receipt_prefix VARCHAR(10) DEFAULT 'R-',
    receipt_starting_number INT DEFAULT 1,
    receipt_footer_note TEXT DEFAULT 'Thank you for your generous contribution. May Goddess Durga bless your family.',
    authorized_signatory_name VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 4. ROLES, PERMISSIONS & USER PROFILES (SUPABASE AUTH LINKED)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_key VARCHAR(50) UNIQUE NOT NULL,
    role_name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL, -- 'view', 'add', 'edit', 'delete', 'approve', 'export', 'print'
    description TEXT,
    UNIQUE(module, action)
);

CREATE TABLE IF NOT EXISTS public.role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id UUID REFERENCES public.roles(id) ON DELETE CASCADE,
    permission_id UUID REFERENCES public.permissions(id) ON DELETE CASCADE,
    UNIQUE(role_id, permission_id)
);

-- Profiles table linked to Supabase auth.users
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE SET NULL,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE,
    mobile VARCHAR(20),
    role_key VARCHAR(50) DEFAULT 'volunteer' REFERENCES public.roles(role_key),
    avatar_url TEXT,
    status VARCHAR(20) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Automatic Profile Creation Trigger on Supabase Auth Sign Up
CREATE OR REPLACE FUNCTION public.fn_handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role_key, status)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role_key', 'volunteer'),
        'Active'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.fn_handle_new_user();

-- ==============================================================================
-- 5. MANDAL MEMBERS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.mandal_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    member_code VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    mobile VARCHAR(20) NOT NULL,
    email VARCHAR(150),
    address TEXT,
    role VARCHAR(100) NOT NULL DEFAULT 'Committee Member',
    joining_date DATE DEFAULT CURRENT_DATE,
    emergency_contact VARCHAR(20),
    id_proof_type VARCHAR(50) DEFAULT 'Aadhaar',
    id_proof_number VARCHAR(100),
    photo_url TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 6. BANK & CASH ACCOUNTS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.bank_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    bank_name VARCHAR(100) NOT NULL,
    branch_name VARCHAR(100) NOT NULL,
    account_holder VARCHAR(150) NOT NULL,
    account_number VARCHAR(50) NOT NULL,
    ifsc VARCHAR(20) NOT NULL,
    account_type VARCHAR(50) DEFAULT 'Savings',
    opening_balance NUMERIC(15, 2) DEFAULT 0.00,
    current_balance NUMERIC(15, 2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.bank_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    bank_account_id UUID REFERENCES public.bank_accounts(id) ON DELETE RESTRICT,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    transaction_type VARCHAR(20) NOT NULL, -- 'Deposit', 'Withdrawal'
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    reference_number VARCHAR(100),
    description TEXT,
    related_module VARCHAR(50),
    related_id UUID,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.cash_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    transaction_type VARCHAR(30) NOT NULL, -- 'Collection', 'Expense', 'DepositToBank', 'WithdrawalFromBank'
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    description TEXT,
    related_module VARCHAR(50),
    related_id UUID,
    handled_by VARCHAR(100),
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 7. DONATIONS & RECEIPTS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    receipt_number VARCHAR(50) UNIQUE NOT NULL,
    donation_date DATE NOT NULL DEFAULT CURRENT_DATE,
    donor_name VARCHAR(150) NOT NULL,
    mobile VARCHAR(20),
    email VARCHAR(150),
    address TEXT,
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    payment_mode VARCHAR(30) NOT NULL DEFAULT 'Cash',
    bank_account_id UUID REFERENCES public.bank_accounts(id) ON DELETE SET NULL,
    transaction_reference VARCHAR(100),
    purpose VARCHAR(100) DEFAULT 'Festival Donation',
    collector_name VARCHAR(100),
    notes TEXT,
    attachment_url TEXT,
    is_cancelled BOOLEAN DEFAULT FALSE,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.donation_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    donation_id UUID REFERENCES public.donations(id) ON DELETE CASCADE,
    receipt_number VARCHAR(50) NOT NULL,
    receipt_pdf_url TEXT,
    qr_code_data TEXT,
    generated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 8. EXPENSES & VENDORS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.expense_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.vendors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    vendor_code VARCHAR(50) UNIQUE NOT NULL,
    vendor_name VARCHAR(150) NOT NULL,
    business_name VARCHAR(200),
    service_type VARCHAR(100) NOT NULL,
    mobile VARCHAR(20) NOT NULL,
    email VARCHAR(150),
    address TEXT,
    gst_number VARCHAR(30),
    bank_details TEXT,
    contract_amount NUMERIC(15, 2) DEFAULT 0.00,
    paid_amount NUMERIC(15, 2) DEFAULT 0.00,
    remaining_amount NUMERIC(15, 2) GENERATED ALWAYS AS (contract_amount - paid_amount) STORED,
    status VARCHAR(20) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    expense_number VARCHAR(50) UNIQUE NOT NULL,
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    category_id UUID REFERENCES public.expense_categories(id) ON DELETE RESTRICT,
    vendor_id UUID REFERENCES public.vendors(id) ON DELETE SET NULL,
    description TEXT NOT NULL,
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    payment_mode VARCHAR(30) NOT NULL DEFAULT 'Cash',
    bank_account_id UUID REFERENCES public.bank_accounts(id) ON DELETE SET NULL,
    paid_by VARCHAR(100),
    bill_url TEXT,
    notes TEXT,
    status VARCHAR(20) DEFAULT 'Paid',
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.vendor_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID REFERENCES public.vendors(id) ON DELETE CASCADE,
    expense_id UUID REFERENCES public.expenses(id) ON DELETE SET NULL,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    payment_mode VARCHAR(30) NOT NULL DEFAULT 'Cash',
    reference_number VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 9. EVENTS & GARBA REGISTRATIONS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    event_name VARCHAR(150) NOT NULL,
    event_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    venue VARCHAR(200) NOT NULL DEFAULT 'Mandal Ground',
    organizer VARCHAR(150),
    chief_guest VARCHAR(150),
    expected_crowd INT DEFAULT 500,
    description TEXT,
    poster_url TEXT,
    status VARCHAR(20) DEFAULT 'Upcoming',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.event_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    event_id UUID REFERENCES public.events(id) ON DELETE SET NULL,
    registration_number VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    photo_url TEXT,
    mobile VARCHAR(20) NOT NULL,
    age INT,
    gender VARCHAR(10),
    registration_type VARCHAR(50) DEFAULT 'Individual',
    amount NUMERIC(10, 2) DEFAULT 200.00,
    payment_mode VARCHAR(30) DEFAULT 'UPI',
    registration_date DATE DEFAULT CURRENT_DATE,
    qr_code TEXT,
    status VARCHAR(20) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 10. VOLUNTEERS & DUTIES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.volunteers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    volunteer_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    photo_url TEXT,
    mobile VARCHAR(20) NOT NULL,
    address TEXT,
    emergency_contact VARCHAR(20),
    department VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.volunteer_duties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    volunteer_id UUID REFERENCES public.volunteers(id) ON DELETE CASCADE,
    duty_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    location VARCHAR(150) NOT NULL,
    department VARCHAR(100) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'Scheduled',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.volunteer_attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    volunteer_id UUID REFERENCES public.volunteers(id) ON DELETE CASCADE,
    duty_id UUID REFERENCES public.volunteer_duties(id) ON DELETE SET NULL,
    attendance_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'Present',
    check_in_time TIME,
    check_out_time TIME,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 11. INVENTORY & MATERIALS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    item_name VARCHAR(150) NOT NULL,
    category VARCHAR(100) NOT NULL,
    opening_stock INT DEFAULT 0,
    current_stock INT DEFAULT 0,
    unit VARCHAR(30) DEFAULT 'Nos',
    purchase_price NUMERIC(10, 2) DEFAULT 0.00,
    supplier VARCHAR(150),
    storage_location VARCHAR(150) DEFAULT 'Mandal Godown',
    min_stock INT DEFAULT 5,
    status VARCHAR(20) DEFAULT 'In Stock',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.inventory_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID REFERENCES public.inventory_items(id) ON DELETE CASCADE,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    transaction_type VARCHAR(30) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    reason TEXT,
    authorized_by VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 12. PERMISSIONS & STATUTORY DOCUMENTS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    document_name VARCHAR(150) NOT NULL,
    document_number VARCHAR(100),
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    responsible_person VARCHAR(150),
    file_url TEXT,
    status VARCHAR(20) DEFAULT 'Valid',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 13. SPONSORSHIPS & ADVERTISEMENT
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.sponsors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    sponsor_name VARCHAR(150) NOT NULL,
    company_name VARCHAR(200),
    contact_person VARCHAR(150),
    mobile VARCHAR(20),
    email VARCHAR(150),
    package_name VARCHAR(100) NOT NULL,
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    paid_amount NUMERIC(15, 2) DEFAULT 0.00,
    remaining_amount NUMERIC(15, 2) GENERATED ALWAYS AS (amount - paid_amount) STORED,
    payment_status VARCHAR(20) DEFAULT 'Paid',
    logo_url TEXT,
    ad_location VARCHAR(200),
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.sponsor_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sponsor_id UUID REFERENCES public.sponsors(id) ON DELETE CASCADE,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    payment_mode VARCHAR(30) DEFAULT 'Bank Transfer',
    receipt_number VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 14. FOOD & PRASAD MANAGEMENT
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.food_prasad (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    meal_date DATE NOT NULL,
    menu VARCHAR(200) NOT NULL,
    estimated_people INT NOT NULL,
    actual_people INT,
    supplier VARCHAR(150) DEFAULT 'Aarti Caterers',
    cost NUMERIC(12, 2) NOT NULL,
    distribution_status VARCHAR(50) DEFAULT 'Completed',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 15. SECURITY & EMERGENCY CONTACTS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.security_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    contact_number VARCHAR(30) NOT NULL,
    alternate_number VARCHAR(30),
    address TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 16. GALLERY & MEDIA
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.gallery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    media_type VARCHAR(20) NOT NULL DEFAULT 'Photo',
    category VARCHAR(50) DEFAULT 'All Events',
    title VARCHAR(150) NOT NULL,
    file_url TEXT NOT NULL,
    thumbnail_url TEXT,
    event_id UUID REFERENCES public.events(id) ON DELETE SET NULL,
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 17. AARTI SCHEDULE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.aarti_schedule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    aarti_name VARCHAR(100) NOT NULL,
    aarti_date DATE NOT NULL,
    aarti_time TIME NOT NULL,
    lead_person VARCHAR(150) NOT NULL,
    prasad VARCHAR(150) DEFAULT 'Laddoo / Peda',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 18. MATAJI / IDOL MANAGEMENT
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.idol_management (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    supplier VARCHAR(150) NOT NULL,
    supplier_contact VARCHAR(20),
    idol_cost NUMERIC(12, 2) DEFAULT 0.00,
    booking_date DATE,
    delivery_date DATE,
    installation_date DATE,
    idol_details TEXT,
    decoration TEXT,
    transportation_mode VARCHAR(100),
    visarjan_date DATE,
    visarjan_location VARCHAR(150),
    photo_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 19. VISARJAN MANAGEMENT
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.visarjan (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    visarjan_date DATE NOT NULL,
    start_time TIME NOT NULL,
    route VARCHAR(250) NOT NULL,
    vehicle VARCHAR(100),
    driver_name VARCHAR(150),
    volunteers_count INT DEFAULT 0,
    police_coordination VARCHAR(150),
    sound_system VARCHAR(150),
    transportation_cost NUMERIC(12, 2) DEFAULT 0.00,
    other_expenses NUMERIC(12, 2) DEFAULT 0.00,
    status VARCHAR(50) DEFAULT 'Scheduled',
    checklist JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 20. NOTIFICATIONS & AUDIT LOGS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(50) DEFAULT 'General',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mandal_id UUID REFERENCES public.mandals(id) ON DELETE CASCADE,
    user_id UUID,
    user_name VARCHAR(150) DEFAULT 'Admin',
    action VARCHAR(50) NOT NULL,
    module VARCHAR(50) NOT NULL,
    record_id VARCHAR(100),
    old_value JSONB,
    new_value JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 21. AUTOMATED LEDGER & BALANCE TRIGGERS
-- ==============================================================================

-- Trigger to automatically post Cash/Bank transaction when a Donation is made
CREATE OR REPLACE FUNCTION fn_process_donation_ledger()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.payment_mode = 'Cash' THEN
        INSERT INTO public.cash_transactions (
            mandal_id, transaction_date, transaction_type, amount, description, related_module, related_id, handled_by
        ) VALUES (
            NEW.mandal_id, NEW.donation_date, 'Collection', NEW.amount, 
            'Donation from ' || NEW.donor_name || ' (Receipt #' || NEW.receipt_number || ')',
            'Donation', NEW.id, NEW.collector_name
        );
    ELSIF NEW.payment_mode IN ('UPI', 'Bank Transfer', 'Cheque') THEN
        IF NEW.bank_account_id IS NOT NULL THEN
            INSERT INTO public.bank_transactions (
                mandal_id, bank_account_id, transaction_date, transaction_type, amount,
                reference_number, description, related_module, related_id
            ) VALUES (
                NEW.mandal_id, NEW.bank_account_id, NEW.donation_date, 'Deposit', NEW.amount,
                NEW.transaction_reference,
                'Donation (' || NEW.payment_mode || ') from ' || NEW.donor_name || ' (Receipt #' || NEW.receipt_number || ')',
                'Donation', NEW.id
            );
            UPDATE public.bank_accounts
            SET current_balance = current_balance + NEW.amount,
                updated_at = NOW()
            WHERE id = NEW.bank_account_id;
        END IF;
    END IF;

    INSERT INTO public.audit_logs (mandal_id, action, module, record_id, new_value)
    VALUES (NEW.mandal_id, 'Add', 'Donations', NEW.receipt_number, row_to_json(NEW));

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_donation_ledger ON public.donations;
CREATE TRIGGER trg_donation_ledger
AFTER INSERT ON public.donations
FOR EACH ROW
EXECUTE FUNCTION fn_process_donation_ledger();


-- Trigger to automatically deduct Cash/Bank balance when an Expense is created
CREATE OR REPLACE FUNCTION fn_process_expense_ledger()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.payment_mode = 'Cash' THEN
        INSERT INTO public.cash_transactions (
            mandal_id, transaction_date, transaction_type, amount, description, related_module, related_id, handled_by
        ) VALUES (
            NEW.mandal_id, NEW.expense_date, 'Expense', NEW.amount,
            'Expense: ' || NEW.description || ' (#' || NEW.expense_number || ')',
            'Expense', NEW.id, NEW.paid_by
        );
    ELSIF NEW.payment_mode IN ('UPI', 'Bank Transfer', 'Cheque') THEN
        IF NEW.bank_account_id IS NOT NULL THEN
            INSERT INTO public.bank_transactions (
                mandal_id, bank_account_id, transaction_date, transaction_type, amount,
                reference_number, description, related_module, related_id
            ) VALUES (
                NEW.mandal_id, NEW.bank_account_id, NEW.expense_date, 'Withdrawal', NEW.amount,
                NEW.expense_number,
                'Expense (' || NEW.payment_mode || '): ' || NEW.description,
                'Expense', NEW.id
            );
            UPDATE public.bank_accounts
            SET current_balance = current_balance - NEW.amount,
                updated_at = NOW()
            WHERE id = NEW.bank_account_id;
        END IF;
    END IF;

    IF NEW.vendor_id IS NOT NULL THEN
        UPDATE public.vendors
        SET paid_amount = paid_amount + NEW.amount,
            updated_at = NOW()
        WHERE id = NEW.vendor_id;
    END IF;

    INSERT INTO public.audit_logs (mandal_id, action, module, record_id, new_value)
    VALUES (NEW.mandal_id, 'Add', 'Expenses', NEW.expense_number, row_to_json(NEW));

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_expense_ledger ON public.expenses;
CREATE TRIGGER trg_expense_ledger
AFTER INSERT ON public.expenses
FOR EACH ROW
EXECUTE FUNCTION fn_process_expense_ledger();


-- Trigger to recalculate inventory current_stock on inventory transactions
CREATE OR REPLACE FUNCTION fn_process_inventory_transaction()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.transaction_type = 'Purchase' OR NEW.transaction_type = 'Return' THEN
        UPDATE public.inventory_items
        SET current_stock = current_stock + NEW.quantity,
            updated_at = NOW()
        WHERE id = NEW.item_id;
    ELSIF NEW.transaction_type = 'Issue' OR NEW.transaction_type = 'Damaged' THEN
        UPDATE public.inventory_items
        SET current_stock = current_stock - NEW.quantity,
            updated_at = NOW()
        WHERE id = NEW.item_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_inventory_transaction ON public.inventory_transactions;
CREATE TRIGGER trg_inventory_transaction
AFTER INSERT ON public.inventory_transactions
FOR EACH ROW
EXECUTE FUNCTION fn_process_inventory_transaction();

-- ==============================================================================
-- 22. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE public.mandals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mandal_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bank_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donation_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteer_duties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteer_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sponsors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sponsor_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_prasad ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gallery ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aarti_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.idol_management ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visarjan ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
    tbl text;
BEGIN
    FOR tbl IN 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "Public & Auth access for %I" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "Public & Auth access for %I" ON public.%I FOR ALL USING (true) WITH CHECK (true)', tbl, tbl);
    END LOOP;
END $$;

-- ==============================================================================
-- 23. SUPABASE STORAGE BUCKETS SETUP
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public) VALUES 
    ('mandal-logos', 'mandal-logos', true),
    ('member-photos', 'member-photos', true),
    ('donation-documents', 'donation-documents', true),
    ('expense-bills', 'expense-bills', true),
    ('vendor-documents', 'vendor-documents', true),
    ('sponsor-logos', 'sponsor-logos', true),
    ('event-posters', 'event-posters', true),
    ('gallery', 'gallery', true),
    ('festival-documents', 'festival-documents', true),
    ('idol-images', 'idol-images', true),
    ('reports', 'reports', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public Read Storage Access" ON storage.objects;
CREATE POLICY "Public Read Storage Access" ON storage.objects FOR SELECT USING (bucket_id IN (
    'mandal-logos', 'member-photos', 'donation-documents', 'expense-bills',
    'vendor-documents', 'sponsor-logos', 'event-posters', 'gallery',
    'festival-documents', 'idol-images', 'reports'
));

DROP POLICY IF EXISTS "Allow Upload to Buckets" ON storage.objects;
CREATE POLICY "Allow Upload to Buckets" ON storage.objects FOR INSERT WITH CHECK (bucket_id IN (
    'mandal-logos', 'member-photos', 'donation-documents', 'expense-bills',
    'vendor-documents', 'sponsor-logos', 'event-posters', 'gallery',
    'festival-documents', 'idol-images', 'reports'
));

DROP POLICY IF EXISTS "Allow Update and Delete" ON storage.objects;
CREATE POLICY "Allow Update and Delete" ON storage.objects FOR UPDATE USING (true) WITH CHECK (true);

-- ==============================================================================
-- 24. DATABASE VIEWS FOR INSTANT REPORTING & DASHBOARD
-- ==============================================================================
CREATE OR REPLACE VIEW public.vw_dashboard_summary AS
SELECT
    (SELECT COALESCE(SUM(amount), 0) FROM public.donations WHERE is_cancelled = false) AS total_donation,
    (SELECT COALESCE(SUM(amount), 0) FROM public.expenses) AS total_expense,
    (SELECT (COALESCE(SUM(amount), 0) - (SELECT COALESCE(SUM(amount), 0) FROM public.expenses)) FROM public.donations WHERE is_cancelled = false) AS current_balance,
    (SELECT COUNT(*) FROM public.mandal_members WHERE status = 'Active') AS total_members,
    (SELECT COUNT(*) FROM public.volunteers WHERE status = 'Active') AS total_volunteers,
    (SELECT COUNT(*) FROM public.events WHERE status = 'Upcoming') AS upcoming_events,
    (SELECT COALESCE(SUM(amount), 0) FROM public.donations WHERE donation_date = CURRENT_DATE AND is_cancelled = false) AS today_collection,
    (SELECT COALESCE(SUM(amount), 0) FROM public.expenses WHERE expense_date = CURRENT_DATE) AS today_expenses,
    (SELECT COALESCE(SUM(current_balance), 0) FROM public.bank_accounts) AS total_bank_balance;

-- ==============================================================================
-- END OF CLEAN DDL SCHEMA
-- ==============================================================================
