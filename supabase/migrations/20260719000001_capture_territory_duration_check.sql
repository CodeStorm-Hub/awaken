-- Anti-cheat hardening: capture_territory validated path geometry (segment
-- distance, density, area) but never cross-checked claimed path length
-- against real elapsed time, so a client could submit a geometrically-valid
-- closed loop with fabricated/instant timing and claim territory with no
-- actual run behind it. Add an optional duration_seconds parameter and
-- reject implausible average speeds.
--
-- duration_seconds defaults to NULL so already-deployed clients that don't
-- send it yet are not broken by this migration — the check only runs when
-- a duration is actually provided. Once every client build sends it,
-- consider tightening this to REQUIRE the parameter, matching the existing
-- `run_path_required` pattern.
CREATE OR REPLACE FUNCTION public.capture_territory(
  new_geom geometry,
  run_path geometry DEFAULT NULL,
  duration_seconds integer DEFAULT NULL
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
  -- ~21.6 km/h sustained average — generous for a fast run/sprint, but well
  -- below any plausible "instant" or vehicle-assisted submission.
  max_avg_speed_mps CONSTANT DOUBLE PRECISION := 6.0;
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

  -- Cross-check average speed against real elapsed time — the per-segment
  -- check above only catches implausible gaps *between* fixes, not a whole
  -- path submitted with fabricated or near-zero total duration.
  IF duration_seconds IS NOT NULL THEN
    IF duration_seconds <= 0 THEN
      RAISE EXCEPTION 'duration_invalid';
    END IF;
    IF (path_len / duration_seconds::double precision) > max_avg_speed_mps THEN
      RAISE EXCEPTION 'capture_too_fast';
    END IF;
  END IF;

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

-- New overload signature — drop the old two-arg one so callers can't bypass
-- the duration check by omitting the third argument's name resolution, then
-- re-apply the same grant posture as the original.
DROP FUNCTION IF EXISTS public.capture_territory(geometry, geometry);

REVOKE ALL ON FUNCTION public.capture_territory(geometry, geometry, integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.capture_territory(geometry, geometry, integer) FROM anon;
GRANT EXECUTE ON FUNCTION public.capture_territory(geometry, geometry, integer) TO authenticated;
