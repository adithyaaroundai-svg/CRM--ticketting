-- Add teams_user_id column to agents table
ALTER TABLE public.agents
ADD COLUMN IF NOT EXISTS teams_user_id text;

CREATE UNIQUE INDEX IF NOT EXISTS agents_teams_user_id_unique_idx
ON public.agents (teams_user_id)
WHERE teams_user_id IS NOT NULL;
