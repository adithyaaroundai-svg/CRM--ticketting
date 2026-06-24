-- Add sender_avatar_url to chat_messages table
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS sender_avatar_url TEXT;
