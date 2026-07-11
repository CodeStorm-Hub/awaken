-- Replace Mirpur square bounty boxes with road-following city-block polygons
-- so runners can loop along actual streets to enclose the bounty.

-- Retire previous rectangular Mirpur seeds (and any leftover sample).
UPDATE public.bounty_zones
SET expires_at = now() - interval '1 hour'
WHERE expires_at > now()
  AND (
    label IN (
      'MIRPUR-10 CIRCLE',
      'SHER-E-BANGLA STADIUM',
      'MIRPUR DOHS',
      'KAZIPARA',
      'MIRPUR-1 / SONY',
      'MIRPUR-11 / 12',
      'SECTION-2 PARK',
      'DOWNTOWN BOUNTY'
    )
    OR ST_X(ST_Centroid(geom)) BETWEEN 90.35 AND 90.39
  );

-- Road-aligned rings (lon lat). Vertices sit on approximate Mirpur street
-- intersections so the outline reads as a runnable block, not a square.

INSERT INTO public.bounty_zones (label, multiplier, geom, expires_at)
VALUES
  -- Stadium block: follows perimeter roads around Sher-e-Bangla NSC
  (
    'SHER-E-BANGLA STADIUM',
    3.0,
    ST_GeomFromText(
      'POLYGON((
        90.36155 23.80470,
        90.36310 23.80435,
        90.36485 23.80455,
        90.36555 23.80540,
        90.36570 23.80655,
        90.36520 23.80770,
        90.36390 23.80825,
        90.36220 23.80810,
        90.36130 23.80720,
        90.36115 23.80585,
        90.36155 23.80470
      ))',
      4326
    ),
    now() + interval '90 days'
  ),
  -- Mirpur-10: irregular ring around the circle / Begum Rokeya junction
  (
    'MIRPUR-10 CIRCLE',
    2.5,
    ST_GeomFromText(
      'POLYGON((
        90.36680 23.80620,
        90.36820 23.80555,
        90.36970 23.80570,
        90.37055 23.80660,
        90.37070 23.80770,
        90.36990 23.80855,
        90.36840 23.80880,
        90.36700 23.80835,
        90.36640 23.80740,
        90.36680 23.80620
      ))',
      4326
    ),
    now() + interval '90 days'
  ),
  -- Mirpur-1 / Sony Cinema block along Mirpur Road
  (
    'MIRPUR-1 / SONY',
    2.2,
    ST_GeomFromText(
      'POLYGON((
        90.35920 23.80260,
        90.36070 23.80225,
        90.36210 23.80255,
        90.36265 23.80345,
        90.36250 23.80455,
        90.36140 23.80515,
        90.35990 23.80500,
        90.35905 23.80410,
        90.35920 23.80260
      ))',
      4326
    ),
    now() + interval '90 days'
  ),
  -- Kazipara residential block (offset street grid)
  (
    'KAZIPARA',
    1.8,
    ST_GeomFromText(
      'POLYGON((
        90.36370 23.81490,
        90.36540 23.81455,
        90.36680 23.81500,
        90.36725 23.81600,
        90.36670 23.81720,
        90.36520 23.81755,
        90.36385 23.81710,
        90.36335 23.81600,
        90.36370 23.81490
      ))',
      4326
    ),
    now() + interval '90 days'
  ),
  -- Section-2 park / lake-side block
  (
    'SECTION-2 PARK',
    2.0,
    ST_GeomFromText(
      'POLYGON((
        90.36570 23.81120,
        90.36740 23.81085,
        90.36890 23.81130,
        90.36935 23.81240,
        90.36870 23.81350,
        90.36710 23.81385,
        90.36580 23.81330,
        90.36535 23.81220,
        90.36570 23.81120
      ))',
      4326
    ),
    now() + interval '90 days'
  ),
  -- Mirpur DOHS grid block
  (
    'MIRPUR DOHS',
    2.0,
    ST_GeomFromText(
      'POLYGON((
        90.37320 23.82030,
        90.37480 23.81995,
        90.37640 23.82040,
        90.37695 23.82140,
        90.37640 23.82255,
        90.37470 23.82295,
        90.37320 23.82240,
        90.37275 23.82130,
        90.37320 23.82030
      ))',
      4326
    ),
    now() + interval '90 days'
  ),
  -- Mirpur-11/12 street block
  (
    'MIRPUR-11 / 12',
    1.75,
    ST_GeomFromText(
      'POLYGON((
        90.37520 23.80850,
        90.37680 23.80815,
        90.37830 23.80860,
        90.37880 23.80960,
        90.37820 23.81080,
        90.37660 23.81120,
        90.37520 23.81070,
        90.37475 23.80960,
        90.37520 23.80850
      ))',
      4326
    ),
    now() + interval '90 days'
  );
