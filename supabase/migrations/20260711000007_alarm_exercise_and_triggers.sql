-- Wave 1: Tax Roulette + Bailout Penalty schema.

ALTER TABLE public.alarms
  ADD COLUMN IF NOT EXISTS exercise_mode TEXT NOT NULL DEFAULT 'fixed'
    CHECK (exercise_mode IN ('fixed', 'roulette')),
  ADD COLUMN IF NOT EXISTS exercise_type TEXT
    CHECK (exercise_type IS NULL OR exercise_type IN ('squats', 'pushUps', 'jumpingJacks', 'sitUps')),
  ADD COLUMN IF NOT EXISTS penalty_multiplier INTEGER NOT NULL DEFAULT 1
    CHECK (penalty_multiplier >= 1 AND penalty_multiplier <= 4);

CREATE TABLE IF NOT EXISTS public.alarm_triggers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  alarm_id TEXT NOT NULL REFERENCES public.alarms (id) ON DELETE CASCADE,
  fired_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at TIMESTAMPTZ,
  required_reps INTEGER NOT NULL,
  exercise_type TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS alarm_triggers_user_unresolved_idx
  ON public.alarm_triggers (user_id, fired_at DESC)
  WHERE resolved_at IS NULL;

ALTER TABLE public.alarm_triggers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own alarm triggers"
  ON public.alarm_triggers
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
