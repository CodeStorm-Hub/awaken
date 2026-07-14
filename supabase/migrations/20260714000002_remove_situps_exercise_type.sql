-- Phase 3 hardening decision: sitUps was never camera-implemented (routed to
-- squats as a silent fallback) and unreachable via the setup screen's UI.
-- Removing it entirely rather than half-shipping it. See
-- docs/user_story/mlkit_pose_detection_hardening_plan.md Phase 3.
-- No existing rows use 'sitUps' (verified before this migration).

ALTER TABLE public.alarms
  DROP CONSTRAINT IF EXISTS alarms_exercise_type_check;

ALTER TABLE public.alarms
  ADD CONSTRAINT alarms_exercise_type_check
    CHECK (exercise_type IS NULL OR exercise_type IN ('squats', 'pushUps', 'jumpingJacks', 'highKnees'));
