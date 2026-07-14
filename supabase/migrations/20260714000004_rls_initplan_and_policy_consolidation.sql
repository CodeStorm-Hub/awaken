-- Performance hardening (advisor findings P1-P2, 2026-07-14 review):
-- P1: wrap auth.uid() as (select auth.uid()) in RLS policies so Postgres
--     evaluates it once per statement instead of once per row.
-- P2: squad_alarms had two overlapping permissive SELECT policies
--     (squad_alarms_select, squad_alarms_upsert as ALL) — split the ALL
--     policy into INSERT/UPDATE only so SELECT is decided by one policy.

-- P1 ---------------------------------------------------------------------

alter policy "Users can manage their own alarm triggers" on public.alarm_triggers
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

alter policy "push_tokens_own" on public.push_tokens
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

alter policy "turf_hit_select_own" on public.turf_hit_notifications
  using ((select auth.uid()) = victim_user_id);

alter policy "turf_hit_update_own" on public.turf_hit_notifications
  using ((select auth.uid()) = victim_user_id)
  with check ((select auth.uid()) = victim_user_id);

alter policy "territory_steals_select" on public.territory_steals
  using ((select auth.uid()) = attacker_id or (select auth.uid()) = victim_id);

alter policy "squads_insert_own" on public.squads
  with check (created_by = (select auth.uid()));

alter policy "squad_members_delete" on public.squad_members
  using (user_id = (select auth.uid()));

alter policy "squad_members_insert" on public.squad_members
  with check (user_id = (select auth.uid()));

alter policy "explored_cells_own" on public.explored_cells
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

alter policy "squad_bailouts_insert" on public.squad_bailouts
  with check (failed_user_id = (select auth.uid()));

alter policy "bounty_claims_insert" on public.bounty_claims
  with check ((select auth.uid()) = user_id);

-- P2 -----------------------------------------------------------------------
-- squad_alarms_upsert was FOR ALL (implicitly covering SELECT too),
-- overlapping with squad_alarms_select. Split into INSERT + UPDATE, both
-- scoped to the caller's own row and both using the initplan-safe form.

drop policy "squad_alarms_upsert" on public.squad_alarms;

create policy "squad_alarms_insert_own" on public.squad_alarms
  for insert
  with check (user_id = (select auth.uid()));

create policy "squad_alarms_update_own" on public.squad_alarms
  for update
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
