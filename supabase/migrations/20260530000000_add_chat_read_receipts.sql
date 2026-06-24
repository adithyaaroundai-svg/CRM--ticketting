-- Persist team chat read receipts so read status survives app restarts.
CREATE TABLE IF NOT EXISTS public.chat_read_receipts (
    message_id UUID NOT NULL REFERENCES public.chat_messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.agents(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    PRIMARY KEY (message_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_chat_read_receipts_user_id
ON public.chat_read_receipts(user_id);

ALTER TABLE public.chat_read_receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view chat read receipts"
ON public.chat_read_receipts FOR SELECT
USING (true);

CREATE POLICY "Everyone can insert chat read receipts"
ON public.chat_read_receipts FOR INSERT
WITH CHECK (true);

CREATE POLICY "Everyone can update chat read receipts"
ON public.chat_read_receipts FOR UPDATE
USING (true)
WITH CHECK (true);
