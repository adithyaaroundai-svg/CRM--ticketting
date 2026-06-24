ALTER TABLE public.tickets
ADD COLUMN IF NOT EXISTS payment_collected boolean NOT NULL DEFAULT false;

ALTER TABLE public.tickets
ADD COLUMN IF NOT EXISTS bill_amount numeric(12,2);

ALTER TABLE public.tickets
ADD CONSTRAINT tickets_bill_amount_check
CHECK (bill_amount IS NULL OR bill_amount >= 0);

COMMENT ON COLUMN public.tickets.payment_collected IS
'Whether payment has been collected for this ticket.';

COMMENT ON COLUMN public.tickets.bill_amount IS
'Amount billed for this ticket in INR.';
