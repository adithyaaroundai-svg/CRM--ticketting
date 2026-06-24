INSERT INTO storage.buckets (id, name, public)
VALUES ('chat_attachments', 'chat_attachments', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public Read" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Upload" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Delete" ON storage.objects;

CREATE POLICY "Public Read"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'chat_attachments');

CREATE POLICY "Authenticated Upload"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'chat_attachments');

CREATE POLICY "Authenticated Delete"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'chat_attachments');
