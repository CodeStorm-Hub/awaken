-- Anti-cheat visibility: nothing in the alarm-dismissal path is server
-- verified (rep counts and camera-failure claims are both client-local
-- state). Record whether the accessibility tap-fallback was used for each
-- completed session so a disproportionate rate on an account (e.g. "camera
-- failed" on effectively every alarm) can be flagged for manual review,
-- even though it isn't blocked in real time.
ALTER TABLE public.sessions
  ADD COLUMN IF NOT EXISTS used_accessibility_mode boolean NOT NULL DEFAULT false;
