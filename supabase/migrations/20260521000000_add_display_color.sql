-- Add display_color to agents so each support/agent user can pick a name colour
ALTER TABLE public.agents
  ADD COLUMN IF NOT EXISTS display_color text;

-- Add display_color to customers (for customer-raised tickets)
ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS display_color text;
