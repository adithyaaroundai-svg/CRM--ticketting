-- Add rich_text_delta column to chat_messages table to store Fleather Delta format
ALTER TABLE public.chat_messages 
ADD COLUMN IF NOT EXISTS rich_text_delta JSONB;
