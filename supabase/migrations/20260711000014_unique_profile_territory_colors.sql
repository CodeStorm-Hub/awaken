-- Unique territory map color per profile, assigned automatically on signup.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS territory_color text;

-- Existing rows get colors before the NOT NULL / UNIQUE constraints.
CREATE OR REPLACE FUNCTION public.hsl_to_hex(
  hue double precision,
  sat double precision,
  light double precision
)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  h double precision := ((hue % 360) + 360) % 360;
  s double precision := GREATEST(0, LEAST(1, sat));
  l double precision := GREATEST(0, LEAST(1, light));
  c double precision := (1 - abs(2 * l - 1)) * s;
  x double precision := c * (1 - abs((h / 60.0) % 2 - 1));
  m double precision := l - c / 2.0;
  r double precision;
  g double precision;
  b double precision;
  ri int;
  gi int;
  bi int;
BEGIN
  IF h < 60 THEN
    r := c; g := x; b := 0;
  ELSIF h < 120 THEN
    r := x; g := c; b := 0;
  ELSIF h < 180 THEN
    r := 0; g := c; b := x;
  ELSIF h < 240 THEN
    r := 0; g := x; b := c;
  ELSIF h < 300 THEN
    r := x; g := 0; b := c;
  ELSE
    r := c; g := 0; b := x;
  END IF;

  ri := GREATEST(0, LEAST(255, round((r + m) * 255)::int));
  gi := GREATEST(0, LEAST(255, round((g + m) * 255)::int));
  bi := GREATEST(0, LEAST(255, round((b + m) * 255)::int));

  RETURN '#' || lpad(to_hex(ri), 2, '0') || lpad(to_hex(gi), 2, '0') || lpad(to_hex(bi), 2, '0');
END;
$$;

-- Picks the next unused turf color. Prefers a curated dark-map palette,
-- then falls back to golden-angle HSL so uniqueness scales past the palette.
CREATE OR REPLACE FUNCTION public.allocate_territory_color()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  palette text[] := ARRAY[
    '#2EE6C5', '#FF7A59', '#FFC14D', '#FF6B9D', '#8B9CFF', '#7DD3FC',
    '#F0ABFC', '#FB923C', '#A3E635', '#34D399', '#F472B6', '#60A5FA',
    '#FBBF24', '#A78BFA', '#4ADE80', '#FB7185', '#38BDF8', '#E879F9',
    '#F97316', '#22D3EE', '#C084FC', '#84CC16', '#F43F5E', '#818CF8',
    '#14B8A6', '#EAB308', '#EC4899', '#3B82F6', '#D946EF', '#10B981',
    '#EF4444', '#6366F1', '#06B6D4', '#CA8A04', '#DB2777', '#2563EB',
    '#7C3AED', '#059669', '#DC2626', '#4F46E5', '#0891B2', '#B45309',
    '#BE185D', '#1D4ED8', '#6D28D9', '#047857', '#B91C1C', '#4338CA',
    '#0E7490', '#A16207', '#9D174D', '#1E40AF', '#5B21B6', '#065F46',
    '#FCA5A5', '#93C5FD', '#FDE68A', '#C4B5FD', '#6EE7B7', '#FDA4AF',
    '#67E8F9', '#F0ABFC', '#FDBA74', '#BEF264', '#FDBA74', '#A5B4FC'
  ];
  candidate text;
  i int := 0;
  max_tries int := 4096;
BEGIN
  PERFORM pg_advisory_xact_lock(87214503);

  FOREACH candidate IN ARRAY palette LOOP
    IF NOT EXISTS (
      SELECT 1 FROM public.profiles p WHERE p.territory_color = lower(candidate)
    ) THEN
      RETURN lower(candidate);
    END IF;
  END LOOP;

  -- Unlimited unique colors via golden-angle walk in HSL space.
  i := (SELECT COUNT(*)::int FROM public.profiles);
  WHILE i < max_tries LOOP
    candidate := lower(public.hsl_to_hex(i * 137.508, 0.72, 0.58));
    IF NOT EXISTS (
      SELECT 1 FROM public.profiles p WHERE p.territory_color = candidate
    ) THEN
      RETURN candidate;
    END IF;
    i := i + 1;
  END LOOP;

  RAISE EXCEPTION 'unable to allocate unique territory_color';
END;
$$;

REVOKE ALL ON FUNCTION public.allocate_territory_color() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.allocate_territory_color() TO service_role;

-- Backfill existing profiles in created_at order for stable assignment.
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT id FROM public.profiles
    WHERE territory_color IS NULL
    ORDER BY created_at ASC, id ASC
  LOOP
    UPDATE public.profiles
    SET territory_color = public.allocate_territory_color()
    WHERE id = r.id;
  END LOOP;
END $$;

ALTER TABLE public.profiles
  ALTER COLUMN territory_color SET NOT NULL;

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_territory_color_key;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_territory_color_key UNIQUE (territory_color);

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_territory_color_format;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_territory_color_format
  CHECK (territory_color ~ '^#[0-9a-f]{6}$');

-- Lock color after assignment (users cannot steal another hue via UPDATE).
CREATE OR REPLACE FUNCTION public.profiles_lock_territory_color()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.territory_color IS DISTINCT FROM OLD.territory_color THEN
    NEW.territory_color := OLD.territory_color;
  END IF;
  IF NEW.territory_color IS NULL THEN
    NEW.territory_color := public.allocate_territory_color();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_lock_territory_color ON public.profiles;
CREATE TRIGGER profiles_lock_territory_color
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.profiles_lock_territory_color();

-- Assign a unique color on every new auth user.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, territory_color)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    public.allocate_territory_color()
  )
  ON CONFLICT (id) DO UPDATE
    SET display_name = EXCLUDED.display_name;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM anon;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM authenticated;

CREATE OR REPLACE VIEW public.territories_geojson
  WITH (security_invoker = true) AS
SELECT
  t.id,
  t.user_id,
  p.display_name,
  p.territory_color,
  ST_AsGeoJSON(t.geom) AS geojson,
  ST_Area(t.geom::geography) AS area_sqm,
  t.last_defended_at
FROM public.territories t
JOIN public.profiles p ON p.id = t.user_id;

GRANT SELECT ON public.territories_geojson TO authenticated;
