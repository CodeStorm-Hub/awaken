-- Phase 0 hardening: alarms.exercise_type check constraint was missing 'highKnees',
-- which is a fully implemented exercise (HighKneesCounterService) — signed-in users
-- could not save a fixed-mode High Knees alarm. See docs/user_story/mlkit_pose_detection_hardening_plan.md §0.1.

ALTER TABLE public.alarms
  DROP CONSTRAINT IF EXISTS alarms_exercise_type_check;

ALTER TABLE public.alarms
  ADD CONSTRAINT alarms_exercise_type_check
    CHECK (exercise_type IS NULL OR exercise_type IN ('squats', 'pushUps', 'jumpingJacks', 'highKnees', 'sitUps'));
