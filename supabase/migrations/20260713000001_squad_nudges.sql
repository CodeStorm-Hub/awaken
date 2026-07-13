-- Squad nudges: one-tap accountability pings between squad mates.
-- Sender inserts one row per recipient; the recipient sees a dashboard
-- banner on next app open and marks their inbox seen.

CREATE TABLE IF NOT EXISTS public.squad_nudges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  squad_id uuid NOT NULL REFERENCES public.squads(id) ON DELETE CASCADE,
  from_user uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  to_user uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  seen boolean NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS squad_nudges_to_user_unseen_idx
  ON public.squad_nudges (to_user) WHERE NOT seen;

ALTER TABLE public.squad_nudges ENABLE ROW LEVEL SECURITY;

-- Send: only as yourself, never to yourself, only within a squad you belong
-- to, and only to users who are actually members of that squad.
DROP POLICY IF EXISTS squad_nudges_insert ON public.squad_nudges;
CREATE POLICY squad_nudges_insert ON public.squad_nudges
  FOR INSERT TO authenticated
  WITH CHECK (
    from_user = (SELECT auth.uid())
    AND to_user <> (SELECT auth.uid())
    AND public.is_squad_member(squad_id)
    AND EXISTS (
      SELECT 1
      FROM public.squad_members sm
      WHERE sm.squad_id = squad_nudges.squad_id
        AND sm.user_id = squad_nudges.to_user
    )
  );

-- Read: your own inbox and outbox.
DROP POLICY IF EXISTS squad_nudges_select ON public.squad_nudges;
CREATE POLICY squad_nudges_select ON public.squad_nudges
  FOR SELECT TO authenticated
  USING (
    to_user = (SELECT auth.uid())
    OR from_user = (SELECT auth.uid())
  );

-- Mark seen: recipient only.
DROP POLICY IF EXISTS squad_nudges_update_seen ON public.squad_nudges;
CREATE POLICY squad_nudges_update_seen ON public.squad_nudges
  FOR UPDATE TO authenticated
  USING (to_user = (SELECT auth.uid()))
  WITH CHECK (to_user = (SELECT auth.uid()));

GRANT SELECT, INSERT, UPDATE ON public.squad_nudges TO authenticated;
