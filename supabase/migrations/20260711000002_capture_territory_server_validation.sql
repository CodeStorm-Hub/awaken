-- Server-side anti-forge checks for territory capture.
-- Optional run_path lets the server re-validate path length / density.

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
BEGIN
  IF user_uuid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
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

  IF run_path IS NOT NULL THEN
    run_path := ST_SetSRID(run_path, 4326);
    path_len := ST_Length(run_path::geography);
    IF path_len < 150.0 THEN
      RAISE EXCEPTION 'path_too_short';
    END IF;
    IF ST_NPoints(run_path) < 6 THEN
      RAISE EXCEPTION 'path_too_sparse';
    END IF;
  END IF;

  PERFORM 1 FROM territories
    WHERE ST_Intersects(geom, new_geom)
    ORDER BY id
    FOR UPDATE;

  new_geom := ST_Multi(ST_MakeValid(new_geom));

  SELECT ST_Union(geom) INTO merged_geom
    FROM territories WHERE user_id = user_uuid AND ST_Intersects(geom, new_geom);
  merged_geom := ST_Multi(ST_Union(COALESCE(merged_geom, ST_GeomFromText('MULTIPOLYGON EMPTY', 4326)), new_geom));
  DELETE FROM territories WHERE user_id = user_uuid AND ST_Intersects(geom, new_geom);
  INSERT INTO territories (user_id, geom, last_defended_at)
    VALUES (user_uuid, merged_geom, NOW());

  SELECT COUNT(*) INTO affected_rivals
    FROM territories WHERE user_id != user_uuid AND ST_Intersects(geom, merged_geom);

  UPDATE territories
    SET geom = ST_Multi(ST_CollectionExtract(ST_Difference(geom, merged_geom), 3))
    WHERE user_id != user_uuid AND ST_Intersects(geom, merged_geom);

  DELETE FROM territories
    WHERE user_id != user_uuid AND (ST_IsEmpty(geom) OR ST_Area(geom::geography) < 1.0);

  INSERT INTO territory_captures (user_id, geom, area_sqm, rivals_affected)
    VALUES (user_uuid, new_geom, ST_Area(new_geom::geography), affected_rivals);

  -- claimed_area_sqm = this loop only (not the post-merge multipolygon).
  -- total_owned_area_sqm = SUM of all current territories for the user.
  RETURN QUERY
    SELECT
      ST_Area(new_geom::geography) AS claimed_area_sqm,
      (SELECT COALESCE(SUM(ST_Area(geom::geography)), 0) FROM territories WHERE user_id = user_uuid) AS total_owned_area_sqm,
      affected_rivals AS rivals_affected;
END;
$function$;

REVOKE ALL ON FUNCTION public.capture_territory(geometry, geometry) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.capture_territory(geometry, geometry) TO authenticated;
