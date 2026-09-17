-- ==============================================================================
-- NAVRATRI UTSAV MANDAL MANAGEMENT ERP - SUPABASE POSTGRESQL SCHEMA
-- Project: Shree Mataji Navratri Utsav Mandal ERP
-- Target: Supabase (PostgreSQL 15+)
-- Features: 33 Tables, Triggers, Functions, RLS, Storage Buckets, Seed Data
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
    registration_number VARCHAR(100) DEFAULT 'MAH/PUNE/2012/F-45892',
    address TEXT NOT NULL DEFAULT 'Mandal Ground, Kothrud, Pune, Maharashtra 411038',
    city VARCHAR(100) DEFAULT 'Pune',
    state VARCHAR(100) DEFAULT 'Maharashtra',
    pincode VARCHAR(20) DEFAULT '411038',
    contact_number VARCHAR(20) DEFAULT '9876543210',
    email VARCHAR(100) DEFAULT 'info@mandal.org',
    website VARCHAR(150),
    festival_year VARCHAR(20) NOT NULL DEFAULT '2026',
    starting_date DATE DEFAULT '2026-09-18',
    ending_date DATE DEFAULT '2026-09-27',
    logo_url TEXT,
    receipt_prefix VARCHAR(10) DEFAULT 'R-',
    receipt_starting_number INT DEFAULT 1,
    receipt_footer_note TEXT DEFAULT 'Thank you for your generous donation. May Maa Durga bless your family.',
    authorized_signatory_name VARCHAR(100) DEFAULT 'Anil Desai (Treasurer)',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 4. ROLES & PERMISSIONS (RBAC)
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
-- 8. EXPENSES & CATEGORIES
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
    supplier VARCHAR(150) NOT NULL DEFAULT 'Mahalaxmi Murti Art',
    supplier_contact VARCHAR(20) DEFAULT '9876543210',
    idol_cost NUMERIC(12, 2) DEFAULT 75000.00,
    booking_date DATE DEFAULT '2026-06-30',
    delivery_date DATE DEFAULT '2026-09-17',
    installation_date DATE DEFAULT '2026-09-17',
    idol_details TEXT DEFAULT '9-feet eco-friendly clay Durga Mata idol with lion and weapons',
    decoration TEXT DEFAULT 'Golden foil backdrop, velvet saree, silver ornaments',
    transportation_mode VARCHAR(100) DEFAULT 'Tempo',
    visarjan_date DATE DEFAULT '2026-09-27',
    visarjan_location VARCHAR(150) DEFAULT 'River Bank, Mula-Mutha Ghat',
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
    visarjan_date DATE NOT NULL DEFAULT '2026-09-27',
    start_time TIME NOT NULL DEFAULT '06:00:00',
    route VARCHAR(250) NOT NULL DEFAULT 'Mandal Ground -> Paud Road -> Alka Talkies -> River Bank',
    vehicle VARCHAR(100) DEFAULT 'Truck (MH-12-AB-1234)',
    driver_name VARCHAR(150) DEFAULT 'Ramesh',
    volunteers_count INT DEFAULT 15,
    police_coordination VARCHAR(150) DEFAULT 'Inspector Kulkarni (Kothrud Police)',
    sound_system VARCHAR(150) DEFAULT 'Sai Sound (Mobile Van)',
    transportation_cost NUMERIC(12, 2) DEFAULT 12000.00,
    other_expenses NUMERIC(12, 2) DEFAULT 8000.00,
    status VARCHAR(50) DEFAULT 'Scheduled',
    checklist JSONB DEFAULT '{"permission": true, "vehicle": true, "driver": true, "volunteers": true, "security": true, "sound": true, "lighting": true, "first_aid": true, "route": true, "water": true, "emergency_contact": true}'::jsonb,
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

-- Function & Trigger to automatically post Cash/Bank transaction when a Donation is made
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


