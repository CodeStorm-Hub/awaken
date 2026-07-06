-- Database Performance Optimization Fixes
-- 1. Create a covering index for the alarm_id foreign key on public.sessions
CREATE INDEX IF NOT EXISTS sessions_alarm_id_idx ON public.sessions (alarm_id);

-- 2. Optimize RLS policies by wrapping auth.uid() inside a SELECT subquery
-- This allows the Postgres query planner to cache the value and avoid re-evaluating it for every row.

-- Optimize alarms policy
DROP POLICY IF EXISTS "Users can manage their own alarms" ON public.alarms;
CREATE POLICY "Users can manage their own alarms"
  ON public.alarms
  FOR ALL
  TO public
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Optimize sessions policy
DROP POLICY IF EXISTS "Users can manage their own sessions" ON public.sessions;
CREATE POLICY "Users can manage their own sessions"
  ON public.sessions
  FOR ALL
  TO public
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Optimize streaks policy
DROP POLICY IF EXISTS "Users can manage their own streak" ON public.streaks;
CREATE POLICY "Users can manage their own streak"
  ON public.streaks
  FOR ALL
  TO public
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- 3. Create functional GiST indexes for geography queries on geometry columns
-- Queries using ST_DWithin(geom::geography, ...) cannot use standard geometry indexes.
-- These functional indexes enable index scans on spatial queries cast to geography.
CREATE INDEX IF NOT EXISTS territories_geom_geog_idx ON public.territories USING GIST ((geom::geography));
CREATE INDEX IF NOT EXISTS territory_captures_geom_geog_idx ON public.territory_captures USING GIST ((geom::geography));
