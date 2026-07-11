-- Fog sync + squad shared bailout + bounty claim ledger

CREATE TABLE IF NOT EXISTS public.explored_cells (
  user_id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  cells text[] NOT NULL DEFAULT '{}',
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.explored_cells ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS explored_cells_own ON public.explored_cells;
CREATE POLICY explored_cells_own ON public.explored_cells
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.upsert_explored_cells(p_cells text[])
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  me uuid := auth.uid();
BEGIN
  IF me IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;
  INSERT INTO public.explored_cells (user_id, cells, updated_at)
  VALUES (me, COALESCE(p_cells, '{}'), now())
  ON CONFLICT (user_id) DO UPDATE
    SET cells = (
          SELECT ARRAY(
            SELECT DISTINCT c
            FROM unnest(
              public.explored_cells.cells || EXCLUDED.cells
            ) AS c
          )
        ),
        updated_at = now();
END;
$$;

GRANT EXECUTE ON FUNCTION public.upsert_explored_cells(text[]) TO authenticated;

CREATE TABLE IF NOT EXISTS public.squad_bailouts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  squad_id uuid NOT NULL REFERENCES public.squads (id) ON DELETE CASCADE,
  failed_user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  applied_at timestamptz
);

ALTER TABLE public.squad_bailouts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS squad_bailouts_select ON public.squad_bailouts;
CREATE POLICY squad_bailouts_select ON public.squad_bailouts
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.squad_members m
      WHERE m.squad_id = squad_bailouts.squad_id AND m.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS squad_bailouts_insert ON public.squad_bailouts;
CREATE POLICY squad_bailouts_insert ON public.squad_bailouts
  FOR INSERT TO authenticated
  WITH CHECK (failed_user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.report_squad_bailout()
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  me uuid := auth.uid();
  sid uuid;
BEGIN
  IF me IS NULL THEN RETURN; END IF;
  SELECT squad_id INTO sid FROM public.squad_members WHERE user_id = me LIMIT 1;
  IF sid IS NULL THEN RETURN; END IF;
  INSERT INTO public.squad_bailouts (squad_id, failed_user_id)
  VALUES (sid, me);
END;
$$;

GRANT EXECUTE ON FUNCTION public.report_squad_bailout() TO authenticated;

CREATE OR REPLACE FUNCTION public.consume_squad_bailout_penalty()
RETURNS boolean
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  me uuid := auth.uid();
  sid uuid;
  n int := 0;
BEGIN
  IF me IS NULL THEN RETURN false; END IF;
  SELECT squad_id INTO sid FROM public.squad_members WHERE user_id = me LIMIT 1;
  IF sid IS NULL THEN RETURN false; END IF;

  UPDATE public.squad_bailouts
     SET applied_at = now()
   WHERE squad_id = sid
     AND applied_at IS NULL
     AND failed_user_id IS DISTINCT FROM me
     AND created_at > now() - interval '36 hours';

  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN n > 0;
END;
$$;

GRANT EXECUTE ON FUNCTION public.consume_squad_bailout_penalty() TO authenticated;

CREATE TABLE IF NOT EXISTS public.bounty_claims (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  bounty_id uuid REFERENCES public.bounty_zones (id) ON DELETE SET NULL,
  label text NOT NULL,
  multiplier numeric NOT NULL DEFAULT 1.5,
  claimed_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS bounty_claims_user_idx
  ON public.bounty_claims (user_id, claimed_at DESC);

ALTER TABLE public.bounty_claims ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS bounty_claims_select ON public.bounty_claims;
CREATE POLICY bounty_claims_select ON public.bounty_claims
  FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS bounty_claims_insert ON public.bounty_claims;
CREATE POLICY bounty_claims_insert ON public.bounty_claims
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
