-- Add receiver_id column to chat_messages table to support Direct Messages
ALTER TABLE public.chat_messages ADD COLUMN receiver_id TEXT NULL;

-- Update the policy to allow viewing DMs
-- Drop the old policy
DROP POLICY IF EXISTS "Everyone can view chat messages" ON public.chat_messages;

-- Create the new policy where users can view global messages (receiver_id IS NULL) 
-- OR their own direct messages
CREATE POLICY "Users can view global and their own direct messages" 
ON public.chat_messages FOR SELECT 
TO authenticated 
USING (
    receiver_id IS NULL OR 
    sender_id = auth.uid()::text OR 
    receiver_id = auth.uid()::text
);
