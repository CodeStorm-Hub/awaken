-- Wave 3–4: live competition + squads + push tokens + bounty zones

-- ── Push tokens ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.push_tokens (
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  token text NOT NULL,
  platform text NOT NULL DEFAULT 'android',
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, token)
);

ALTER TABLE public.push_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS push_tokens_own ON public.push_tokens;
CREATE POLICY push_tokens_own ON public.push_tokens
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── Turf-hit notifications ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.turf_hit_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  victim_user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  attacker_user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  claimed_area_sq_meters double precision NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  read_at timestamptz
);

CREATE INDEX IF NOT EXISTS turf_hit_victim_idx
  ON public.turf_hit_notifications (victim_user_id, created_at DESC);

ALTER TABLE public.turf_hit_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS turf_hit_select_own ON public.turf_hit_notifications;
CREATE POLICY turf_hit_select_own ON public.turf_hit_notifications
  FOR SELECT TO authenticated
  USING (auth.uid() = victim_user_id);

DROP POLICY IF EXISTS turf_hit_update_own ON public.turf_hit_notifications;
CREATE POLICY turf_hit_update_own ON public.turf_hit_notifications
  FOR UPDATE TO authenticated
  USING (auth.uid() = victim_user_id)
  WITH CHECK (auth.uid() = victim_user_id);

-- Steal ledger for nemesis pairing
CREATE TABLE IF NOT EXISTS public.territory_steals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  attacker_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  victim_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  area_sqm double precision NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS territory_steals_pair_idx
  ON public.territory_steals (attacker_id, victim_id);

ALTER TABLE public.territory_steals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS territory_steals_select ON public.territory_steals;
CREATE POLICY territory_steals_select ON public.territory_steals
  FOR SELECT TO authenticated
  USING (auth.uid() = attacker_id OR auth.uid() = victim_id);