-- Function & Trigger to automatically deduct Cash/Bank balance when an Expense is created
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
-- 24. SEED DATA (MATCHING EXACT DESIGN BOARD IN SCREENSHOT)
-- ==============================================================================

-- 24.1 Default Mandal
INSERT INTO public.mandals (
    id, name, registration_number, address, city, state, pincode,
    contact_number, email, festival_year, starting_date, ending_date,
    receipt_prefix, authorized_signatory_name
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Shree Mataji Navratri Utsav Mandal',
    'MAH/PUNE/2012/F-45892',
    'Pune, Maharashtra',
    'Pune',
    'Maharashtra',
    '411038',
    '9876543210',
    'info@mandal.org',
    '2026',
    '2026-09-18',
    '2026-09-27',
    'R-',
    'Anil Desai'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- 24.2 Roles
INSERT INTO public.roles (role_key, role_name, description) VALUES
    ('admin', 'Admin', 'Full administrative control over all modules and financial records'),
    ('president', 'President', 'Mandal president with executive approval authority'),
    ('secretary', 'Secretary', 'General administration, events, and document management'),
    ('treasurer', 'Treasurer', 'Financial entries, accounts, receipts, and expense approvals'),
    ('committee_member', 'Committee Member', 'Event coordination and member assistance'),
    ('volunteer', 'Volunteer', 'Ground management, crowd control, and event assistance')
ON CONFLICT (role_key) DO NOTHING;

-- 24.3 Members (Matching Design Board Screen 2)
INSERT INTO public.mandal_members (mandal_id, member_code, full_name, role, mobile, status) VALUES
    ('00000000-0000-0000-0000-000000000001', 'MEM-001', 'Rajesh Patel', 'President', '9876543210', 'Active'),
    ('00000000-0000-0000-0000-000000000001', 'MEM-002', 'Sunil Mehta', 'Vice President', '9876543211', 'Active'),
    ('00000000-0000-0000-0000-000000000001', 'MEM-003', 'Pooja Sharma', 'Secretary', '9876543212', 'Active'),
    ('00000000-0000-0000-0000-000000000001', 'MEM-004', 'Anil Desai', 'Treasurer', '9876543213', 'Active'),
    ('00000000-0000-0000-0000-000000000001', 'MEM-005', 'Neha Joshi', 'Committee Member', '9876543214', 'Active'),
    ('00000000-0000-0000-0000-000000000001', 'MEM-006', 'Rohit Kumar', 'Volunteer', '9876543215', 'Active')
ON CONFLICT (member_code) DO NOTHING;

-- 24.4 Bank Accounts (Matching Design Board Screen 5)
INSERT INTO public.bank_accounts (id, mandal_id, bank_name, branch_name, account_holder, account_number, ifsc, current_balance) VALUES
    ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'SBI', 'Main Branch', 'Shree Mataji Navratri Mandal', '1234567890', 'SBIN0001234', 85000.00),
    ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'HDFC', 'Kothrud', 'Shree Mataji Navratri Mandal', '9876543210', 'HDFC0005478', 42000.00),
    ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'ICICI', 'FC Road', 'Shree Mataji Navratri Mandal', '4567890123', 'ICIC0008101', 28000.00)
ON CONFLICT (id) DO NOTHING;

-- 24.5 Expense Categories
INSERT INTO public.expense_categories (name, description) VALUES
    ('Decoration', 'Mandal pandal decoration, flower garland, stage backdrop'),
    ('Sound', 'Sound system, microphones, amplifiers, DJ'),
    ('Lighting', 'Focus lights, LED serials, halogens, generators'),
    ('Stage', 'Wooden platform, carpet, VIP seating, barricades'),
    ('Idol', 'Mataji idol booking, transport, rituals, sthapana'),
    ('Prasad', 'Laddoo, fruits, daily bhog prasad'),
    ('Food', 'Daily volunteer meals, mahaprasad bhandara'),
    ('Advertisement', 'Banners, hoardings, social media, pamphlets'),
    ('Security', 'Bouncers, metal detectors, walkie-talkies'),
    ('Electricity', 'MSEDCL festival connection and diesel fuel'),
    ('Garba', 'Orchestra, traditional singers, sound setup'),
    ('Prize', 'Trophies and gifts for Garba winners'),
    ('Photography', 'Cameraman, video recording, live streaming'),
    ('Transportation', 'Visarjan truck and goods logistics'),
    ('Miscellaneous', 'Incidental office and pooja items')
