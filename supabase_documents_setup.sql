-- Create a table for document metadata
CREATE TABLE public.documents (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL,
  file_url text NOT NULL,
  file_type text NOT NULL,
  tag text,
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Create a table to track document-memory associations
CREATE TABLE public.document_memories (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  document_id uuid REFERENCES public.documents ON DELETE CASCADE NOT NULL,
  memory_id text NOT NULL,
  memory_content text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Create index for document_id for faster lookups
CREATE INDEX document_memories_document_id_idx ON public.document_memories(document_id);

-- Set up Row Level Security
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_memories ENABLE ROW LEVEL SECURITY;

-- Create policies for document_memories
CREATE POLICY "Users can view their own document memories" ON public.document_memories
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM public.documents WHERE id = document_id
    )
  );

CREATE POLICY "Users can insert their own document memories" ON public.document_memories
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM public.documents WHERE id = document_id
    )
  );

CREATE POLICY "Users can delete their own document memories" ON public.document_memories
  FOR DELETE USING (
    auth.uid() IN (
      SELECT user_id FROM public.documents WHERE id = document_id
    )
  );

-- Create policies for documents

-- Create policies
CREATE POLICY "Users can view their own documents" ON public.documents
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own documents" ON public.documents
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own documents" ON public.documents
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own documents" ON public.documents
  FOR DELETE USING (auth.uid() = user_id);

-- Create storage bucket for documents
INSERT INTO storage.buckets (id, name, public) VALUES ('documents', 'documents', true);

-- Set up storage policy to allow authenticated users to upload files
CREATE POLICY "Allow authenticated users to upload files"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'documents' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Set up storage policy to allow users to view their own files
CREATE POLICY "Allow users to view their own files"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'documents' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Set up storage policy to allow users to update their own files
CREATE POLICY "Allow users to update their own files"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'documents' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Set up storage policy to allow users to delete their own files
CREATE POLICY "Allow users to delete their own files"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'documents' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Create index for user_id for faster queries
CREATE INDEX documents_user_id_idx ON public.documents(user_id);

-- Create index for tag for faster filtering
CREATE INDEX documents_tag_idx ON public.documents(tag); 