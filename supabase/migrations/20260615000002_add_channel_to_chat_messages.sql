-- Add channel field to chat_messages table
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS channel TEXT DEFAULT 'support-chat';

-- Update existing messages to have the default channel
UPDATE public.chat_messages SET channel = 'support-chat' WHERE channel IS NULL;

-- Add index on channel for better query performance
CREATE INDEX IF NOT EXISTS idx_chat_messages_channel ON public.chat_messages(channel);