ON CONFLICT (name) DO NOTHING;

-- 24.6 Vendors (Matching Design Board Screen 9)
INSERT INTO public.vendors (mandal_id, vendor_code, vendor_name, service_type, mobile, contract_amount, paid_amount, status) VALUES
    ('00000000-0000-0000-0000-000000000001', 'V-001', 'Shree Decoration', 'Decoration', '9876543210', 50000.00, 50000.00, 'Paid'),
    ('00000000-0000-0000-0000-000000000001', 'V-002', 'Sai Sound', 'Sound', '9876543211', 35000.00, 35000.00, 'Paid'),
    ('00000000-0000-0000-0000-000000000001', 'V-003', 'Om Light', 'Lighting', '9876543212', 25000.00, 10000.00, 'Pending'),
    ('00000000-0000-0000-0000-000000000001', 'V-004', 'Aarti Caterers', 'Catering', '9876543213', 40000.00, 40000.00, 'Paid'),
    ('00000000-0000-0000-0000-000000000001', 'V-005', 'Print World', 'Printing', '9876543214', 15000.00, 10000.00, 'Partial')
ON CONFLICT (vendor_code) DO NOTHING;

-- 24.7 Donations (Matching Design Board Screen 1 & 3: Total Donation ₹2,45,000)
INSERT INTO public.donations (mandal_id, receipt_number, donation_date, donor_name, mobile, address, amount, payment_mode, purpose, collector_name) VALUES
    ('00000000-0000-0000-0000-000000000001', 'R-001', '2026-09-16', 'ABC Traders', '9876543210', 'Pune', 5000.00, 'UPI', 'Festival Donation', 'Rahul Desai'),
    ('00000000-0000-0000-0000-000000000001', 'R-002', '2026-09-16', 'XYZ Enterprise', '9876543211', 'Pune', 2500.00, 'Cash', 'Aarti Donation', 'Anil Desai'),
    ('00000000-0000-0000-0000-000000000001', 'R-003', '2026-09-15', 'Rameshwar Builders', '9876543212', 'Kothrud', 50000.00, 'Bank Transfer', 'Main Sponsor Donation', 'Rajesh Patel'),
    ('00000000-0000-0000-0000-000000000001', 'R-004', '2026-09-15', 'Kalyani Jewellers', '9876543213', 'FC Road', 75000.00, 'Bank Transfer', 'Gold Sponsor', 'Rajesh Patel'),
    ('00000000-0000-0000-0000-000000000001', 'R-005', '2026-09-16', 'Amit Shah', '9876543210', 'Pune, Maharashtra', 5000.00, 'Cash', 'Festival Donation', 'Rahul Desai'),
    ('00000000-0000-0000-0000-000000000001', 'R-006', '2026-09-14', 'Community Wellwishers', '9876543215', 'Pune', 107500.00, 'Cheque', 'General Mahaprasad Fund', 'Anil Desai')
ON CONFLICT (receipt_number) DO NOTHING;

