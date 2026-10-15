-- ====================================================================
-- SAAN KOT - Multi-Tenant Restaurant POS & Kitchen Display Schema
-- Migration: 001_saan_kot_schema.sql
-- Target: PostgreSQL 15+ / Supabase
-- Features: Multi-Tenancy, Branch-Level Scoping, Row-Level Security (RLS),
--           Audit Logs, Double-Entry Khata Ledger, Recipe BOM & Inventory
-- ====================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ====================================================================
-- 1. TENANTS (Multi-Tenant Root)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    vat_number VARCHAR(50),
    phone VARCHAR(30),
    currency VARCHAR(10) DEFAULT 'NPR',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 2. BRANCHES (Locations per Tenant)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255),
    phone VARCHAR(30),
    is_main BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 3. STAFF PROFILES & RBAC
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.staff_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
    user_id UUID, -- References auth.users(id) if Supabase Auth is enabled
    full_name VARCHAR(150) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'waiter', -- admin, cashier, kitchen, waiter
    pin_hash VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 4. DINING TABLES & CUSTOM TABS
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.dining_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL, -- e.g. T1, T2, Fancy wala, Masu wala, Pack
    is_occupied BOOLEAN DEFAULT FALSE,
    current_order_id UUID,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 5. MENU CATEGORIES & ITEMS
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.menu_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL, -- Coffee, Cold Beverages, Hookah, Momo & Noodles, etc.
    display_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.menu_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.menu_categories(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    price DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    code VARCHAR(50),
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 6. ORDERS & LINE ITEMS
-- ====================================================================
CREATE TYPE order_status_enum AS ENUM ('pending', 'completed', 'cancelled');
CREATE TYPE payment_method_enum AS ENUM ('cash', 'fonepay', 'esewa', 'customer_credit');

CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(50) NOT NULL, -- e.g. ORD-13229
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    table_id UUID REFERENCES public.dining_tables(id) ON DELETE SET NULL,
    table_name VARCHAR(100) NOT NULL,
    staff_name VARCHAR(150) NOT NULL DEFAULT 'Addy',
    status order_status_enum NOT NULL DEFAULT 'pending',
    subtotal DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    discount_type VARCHAR(50) DEFAULT 'none',
    payable_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    payment_method payment_method_enum,
    customer_id UUID,
    customer_name VARCHAR(150),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    menu_item_id UUID NOT NULL REFERENCES public.menu_items(id),
    item_name VARCHAR(200) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(12, 2) NOT NULL,
    total_price DECIMAL(12, 2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 7. KITCHEN ORDER TICKETS (KOT)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.kots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    kot_number VARCHAR(50) NOT NULL, -- e.g. KOT #1042
    table_name VARCHAR(100) NOT NULL,
    server_name VARCHAR(150) NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.kot_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kot_id UUID NOT NULL REFERENCES public.kots(id) ON DELETE CASCADE,
    menu_item_name VARCHAR(200) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    special_instructions VARCHAR(255)
);

-- ====================================================================
-- 8. ANTI-THEFT ORDER AUDIT LOGS
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.order_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    staff_name VARCHAR(150) NOT NULL,
    action_type VARCHAR(100) NOT NULL, -- ITEM_REMOVED, QTY_MODIFIED, DISCOUNT_APPLIED, ORDER_CANCELLED
    item_name VARCHAR(200),
    old_value VARCHAR(100),
    new_value VARCHAR(100),
    reason TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 9. CUSTOMERS & KHATA CREDIT LEDGER
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(30),
    address VARCHAR(255),
    total_due DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    is_staff BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TYPE khata_entry_type AS ENUM ('credit_purchase', 'payment_settlement', 'opening_due');

CREATE TABLE IF NOT EXISTS public.khata_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    entry_type khata_entry_type NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    payment_method payment_method_enum,
    note TEXT,
    staff_name VARCHAR(150) NOT NULL DEFAULT 'Addy',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 10. INVENTORY, RECIPE BOM & STOCK LOGS
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    unit VARCHAR(50) NOT NULL DEFAULT 'units', -- kg, ltr, pcs, cups
    current_stock DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    minimum_stock DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    cost_per_unit DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.recipe_bom (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    menu_item_id UUID NOT NULL REFERENCES public.menu_items(id) ON DELETE CASCADE,
    inventory_item_id UUID NOT NULL REFERENCES public.inventory_items(id) ON DELETE CASCADE,
    quantity_required DECIMAL(10, 4) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(menu_item_id, inventory_item_id)
);

CREATE TYPE stock_change_type AS ENUM ('sale_deduction', 'purchase_restock', 'wastage_adjustment');

CREATE TABLE IF NOT EXISTS public.stock_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    inventory_item_id UUID NOT NULL REFERENCES public.inventory_items(id) ON DELETE CASCADE,
    change_type stock_change_type NOT NULL,
    quantity_change DECIMAL(12, 2) NOT NULL,
    previous_stock DECIMAL(12, 2) NOT NULL,
    new_stock DECIMAL(12, 2) NOT NULL,
    reason TEXT,
    performed_by VARCHAR(150) NOT NULL DEFAULT 'Addy',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 11. INDEXES FOR PERFORMANCE
-- ====================================================================
CREATE INDEX IF NOT EXISTS idx_branches_tenant ON public.branches(tenant_id);
CREATE INDEX IF NOT EXISTS idx_dining_tables_branch ON public.dining_tables(branch_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_tenant_cat ON public.menu_items(tenant_id, category_id);
CREATE INDEX IF NOT EXISTS idx_orders_tenant_status ON public.orders(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_kots_order ON public.kots(order_id);
CREATE INDEX IF NOT EXISTS idx_customers_tenant ON public.customers(tenant_id);
CREATE INDEX IF NOT EXISTS idx_khata_customer ON public.khata_ledger(customer_id);
CREATE INDEX IF NOT EXISTS idx_inventory_tenant_branch ON public.inventory_items(tenant_id, branch_id);
CREATE INDEX IF NOT EXISTS idx_recipe_bom_menu_item ON public.recipe_bom(menu_item_id);
CREATE INDEX IF NOT EXISTS idx_stock_logs_item ON public.stock_logs(inventory_item_id);

-- ====================================================================
-- 12. ROW-LEVEL SECURITY (RLS) POLICIES
-- ====================================================================
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dining_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kot_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.khata_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipe_bom ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_logs ENABLE ROW LEVEL SECURITY;

-- Helper macro for Supabase JWT tenant_id isolation
-- In production, the JWT contains: {"tenant_id": "...", "branch_id": "..."}
CREATE OR REPLACE FUNCTION public.current_tenant_id() RETURNS UUID AS $$
    SELECT NULLIF(current_setting('request.jwt.claim.tenant_id', true), '')::UUID;
$$ LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION public.current_branch_id() RETURNS UUID AS $$
    SELECT NULLIF(current_setting('request.jwt.claim.branch_id', true), '')::UUID;
$$ LANGUAGE SQL STABLE;

-- RLS Policies Example: Dining Tables (scoped by tenant and branch)
CREATE POLICY "Tenant tables isolation" ON public.dining_tables
    FOR ALL
    USING (
        tenant_id = public.current_tenant_id() 
        OR public.current_tenant_id() IS NULL -- Fallback for service role key
    );

-- RLS Policies Example: Orders
CREATE POLICY "Tenant orders isolation" ON public.orders
    FOR ALL
    USING (
        tenant_id = public.current_tenant_id() 
        OR public.current_tenant_id() IS NULL
    );

-- RLS Policies Example: Customers & Khata
CREATE POLICY "Tenant customers isolation" ON public.customers
    FOR ALL
    USING (
        tenant_id = public.current_tenant_id() 
        OR public.current_tenant_id() IS NULL
    );

CREATE POLICY "Tenant khata isolation" ON public.khata_ledger
    FOR ALL
    USING (
        tenant_id = public.current_tenant_id() 
        OR public.current_tenant_id() IS NULL
    );

-- RLS Policies Example: Inventory & Recipes
CREATE POLICY "Tenant inventory isolation" ON public.inventory_items
    FOR ALL
    USING (
        tenant_id = public.current_tenant_id() 
        OR public.current_tenant_id() IS NULL
    );

CREATE POLICY "Tenant recipe_bom isolation" ON public.recipe_bom
    FOR ALL
    USING (
        tenant_id = public.current_tenant_id() 
        OR public.current_tenant_id() IS NULL
    );

-- ====================================================================
-- 13. SEED DATA (Exact Reference Cafe Baseline)
-- ====================================================================
INSERT INTO public.tenants (id, name, slug, vat_number, currency)
VALUES ('00000000-0000-0000-0000-000000000001', 'Saan Cafe & Lounge', 'saan-cafe', '609823412', 'NPR')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.branches (id, tenant_id, name, location, is_main)
VALUES ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Kathmandu Main Branch', 'Kathmandu Central', TRUE)
ON CONFLICT DO NOTHING;
