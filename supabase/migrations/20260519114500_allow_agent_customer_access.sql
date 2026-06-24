-- Migration: Ensure agent app (anon key) can manage customers
-- Context: Flutter dashboard uses custom agent auth that never creates a
-- Supabase Auth session, so all traffic hits PostgREST as 'anon'. Recent RLS
-- hardening accidentally removed anon update permissions, which broke AMC edits.

-- 1. Ensure table still has RLS enabled (safe no-op if already on)
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

-- 2. Allow the agent app (anon role) to read customer records
DROP POLICY IF EXISTS "Allow agents (anon) to select customers" ON public.customers;
CREATE POLICY "Allow agents (anon) to select customers"
  ON public.customers
  FOR SELECT TO anon
  USING (true);

-- 3. Allow the agent app (anon role) to insert customer records
DROP POLICY IF EXISTS "Allow agents (anon) to insert customers" ON public.customers;
CREATE POLICY "Allow agents (anon) to insert customers"
  ON public.customers
  FOR INSERT TO anon
  WITH CHECK (true);

-- 4. Allow the agent app (anon role) to update customer records (AMC, etc.)
DROP POLICY IF EXISTS "Allow agents (anon) to update customers" ON public.customers;
CREATE POLICY "Allow agents (anon) to update customers"
  ON public.customers
  FOR UPDATE TO anon
  USING (true)
  WITH CHECK (true);
