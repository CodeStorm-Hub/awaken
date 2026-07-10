-- Client-facing views used by TerritorySupabaseDatasource.

CREATE OR REPLACE VIEW public.territories_geojson
  WITH (security_invoker = true) AS
SELECT
  t.id,
  t.user_id,
  p.display_name,
  ST_AsGeoJSON(t.geom) AS geojson,
  ST_Area(t.geom::geography) AS area_sqm,
  t.last_defended_at
FROM public.territories t
JOIN public.profiles p ON p.id = t.user_id;

CREATE OR REPLACE VIEW public.leaderboard_global
  WITH (security_invoker = true) AS
SELECT
  t.user_id,
  p.display_name,
  SUM(ST_Area(t.geom::geography)) AS total_area_sqm,
  RANK() OVER (ORDER BY SUM(ST_Area(t.geom::geography)) DESC) AS rank
FROM public.territories t
JOIN public.profiles p ON p.id = t.user_id
GROUP BY t.user_id, p.display_name
ORDER BY total_area_sqm DESC;

GRANT SELECT ON public.territories_geojson TO authenticated;
GRANT SELECT ON public.leaderboard_global TO authenticated;