-- 24.8 Expenses (Matching Design Board Screen 1 & 4: Total Expense ₹1,18,500)
INSERT INTO public.expenses (mandal_id, expense_number, expense_date, category_id, description, amount, payment_mode, paid_by) VALUES
    ('00000000-0000-0000-0000-000000000001', 'E-001', '2026-09-10', (SELECT id FROM public.expense_categories WHERE name='Decoration' LIMIT 1), 'Stage & Pandal Advance', 25000.00, 'Bank Transfer', 'Treasurer'),
    ('00000000-0000-0000-0000-000000000001', 'E-002', '2026-09-12', (SELECT id FROM public.expense_categories WHERE name='Sound' LIMIT 1), 'Sound System Rental Deposit', 20000.00, 'Bank Transfer', 'Treasurer'),
    ('00000000-0000-0000-0000-000000000001', 'E-003', '2026-09-14', (SELECT id FROM public.expense_categories WHERE name='Lighting' LIMIT 1), 'LED Lights & Serial Decoration', 15000.00, 'UPI', 'Secretary'),
    ('00000000-0000-0000-0000-000000000001', 'E-004', '2026-09-15', (SELECT id FROM public.expense_categories WHERE name='Advertisement' LIMIT 1), 'Flex Banners & Street Posters', 8500.00, 'Cash', 'Secretary'),
    ('00000000-0000-0000-0000-000000000001', 'E-012', '2026-09-16', (SELECT id FROM public.expense_categories WHERE name='Decoration' LIMIT 1), 'Stage Decoration & Backdrop', 25000.00, 'Cash', 'Treasurer'),
    ('00000000-0000-0000-0000-000000000001', 'E-013', '2026-09-16', (SELECT id FROM public.expense_categories WHERE name='Prasad' LIMIT 1), 'Daily Laddoo & Dry Fruits Bhog', 12000.00, 'Cash', 'Treasurer'),
    ('00000000-0000-0000-0000-000000000001', 'E-014', '2026-09-16', (SELECT id FROM public.expense_categories WHERE name='Security' LIMIT 1), 'Walkie Talkies & Barricade locks', 13000.00, 'UPI', 'Treasurer')
ON CONFLICT (expense_number) DO NOTHING;

-- 24.9 Events (Matching Design Board Screen 6)
INSERT INTO public.events (mandal_id, event_name, event_date, start_time, end_time, venue, status) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Ghatasthapana', '2026-09-18', '07:00:00', '11:00:00', 'Mandal Ground', 'Upcoming'),
    ('00000000-0000-0000-0000-000000000001', 'Garba Night', '2026-09-19', '19:30:00', '23:30:00', 'Mandal Ground', 'Upcoming'),
    ('00000000-0000-0000-0000-000000000001', 'Cultural Program', '2026-09-20', '18:00:00', '22:00:00', 'Mandal Ground', 'Upcoming'),
    ('00000000-0000-0000-0000-000000000001', 'Dandiya Night', '2026-09-21', '20:00:00', '00:00:00', 'Mandal Ground', 'Upcoming'),
    ('00000000-0000-0000-0000-000000000001', 'Bhajan Sandhya', '2026-09-22', '18:30:00', '21:30:00', 'Mandal Ground', 'Upcoming'),
    ('00000000-0000-0000-0000-000000000001', 'Ladies Special', '2026-09-23', '17:00:00', '21:00:00', 'Mandal Ground', 'Upcoming'),
    ('00000000-0000-0000-0000-000000000001', 'Kids Program', '2026-09-24', '16:30:00', '19:30:00', 'Mandal Ground', 'Upcoming'),
    ('00000000-0000-0000-0000-000000000001', 'Durga Ashtami', '2026-09-25', '06:00:00', '14:00:00', 'Mandal Ground', 'Upcoming'),
    ('00000000-0000-0000-0000-000000000001', 'Maha Aarti', '2026-09-26', '20:00:00', '22:30:00', 'Mandal Ground', 'Upcoming'),
    ('00000000-0000-0000-0000-000000000001', 'Visarjan', '2026-09-27', '06:00:00', '16:00:00', 'River Bank', 'Upcoming')
ON CONFLICT DO NOTHING;

