-- Territory capture RPCs — verified against live project fsdfqcnjcjtdmdjshrvu.

CREATE OR REPLACE FUNCTION public.capture_territory(new_geom geometry)
RETURNS TABLE(
  claimed_area_sqm double precision,
  total_owned_area_sqm double precision,
  rivals_affected integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  user_uuid UUID := auth.uid();
  merged_geom GEOMETRY;
  affected_rivals INT;
BEGIN
  IF user_uuid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  new_geom := ST_SetSRID(new_geom, 4326);

  IF ST_Area(new_geom::geography) < 50.0 THEN
    RAISE EXCEPTION 'loop_too_small';
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

  RETURN QUERY
    SELECT
      ST_Area(merged_geom::geography) AS claimed_area_sqm,
      (SELECT COALESCE(SUM(ST_Area(geom::geography)), 0) FROM territories WHERE user_id = user_uuid) AS total_owned_area_sqm,
      affected_rivals AS rivals_affected;
END;
$$;

CREATE OR REPLACE FUNCTION public.touch_territory_defense(run_path geometry)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  user_uuid UUID := auth.uid();
BEGIN
  IF user_uuid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  UPDATE territories
    SET last_defended_at = NOW()
    WHERE user_id = user_uuid
      AND ST_DWithin(geom::geography, ST_SetSRID(run_path, 4326)::geography, 25.0);
END;
$$;

CREATE OR REPLACE FUNCTION public.leaderboard_nearby(
  viewer_lon double precision,
  viewer_lat double precision,
  radius_meters double precision DEFAULT 5000
)
RETURNS TABLE(
  user_id uuid,
  display_name text,
  total_area_sqm double precision,
  rank bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
  SELECT
    t.user_id,
    p.display_name,
    SUM(ST_Area(t.geom::geography)) AS total_area_sqm,
    RANK() OVER (ORDER BY SUM(ST_Area(t.geom::geography)) DESC) AS rank
  FROM territories t
  JOIN public.profiles p ON p.id = t.user_id
  WHERE ST_DWithin(
    t.geom::geography,
    ST_SetSRID(ST_MakePoint(viewer_lon, viewer_lat), 4326)::geography,
    radius_meters
  )
  GROUP BY t.user_id, p.display_name
  ORDER BY total_area_sqm DESC;
$$;

CREATE OR REPLACE FUNCTION public.leaderboard_windowed(
  window_hours integer,
  viewer_lon double precision DEFAULT NULL,
  viewer_lat double precision DEFAULT NULL,
  radius_meters double precision DEFAULT NULL
)
RETURNS TABLE(
  user_id uuid,
  display_name text,
  total_area_sqm double precision,
  rank bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
  SELECT
    c.user_id,
    p.display_name,
    SUM(c.area_sqm) AS total_area_sqm,
    RANK() OVER (ORDER BY SUM(c.area_sqm) DESC) AS rank
  FROM territory_captures c
  JOIN public.profiles p ON p.id = c.user_id
  WHERE c.captured_at >= NOW() - (window_hours || ' hours')::interval
    AND (
      viewer_lon IS NULL OR viewer_lat IS NULL OR radius_meters IS NULL
      OR ST_DWithin(
        c.geom::geography,
        ST_SetSRID(ST_MakePoint(viewer_lon, viewer_lat), 4326)::geography,
        radius_meters
      )
    )
  GROUP BY c.user_id, p.display_name
  ORDER BY total_area_sqm DESC;
$$;

CREATE OR REPLACE FUNCTION public.decaying_territories()
RETURNS TABLE(
  id uuid,
  days_until_decay double precision,
  area_sqm double precision
)
LANGUAGE sql
STABLE
SET search_path TO 'public', 'extensions'
AS $$
  SELECT
    id,
    EXTRACT(EPOCH FROM ((last_defended_at + INTERVAL '7 days') - NOW())) / 86400.0 AS days_until_decay,
    ST_Area(geom::geography) AS area_sqm
  FROM territories
  WHERE user_id = auth.uid()
    AND last_defended_at < NOW() - INTERVAL '5 days'
    AND last_defended_at >= NOW() - INTERVAL '7 days';
$$;
