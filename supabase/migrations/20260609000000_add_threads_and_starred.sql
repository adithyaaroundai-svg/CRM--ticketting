-- Create message_threads table
CREATE TABLE IF NOT EXISTS public.message_threads (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    parent_message_id UUID NOT NULL REFERENCES public.chat_messages(id) ON DELETE CASCADE,
    reply_message_id UUID NOT NULL REFERENCES public.chat_messages(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    CONSTRAINT unique_thread_relationship UNIQUE(parent_message_id, reply_message_id),
    CONSTRAINT unique_reply_message UNIQUE(reply_message_id)
);

-- Create starred_messages table
CREATE TABLE IF NOT EXISTS public.starred_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    message_id UUID NOT NULL REFERENCES public.chat_messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(message_id, user_id)
);

-- Enable RLS on new tables
ALTER TABLE public.message_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.starred_messages ENABLE ROW LEVEL SECURITY;

-- Policies for message_threads
CREATE POLICY "Authenticated users can view message threads" 
ON public.message_threads FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Authenticated users can insert message threads" 
ON public.message_threads FOR INSERT 
TO authenticated 
WITH CHECK (true);

-- Policies for starred_messages
CREATE POLICY "Users can view their own starred messages"
ON public.starred_messages FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own starred messages"
ON public.starred_messages FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own starred messages"
ON public.starred_messages FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_message_threads_parent_message_id ON public.message_threads(parent_message_id);
CREATE INDEX IF NOT EXISTS idx_message_threads_reply_message_id ON public.message_threads(reply_message_id);
CREATE INDEX IF NOT EXISTS idx_starred_messages_message_id ON public.starred_messages(message_id);
CREATE INDEX IF NOT EXISTS idx_starred_messages_user_id ON public.starred_messages(user_id);
