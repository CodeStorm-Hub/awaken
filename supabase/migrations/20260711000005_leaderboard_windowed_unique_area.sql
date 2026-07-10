-- Windowed boards ranked by unique area claimed in the window (ST_Union),
-- not SUM(area_sqm) which double-counts overlapping loops and can exceed
-- all-time owned land (e.g. 0.074 km² momentum vs 0.071 km² owned).

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
AS $function$
  SELECT
    c.user_id,
    p.display_name,
    ST_Area(ST_Multi(ST_UnaryUnion(ST_Collect(c.geom)))::geography) AS total_area_sqm,
    RANK() OVER (
      ORDER BY ST_Area(ST_Multi(ST_UnaryUnion(ST_Collect(c.geom)))::geography) DESC
    ) AS rank
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
$function$;

REVOKE ALL ON FUNCTION public.leaderboard_windowed(integer, double precision, double precision, double precision) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.leaderboard_windowed(integer, double precision, double precision, double precision) TO authenticated;
