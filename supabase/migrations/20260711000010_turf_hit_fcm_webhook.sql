-- Fire FCM Edge Function when a turf hit is recorded (killed-app push path).
-- verify_jwt is disabled on notify-turf-hit; body carries the row payload.

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.trg_notify_turf_hit_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://nankdbntvvopnfvvvaoo.supabase.co/functions/v1/notify-turf-hit',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := jsonb_build_object('record', to_jsonb(NEW))
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS turf_hit_push_notify ON public.turf_hit_notifications;
CREATE TRIGGER turf_hit_push_notify
  AFTER INSERT ON public.turf_hit_notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_notify_turf_hit_push();

REVOKE ALL ON FUNCTION public.trg_notify_turf_hit_push() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.trg_notify_turf_hit_push() TO postgres, service_role;
