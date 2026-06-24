-- Index for fast thread reply lookups on existing thread_parent_id column
CREATE INDEX IF NOT EXISTS idx_chat_messages_thread_parent_id ON public.chat_messages(thread_parent_id);

-- Fix RLS on message_threads if not already applied
ALTER TABLE public.message_threads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can view message threads" ON public.message_threads;
DROP POLICY IF EXISTS "Authenticated users can insert message threads" ON public.message_threads;

CREATE POLICY "Authenticated users can view message threads"
ON public.message_threads FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Authenticated users can insert message threads"
ON public.message_threads FOR INSERT
TO authenticated
WITH CHECK (true);
