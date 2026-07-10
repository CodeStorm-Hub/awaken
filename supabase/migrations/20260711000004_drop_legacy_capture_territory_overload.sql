-- Drop legacy capture_territory(geometry) overload that still returned
-- ST_Area(merged_geom) as claimed_area_sqm. Callers use the 2-arg form
-- (run_path may be omitted via DEFAULT NULL).

DROP FUNCTION IF EXISTS public.capture_territory(geometry);

REVOKE ALL ON FUNCTION public.capture_territory(geometry, geometry) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.capture_territory(geometry, geometry) TO authenticated;