-- 24.10 Garba Participants (Matching Design Board Screen 7)
INSERT INTO public.event_participants (mandal_id, registration_number, name, mobile, age, gender, amount, status) VALUES
    ('00000000-0000-0000-0000-000000000001', 'REG-101', 'Riya Patel', '9876543210', 22, 'F', 200.00, 'Active'),
    ('00000000-0000-0000-0000-000000000001', 'REG-102', 'Amit Shah', '9876543211', 25, 'M', 200.00, 'Active'),
    ('00000000-0000-0000-0000-000000000001', 'REG-103', 'Pooja Mehta', '9876543212', 20, 'F', 200.00, 'Active'),
    ('00000000-0000-0000-0000-000000000001', 'REG-104', 'Rahul Desai', '9876543213', 28, 'M', 200.00, 'Active'),
    ('00000000-0000-0000-0000-000000000001', 'REG-105', 'Sneha Joshi', '9876543214', 24, 'F', 200.00, 'Active'),
    ('00000000-0000-0000-0000-000000000001', 'REG-106', 'Karan Gupta', '9876543215', 30, 'M', 200.00, 'Active')
ON CONFLICT (registration_number) DO NOTHING;

-- 24.11 Volunteers (Matching Design Board Screen 8)
INSERT INTO public.volunteers (mandal_id, volunteer_code, name, mobile, department, status) VALUES
    ('00000000-0000-0000-0000-000000000001', 'VOL-01', 'Vijay Patil', '9876543210', 'Security', 'Active'),
    ('00000000-0000-0000-0000-000000000001', 'VOL-02', 'Sneha More', '9876543211', 'Medical', 'Active'),
    ('00000000-0000-0000-0000-000000000001', 'VOL-03', 'Rohit Sharma', '9876543212', 'Decoration', 'Active'),
    ('00000000-0000-0000-0000-000000000001', 'VOL-04', 'Pooja Nair', '9876543213', 'Food', 'Active'),
    ('00000000-0000-0000-0000-000000000001', 'VOL-05', 'Sagar Kale', '9876543214', 'Parking', 'Active'),
    ('00000000-0000-0000-0000-000000000001', 'VOL-06', 'Anita Desai', '9876543215', 'Crowd Management', 'Active')
ON CONFLICT (volunteer_code) DO NOTHING;

-- 24.12 Inventory (Matching Design Board Screen 10)
INSERT INTO public.inventory_items (mandal_id, item_name, category, opening_stock, current_stock, unit, status) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Chairs', 'Furniture', 100, 100, 'Nos', 'In Stock'),
    ('00000000-0000-0000-0000-000000000001', 'Speakers', 'Sound', 8, 8, 'Nos', 'In Stock'),
    ('00000000-0000-0000-0000-000000000001', 'Lights', 'Lighting', 20, 20, 'Nos', 'In Stock'),
    ('00000000-0000-0000-0000-000000000001', 'Extension Board', 'Electrical', 15, 15, 'Nos', 'In Stock'),
    ('00000000-0000-0000-0000-000000000001', 'Garlands', 'Decoration', 50, 50, 'Nos', 'In Stock')
ON CONFLICT DO NOTHING;

-- 24.13 Permissions & Statutory Documents (Matching Design Board Screen 11)
INSERT INTO public.documents (mandal_id, document_name, issue_date, expiry_date, status) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Police Permission', '2026-09-01', '2026-09-30', 'Valid'),
    ('00000000-0000-0000-0000-000000000001', 'Municipal Permission', '2026-09-05', '2026-10-05', 'Valid'),
    ('00000000-0000-0000-0000-000000000001', 'Sound Permission', '2026-09-10', '2026-10-10', 'Valid'),
    ('00000000-0000-0000-0000-000000000001', 'Fire Safety', '2026-09-12', '2026-10-12', 'Valid'),
    ('00000000-0000-0000-0000-000000000001', 'Insurance', '2026-09-15', '2026-10-15', 'Valid')
ON CONFLICT DO NOTHING;

