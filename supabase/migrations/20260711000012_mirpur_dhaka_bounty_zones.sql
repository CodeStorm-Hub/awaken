-- Seed bounty zones around Mirpur, Dhaka (WGS:4326).
-- Small runnable polygons (~200–300 m) with staggered multipliers.
-- Expires ~90 days from apply time so they stay active for dogfooding.

INSERT INTO public.bounty_zones (label, multiplier, geom, expires_at)
VALUES
  (
    'MIRPUR-10 CIRCLE',
    2.5,
    ST_GeomFromText(
      'POLYGON((90.3672 23.8058, 90.3702 23.8058, 90.3702 23.8082, 90.3672 23.8082, 90.3672 23.8058))',
      4326
    ),
    now() + interval '90 days'
  ),
  (
    'SHER-E-BANGLA STADIUM',
    3.0,
    ST_GeomFromText(
      'POLYGON((90.3618 23.8050, 90.3652 23.8050, 90.3652 23.8080, 90.3618 23.8080, 90.3618 23.8050))',
      4326
    ),
    now() + interval '90 days'
  ),
  (
    'MIRPUR DOHS',
    2.0,
    ST_GeomFromText(
      'POLYGON((90.3735 23.8205, 90.3768 23.8205, 90.3768 23.8232, 90.3735 23.8232, 90.3735 23.8205))',
      4326
    ),
    now() + interval '90 days'
  ),
  (
    'KAZIPARA',
    1.8,
    ST_GeomFromText(
      'POLYGON((90.3640 23.8152, 90.3670 23.8152, 90.3670 23.8178, 90.3640 23.8178, 90.3640 23.8152))',
      4326
    ),
    now() + interval '90 days'
  ),
  (
    'MIRPUR-1 / SONY',
    2.2,
    ST_GeomFromText(
      'POLYGON((90.3595 23.8028, 90.3625 23.8028, 90.3625 23.8052, 90.3595 23.8052, 90.3595 23.8028))',
      4326
    ),
    now() + interval '90 days'
  ),
  (
    'MIRPUR-11 / 12',
    1.75,
    ST_GeomFromText(
      'POLYGON((90.3755 23.8088, 90.3785 23.8088, 90.3785 23.8114, 90.3755 23.8114, 90.3755 23.8088))',
      4326
    ),
    now() + interval '90 days'
  ),
  (
    'SECTION-2 PARK',
    2.0,
    ST_GeomFromText(
      'POLYGON((90.3660 23.8115, 90.3690 23.8115, 90.3690 23.8140, 90.3660 23.8140, 90.3660 23.8115))',
      4326
    ),
    now() + interval '90 days'
  );

-- Retire the sample Toronto downtown bounty so the map focuses on Dhaka.
UPDATE public.bounty_zones
SET expires_at = now() - interval '1 hour'
WHERE label = 'DOWNTOWN BOUNTY'
  AND ST_X(ST_Centroid(geom)) < 0;
