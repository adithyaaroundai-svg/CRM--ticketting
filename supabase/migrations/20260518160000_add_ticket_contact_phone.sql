-- Add a dedicated contact_phone column for tickets so agents can see who called.
ALTER TABLE public.tickets
  ADD COLUMN IF NOT EXISTS contact_phone text;

COMMENT ON COLUMN public.tickets.contact_phone IS
  'Phone number captured when raising the ticket.';
