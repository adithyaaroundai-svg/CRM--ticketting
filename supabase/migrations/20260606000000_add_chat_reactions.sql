-- Add reactions column to chat_messages table
ALTER TABLE public.chat_messages 
ADD COLUMN IF NOT EXISTS reactions JSONB DEFAULT '[]'::jsonb;

-- Add index for faster queries on reactions
CREATE INDEX IF NOT EXISTS idx_chat_messages_reactions 
ON public.chat_messages USING GIN (reactions);
