-- Fix infinite RLS recursion on squad_members (42P17).
-- Policies that SELECT squad_members from within a squad_members policy
-- re-enter the same policy. Use a SECURITY DEFINER helper instead.

CREATE OR REPLACE FUNCTION public.is_squad_member(p_squad_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.squad_members
    WHERE squad_id = p_squad_id
      AND user_id = (SELECT auth.uid())
  );
$$;

REVOKE ALL ON FUNCTION public.is_squad_member(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_squad_member(uuid) TO authenticated;

DROP POLICY IF EXISTS squad_members_select ON public.squad_members;
CREATE POLICY squad_members_select ON public.squad_members
  FOR SELECT TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR public.is_squad_member(squad_id)
  );

DROP POLICY IF EXISTS squads_select_member ON public.squads;
CREATE POLICY squads_select_member ON public.squads
  FOR SELECT TO authenticated
  USING (
    created_by = (SELECT auth.uid())
    OR public.is_squad_member(id)
  );

DROP POLICY IF EXISTS squad_alarms_select ON public.squad_alarms;
CREATE POLICY squad_alarms_select ON public.squad_alarms
  FOR SELECT TO authenticated
  USING (public.is_squad_member(squad_id));

DROP POLICY IF EXISTS squad_bailouts_select ON public.squad_bailouts;
CREATE POLICY squad_bailouts_select ON public.squad_bailouts
  FOR SELECT TO authenticated
  USING (public.is_squad_member(squad_id));
