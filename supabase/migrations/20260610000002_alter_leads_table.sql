-- Add missing columns to existing leads table
ALTER TABLE public.leads
ADD COLUMN IF NOT EXISTS customer_name TEXT,
ADD COLUMN IF NOT EXISTS phone_number TEXT NOT NULL DEFAULT '',
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS follow_up_date DATE,
ADD COLUMN IF NOT EXISTS owner TEXT,
ADD COLUMN IF NOT EXISTS source TEXT,
ADD COLUMN IF NOT EXISTS demo_needed TEXT;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_leads_customer_name ON public.leads(customer_name);
CREATE INDEX IF NOT EXISTS idx_leads_phone_number ON public.leads(phone_number);
CREATE INDEX IF NOT EXISTS idx_leads_owner ON public.leads(owner);
CREATE INDEX IF NOT EXISTS idx_leads_source ON public.leads(source);
