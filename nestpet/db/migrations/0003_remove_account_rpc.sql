-- Migration: create RPC to remove authenticated user's account and related rows
-- Run this in Supabase SQL Editor (it runs as admin and will create the function
-- owned by a superuser role). The function is SECURITY DEFINER so it can delete from
-- protected schemas (e.g. auth.users). It uses auth.uid() to ensure the caller
-- can only delete their own account.

BEGIN;

CREATE OR REPLACE FUNCTION public.remove_account_and_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  p_uid uuid := auth.uid()::uuid;
BEGIN
  IF p_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  -- Delete dependent rows. Order matters due to FK constraints.
  PERFORM 1;
  DELETE FROM public.favorites WHERE user_id = p_uid;
  DELETE FROM public.typing_status WHERE user_id = p_uid;
  DELETE FROM public.messages WHERE user_id = p_uid;
  DELETE FROM public.animals WHERE org_id = p_uid;
  DELETE FROM public.organizations WHERE user_id = p_uid;
  DELETE FROM public.profiles WHERE id = p_uid;

  -- Finally remove the auth user record.
  DELETE FROM auth.users WHERE id = p_uid;
END;
$$;

COMMIT;

-- IMPORTANT:
-- 1) Deploy this from the Supabase SQL Editor (or other admin connection) so the
--    function is created with superuser/owner privileges. The SQL Editor executes
--    as an admin and therefore the function will be able to delete from auth.users.
-- 2) The function uses auth.uid() so it can only delete the account of the
--    authenticated caller. Do NOT change this function to accept an arbitrary uid
--    unless you also add strict authorization checks.
-- 3) Once the function exists you can call it from the client using the RPC
--    endpoint: e.g. `supabase.rpc('remove_account_and_data')`.
-- 4) For auditing, you can extend the function to insert a row into an admin log
--    table before deleting.
