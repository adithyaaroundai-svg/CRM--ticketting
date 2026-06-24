-- Fix existing timestamps that were stored in IST but marked as UTC
-- Subtract 5 hours 30 minutes to convert IST to actual UTC

-- Fix tickets table
UPDATE tickets 
SET 
  created_at = created_at - INTERVAL '5 hours 30 minutes',
  updated_at = updated_at - INTERVAL '5 hours 30 minutes',
  sla_due = CASE 
    WHEN sla_due IS NOT NULL THEN sla_due - INTERVAL '5 hours 30 minutes'
    ELSE NULL 
  END
WHERE created_at < NOW() - INTERVAL '1 minute'; -- Only fix old records, not ones just created

-- Fix ticket_remarks table
UPDATE ticket_remarks 
SET 
  created_at = CASE 
    WHEN created_at IS NOT NULL THEN created_at - INTERVAL '5 hours 30 minutes'
    ELSE NULL 
  END,
  updated_at = CASE 
    WHEN updated_at IS NOT NULL THEN updated_at - INTERVAL '5 hours 30 minutes'
    ELSE NULL 
  END
WHERE created_at IS NOT NULL AND created_at < NOW() - INTERVAL '1 minute';

-- Fix customers table
UPDATE customers 
SET 
  created_at = CASE 
    WHEN created_at IS NOT NULL THEN created_at - INTERVAL '5 hours 30 minutes'
    ELSE NULL 
  END,
  amc_expiry_date = CASE 
    WHEN amc_expiry_date IS NOT NULL THEN amc_expiry_date - INTERVAL '5 hours 30 minutes'
    ELSE NULL 
  END,
  tss_expiry_date = CASE 
    WHEN tss_expiry_date IS NOT NULL THEN tss_expiry_date - INTERVAL '5 hours 30 minutes'
    ELSE NULL 
  END
WHERE created_at IS NOT NULL AND created_at < NOW() - INTERVAL '1 minute';

-- Fix chat_messages table
UPDATE chat_messages 
SET 
  created_at = created_at - INTERVAL '5 hours 30 minutes'
WHERE created_at < NOW() - INTERVAL '1 minute';

-- Fix comments table
UPDATE comments 
SET 
  created_at = CASE 
    WHEN created_at IS NOT NULL THEN created_at - INTERVAL '5 hours 30 minutes'
    ELSE NULL 
  END
WHERE created_at IS NOT NULL AND created_at < NOW() - INTERVAL '1 minute';
