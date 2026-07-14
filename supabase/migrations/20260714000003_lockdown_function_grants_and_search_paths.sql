-- Security hardening (advisor findings D1-D5, 2026-07-14 review):
-- 1) SECURITY DEFINER functions must not be callable by anon (or at all,
--    for the trigger function) via PostgREST /rest/v1/rpc/.
-- 2) Future functions should ship locked-down by default.
-- 3) PostGIS's spatial_ref_sys: revoke writes from client roles.
-- 4) Pin search_path on the two flagged SECURITY INVOKER functions.

-- D2: trigger function — only ever runs as the trigger owner.
revoke execute on function public.trg_notify_turf_hit_push() from public, anon, authenticated;

-- D3: app calls these as authenticated only; remove anon surface.
revoke execute on function public.allocate_territory_color() from public, anon;
revoke execute on function public.is_squad_member(uuid) from public, anon;

-- D4: PostGIS internal estimator — nothing calls it over PostgREST.
revoke execute on function public.st_estimatedextent(text, text) from public, anon, authenticated;
revoke execute on function public.st_estimatedextent(text, text, text) from public, anon, authenticated;
revoke execute on function public.st_estimatedextent(text, text, text, boolean) from public, anon, authenticated;

-- Systemic: new functions no longer get EXECUTE for PUBLIC implicitly;
-- future migrations must grant to anon/authenticated explicitly.
alter default privileges in schema public revoke execute on functions from public;

-- D1: spatial_ref_sys is PostGIS-managed reference data (RLS intentionally
-- not enabled — PostGIS reads it internally); block client writes instead.
revoke insert, update, delete on table public.spatial_ref_sys from anon, authenticated;

-- D5: pin search_path (mutable-search-path advisor).
alter function public.hsl_to_hex(double precision, double precision, double precision) set search_path = public, pg_temp;
alter function public.profiles_lock_territory_color() set search_path = public, pg_temp;
