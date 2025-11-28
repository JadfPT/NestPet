-- Add read receipts column and typing_status table
BEGIN;

-- 1) add read_at to messages
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS read_at timestamptz;

-- 2) typing_status table to store ephemeral typing flags per conversation
CREATE TABLE IF NOT EXISTS public.typing_status (
  animal_id uuid NOT NULL,
  user_id uuid NOT NULL,
  is_typing boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (animal_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_typing_animal_user ON public.typing_status (animal_id, user_id);

-- 3) RLS for typing_status: allow users to upsert their own status
ALTER TABLE public.typing_status ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS typing_status_upsert ON public.typing_status;
CREATE POLICY typing_status_upsert
  ON public.typing_status
  FOR ALL
  USING (user_id = auth.uid()::uuid)
  WITH CHECK (user_id = auth.uid()::uuid);

COMMIT;