-- ── Patch capture_territory to emit turf hits + steals ──────────────────────
CREATE OR REPLACE FUNCTION public.capture_territory(
  new_geom geometry,
  run_path geometry DEFAULT NULL
)
RETURNS TABLE(
  claimed_area_sqm double precision,
  total_owned_area_sqm double precision,
  rivals_affected integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
  user_uuid UUID := auth.uid();
  merged_geom GEOMETRY;
  affected_rivals INT;
  claimed_area DOUBLE PRECISION;
  path_len DOUBLE PRECISION;
  ring_pts INT;
  path_pts INT;
  i INT;
  seg_m DOUBLE PRECISION;
  max_segment_meters CONSTANT DOUBLE PRECISION := 80.0;
  rival RECORD;
BEGIN
  IF user_uuid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  IF run_path IS NULL THEN
    RAISE EXCEPTION 'run_path_required';
  END IF;

  new_geom := ST_SetSRID(new_geom, 4326);
  claimed_area := ST_Area(new_geom::geography);

  IF claimed_area < 50.0 THEN
    RAISE EXCEPTION 'loop_too_small';
  END IF;

  IF claimed_area > 500000.0 THEN
    RAISE EXCEPTION 'loop_too_large';
  END IF;

  ring_pts := ST_NPoints(ST_ExteriorRing(ST_GeometryN(ST_MakeValid(new_geom), 1)));
  IF ring_pts IS NULL OR ring_pts < 6 THEN
    RAISE EXCEPTION 'loop_too_simple';
  END IF;

  run_path := ST_SetSRID(run_path, 4326);
  path_len := ST_Length(run_path::geography);
  IF path_len < 150.0 THEN
    RAISE EXCEPTION 'path_too_short';
  END IF;

  path_pts := ST_NPoints(run_path);
  IF path_pts IS NULL OR path_pts < 6 THEN
    RAISE EXCEPTION 'path_too_sparse';
  END IF;

  FOR i IN 1..(path_pts - 1) LOOP
    seg_m := ST_Distance(
      ST_PointN(run_path, i)::geography,
      ST_PointN(run_path, i + 1)::geography
    );
    IF seg_m > max_segment_meters THEN
      RAISE EXCEPTION 'path_segment_too_fast';
    END IF;
  END LOOP;

  PERFORM 1 FROM territories
    WHERE ST_Intersects(geom, new_geom)
    ORDER BY id
    FOR UPDATE;

  new_geom := ST_Multi(ST_MakeValid(new_geom));
  claimed_area := ST_Area(new_geom::geography);

  SELECT ST_Union(geom) INTO merged_geom
    FROM territories WHERE user_id = user_uuid AND ST_Intersects(geom, new_geom);
  merged_geom := ST_Multi(ST_Union(COALESCE(merged_geom, ST_GeomFromText('MULTIPOLYGON EMPTY', 4326)), new_geom));
  DELETE FROM territories WHERE user_id = user_uuid AND ST_Intersects(geom, new_geom);
  INSERT INTO territories (user_id, geom, last_defended_at)
    VALUES (user_uuid, merged_geom, NOW());

  SELECT COUNT(*) INTO affected_rivals
    FROM territories WHERE user_id != user_uuid AND ST_Intersects(geom, merged_geom);

  -- Emit turf-hit + steal ledger before cutting rival geom.
  FOR rival IN
    SELECT user_id AS victim_id,
           ST_Area(ST_Intersection(geom, merged_geom)::geography) AS cut_sqm
      FROM territories
     WHERE user_id != user_uuid AND ST_Intersects(geom, merged_geom)
  LOOP
    INSERT INTO public.turf_hit_notifications (
      victim_user_id, attacker_user_id, claimed_area_sq_meters
    ) VALUES (rival.victim_id, user_uuid, COALESCE(rival.cut_sqm, 0));

    INSERT INTO public.territory_steals (
      attacker_id, victim_id, area_sqm
    ) VALUES (user_uuid, rival.victim_id, COALESCE(rival.cut_sqm, 0));
  END LOOP;

  UPDATE territories
    SET geom = ST_Multi(ST_CollectionExtract(ST_Difference(geom, merged_geom), 3))
    WHERE user_id != user_uuid AND ST_Intersects(geom, merged_geom);

  DELETE FROM territories
    WHERE user_id != user_uuid AND (ST_IsEmpty(geom) OR ST_Area(geom::geography) < 1.0);

  INSERT INTO territory_captures (user_id, geom, area_sqm, rivals_affected)
    VALUES (user_uuid, new_geom, claimed_area, affected_rivals);

  RETURN QUERY
    SELECT
      claimed_area AS claimed_area_sqm,
      (SELECT COALESCE(SUM(ST_Area(geom::geography)), 0)
         FROM territories WHERE user_id = user_uuid) AS total_owned_area_sqm,
      affected_rivals AS rivals_affected;
END;
$function$;

REVOKE ALL ON FUNCTION public.capture_territory(geometry, geometry) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.capture_territory(geometry, geometry) FROM anon;
GRANT EXECUTE ON FUNCTION public.capture_territory(geometry, geometry) TO authenticated;

-- ── Bounty zones ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.bounty_zones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  label text NOT NULL DEFAULT 'BOUNTY',
  multiplier numeric NOT NULL DEFAULT 1.5,
  geom geometry(Polygon, 4326) NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS bounty_zones_geom_idx
  ON public.bounty_zones USING GIST (geom);
CREATE INDEX IF NOT EXISTS bounty_zones_expires_idx
  ON public.bounty_zones (expires_at);

ALTER TABLE public.bounty_zones ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS bounty_zones_read ON public.bounty_zones;
CREATE POLICY bounty_zones_read ON public.bounty_zones
  FOR SELECT TO authenticated, anon
  USING (expires_at > now());

CREATE OR REPLACE FUNCTION public.list_active_bounty_zones()
RETURNS TABLE (
  id uuid,
  label text,
  multiplier numeric,
  expires_at timestamptz,
  geojson jsonb
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    b.id,
    b.label,
    b.multiplier,
    b.expires_at,
    ST_AsGeoJSON(b.geom)::jsonb AS geojson
  FROM public.bounty_zones b
  WHERE b.expires_at > now();
$$;

GRANT EXECUTE ON FUNCTION public.list_active_bounty_zones() TO authenticated, anon;

INSERT INTO public.bounty_zones (label, multiplier, geom, expires_at)
SELECT
  'DOWNTOWN BOUNTY',
  2.0,
  ST_SetSRID(
    ST_MakePolygon(
      ST_GeomFromText(
        'LINESTRING(-79.390 43.645, -79.375 43.645, -79.375 43.655, -79.390 43.655, -79.390 43.645)'
      )
    ),
    4326
  ),
  now() + interval '30 days'
WHERE NOT EXISTS (SELECT 1 FROM public.bounty_zones LIMIT 1);

-- ── Nemesis RPC ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_nemesis()
RETURNS TABLE (
  rival_user_id uuid,
  rival_display_name text,
  mutual_steal_count bigint,
  my_disputed_sq_meters double precision,
  rival_disputed_sq_meters double precision
)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  me uuid := auth.uid();
BEGIN
  IF me IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH pairs AS (
    SELECT
      CASE WHEN s.attacker_id = me THEN s.victim_id ELSE s.attacker_id END AS rival,
      COUNT(*)::bigint AS steal_count,
      COALESCE(SUM(s.area_sqm) FILTER (WHERE s.attacker_id = me), 0)::double precision AS my_m2,
      COALESCE(SUM(s.area_sqm) FILTER (WHERE s.victim_id = me), 0)::double precision AS rival_m2
    FROM public.territory_steals s
    WHERE s.attacker_id = me OR s.victim_id = me
    GROUP BY 1
  )
  SELECT
    p.rival,
    COALESCE(pr.display_name, 'Rival'),
    p.steal_count,
    p.my_m2,
    p.rival_m2
  FROM pairs p
  LEFT JOIN public.profiles pr ON pr.id = p.rival
  WHERE p.rival IS NOT NULL
  ORDER BY p.steal_count DESC, (p.my_m2 + p.rival_m2) DESC
  LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_nemesis() TO authenticated;

-- ── Squads ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.squads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  invite_code text NOT NULL UNIQUE DEFAULT substr(md5(random()::text), 1, 8),
  created_by uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.squad_members (
  squad_id uuid NOT NULL REFERENCES public.squads (id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  joined_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (squad_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.squad_alarms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  squad_id uuid NOT NULL REFERENCES public.squads (id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  rep_count int NOT NULL DEFAULT 0,
  required_reps int NOT NULL DEFAULT 20,
  exercise_type text,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (squad_id, user_id)
);

ALTER TABLE public.squads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.squad_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.squad_alarms ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS squads_select_member ON public.squads;
CREATE POLICY squads_select_member ON public.squads
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.squad_members m
      WHERE m.squad_id = id AND m.user_id = auth.uid()
    )
    OR created_by = auth.uid()
  );

DROP POLICY IF EXISTS squads_insert_own ON public.squads;
CREATE POLICY squads_insert_own ON public.squads
  FOR INSERT TO authenticated
  WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS squad_members_select ON public.squad_members;
CREATE POLICY squad_members_select ON public.squad_members
  FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.squad_members m
      WHERE m.squad_id = squad_members.squad_id AND m.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS squad_members_insert ON public.squad_members;
CREATE POLICY squad_members_insert ON public.squad_members
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS squad_members_delete ON public.squad_members;
CREATE POLICY squad_members_delete ON public.squad_members
  FOR DELETE TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS squad_alarms_select ON public.squad_alarms;
CREATE POLICY squad_alarms_select ON public.squad_alarms
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.squad_members m
      WHERE m.squad_id = squad_alarms.squad_id AND m.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS squad_alarms_upsert ON public.squad_alarms;
CREATE POLICY squad_alarms_upsert ON public.squad_alarms
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.squad_alarms;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.turf_hit_notifications;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS hud_theme text NOT NULL DEFAULT 'cyan';
