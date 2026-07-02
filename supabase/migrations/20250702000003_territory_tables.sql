-- Territory capture tables: owned polygons, run history, capture event log.

CREATE TABLE public.territories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  geom geometry(MultiPolygon, 4326) NOT NULL,
  health INTEGER NOT NULL DEFAULT 100,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_defended_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX territories_user_id_idx ON public.territories (user_id);
CREATE INDEX territories_geom_gist_idx ON public.territories USING GIST (geom);
CREATE INDEX territories_last_defended_at_idx ON public.territories (last_defended_at);

CREATE TABLE public.runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  path geometry(LineString, 4326) NOT NULL,
  distance_meters DOUBLE PRECISION NOT NULL,
  duration_seconds INTEGER NOT NULL,
  is_closed_loop BOOLEAN NOT NULL DEFAULT false,
  territory_claimed BOOLEAN NOT NULL DEFAULT false,
  area_claimed_sqm DOUBLE PRECISION,
  invalidated_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX runs_user_id_idx ON public.runs (user_id);
CREATE INDEX runs_created_at_idx ON public.runs (created_at);

CREATE TABLE public.territory_captures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  geom geometry(MultiPolygon, 4326) NOT NULL,
  area_sqm DOUBLE PRECISION NOT NULL,
  rivals_affected INTEGER NOT NULL DEFAULT 0,
  captured_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX territory_captures_user_id_idx ON public.territory_captures (user_id);
CREATE INDEX territory_captures_captured_at_idx ON public.territory_captures (captured_at);
CREATE INDEX territory_captures_geom_gist_idx ON public.territory_captures USING GIST (geom);

ALTER TABLE public.territories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.territory_captures ENABLE ROW LEVEL SECURITY;

-- Shared map: any signed-in user can read all territories.
-- Writes only via SECURITY DEFINER RPCs (capture_territory).
CREATE POLICY territories_select_all
  ON public.territories
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY runs_select_own
  ON public.runs
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY runs_insert_own
  ON public.runs
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Capture history is readable for windowed leaderboards; writes via RPC only.
CREATE POLICY territory_captures_select_all
  ON public.territory_captures
  FOR SELECT
  TO authenticated
  USING (true);
