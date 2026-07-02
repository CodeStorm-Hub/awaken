-- RPC execute grants: authenticated only (not anon).
-- SECURITY DEFINER is intentional — steal/contest writes cross user rows.

REVOKE ALL ON FUNCTION public.capture_territory(geometry) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.touch_territory_defense(geometry) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.leaderboard_nearby(double precision, double precision, double precision) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.leaderboard_windowed(integer, double precision, double precision, double precision) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.decaying_territories() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.capture_territory(geometry) TO authenticated;
GRANT EXECUTE ON FUNCTION public.touch_territory_defense(geometry) TO authenticated;
GRANT EXECUTE ON FUNCTION public.leaderboard_nearby(double precision, double precision, double precision) TO authenticated;
GRANT EXECUTE ON FUNCTION public.leaderboard_windowed(integer, double precision, double precision, double precision) TO authenticated;
GRANT EXECUTE ON FUNCTION public.decaying_territories() TO authenticated;
