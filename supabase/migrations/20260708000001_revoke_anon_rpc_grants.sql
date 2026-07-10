-- Supabase default privileges may re-grant anon EXECUTE after territory_grants.
-- Enforce authenticated-only access to territory RPCs (anti-cheat boundary).

REVOKE EXECUTE ON FUNCTION public.capture_territory(geometry) FROM anon;
REVOKE EXECUTE ON FUNCTION public.touch_territory_defense(geometry) FROM anon;
REVOKE EXECUTE ON FUNCTION public.leaderboard_nearby(double precision, double precision, double precision) FROM anon;
REVOKE EXECUTE ON FUNCTION public.leaderboard_windowed(integer, double precision, double precision, double precision) FROM anon;
REVOKE EXECUTE ON FUNCTION public.decaying_territories() FROM anon;