-- 24.14 Sponsors (Matching Design Board Screen 12)
INSERT INTO public.sponsors (mandal_id, sponsor_name, package_name, amount, paid_amount, payment_status) VALUES
    ('00000000-0000-0000-0000-000000000001', 'ABC Pvt. Ltd.', 'Main Sponsor', 100000.00, 100000.00, 'Paid'),
    ('00000000-0000-0000-0000-000000000001', 'XYZ Group', 'Gold Sponsor', 50000.00, 50000.00, 'Paid'),
    ('00000000-0000-0000-0000-000000000001', 'Sunrise Co.', 'Silver Sponsor', 25000.00, 10000.00, 'Pending'),
    ('00000000-0000-0000-0000-000000000001', 'Global Media', 'Banner Sponsor', 15000.00, 15000.00, 'Paid'),
    ('00000000-0000-0000-0000-000000000001', 'Shree Traders', 'Event Sponsor', 10000.00, 10000.00, 'Paid')
ON CONFLICT DO NOTHING;

-- 24.15 Food & Prasad (Matching Design Board Screen 13)
INSERT INTO public.food_prasad (mandal_id, meal_date, menu, estimated_people, actual_people, cost) VALUES
    ('00000000-0000-0000-0000-000000000001', '2026-09-18', 'Khichdi', 500, 480, 8000.00),
    ('00000000-0000-0000-0000-000000000001', '2026-09-19', 'Puri Sabzi', 500, 520, 10000.00),
    ('00000000-0000-0000-0000-000000000001', '2026-09-20', 'Farsan', 500, 510, 9500.00),
    ('00000000-0000-0000-0000-000000000001', '2026-09-21', 'Khichdi', 500, 495, 8500.00)
ON CONFLICT DO NOTHING;

-- 24.16 Security Emergency Contacts (Matching Design Board Screen 14)
INSERT INTO public.security_contacts (mandal_id, title, category, contact_number) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Police Control Room', 'Police', '100'),
    ('00000000-0000-0000-0000-000000000001', 'Fire Brigade Emergency', 'Fire Brigade', '101'),
    ('00000000-0000-0000-0000-000000000001', 'Ambulance Emergency', 'Ambulance', '108'),
    ('00000000-0000-0000-0000-000000000001', 'City Civil Hospital', 'Hospital', '020-123456')
ON CONFLICT DO NOTHING;

-- 24.17 Aarti Schedule (Matching Design Board Screen 16)
INSERT INTO public.aarti_schedule (mandal_id, aarti_name, aarti_date, aarti_time, lead_person) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Morning Aarti', '2026-09-18', '06:30:00', 'Pandit Sharma'),
    ('00000000-0000-0000-0000-000000000001', 'Evening Aarti', '2026-09-18', '19:30:00', 'Mahesh Bhatt'),
    ('00000000-0000-0000-0000-000000000001', 'Maha Aarti', '2026-09-22', '20:00:00', 'Ramdas Ji')
ON CONFLICT DO NOTHING;

-- 24.18 Mataji Idol Management (Matching Design Board Screen 17)
INSERT INTO public.idol_management (
    mandal_id, supplier, idol_cost, booking_date, delivery_date,
    installation_date, visarjan_date, transportation_mode, visarjan_location, photo_url
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Mahalaxmi Murti Art',
    75000.00,
    '2026-06-30',
    '2026-09-17',
    '2026-09-17',
    '2026-09-27',
    'Tempo',
    'River Bank',
    'https://images.unsplash.com/photo-1601614749377-622f67ec1656?w=600&q=80'
) ON CONFLICT DO NOTHING;

-- 24.19 Visarjan (Matching Design Board Screen 18)
INSERT INTO public.visarjan (
    mandal_id, visarjan_date, start_time, route, vehicle, driver_name, volunteers_count, status
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    '2026-09-27',
    '06:00:00',
    'River Bank',
    'Truck',
    'Ramesh',
    15,
    'Scheduled'
) ON CONFLICT DO NOTHING;

-- ==============================================================================
-- 25. DATABASE VIEWS FOR INSTANT REPORTING & DASHBOARD
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
-- END OF SCHEMA
-- ==============================================================================
