-- Add last_seen column if it doesn't exist
ALTER TABLE public.agents
ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ DEFAULT NOW();

-- Populate existing agents that don't have a value
UPDATE public.agents
SET last_seen = created_at
WHERE last_seen IS NULL;
