# Original User Request

## Initial Request — 2026-07-01T12:12:07Z

Implement the Territory Capture feature in the Awaken Flutter app. The application must support tracking runs, claiming territory by closing loops, merging and stealing territories, enforcing speed caps and GPS smoothing, daily territory decay with warning notifications, and displaying global/nearby leaderboards.

Working directory: c:\Users\afsan\Workspace\awaken
Integrity mode: benchmark

## Requirements

### R1. Track the Run & GPS Smoothing
- Implement real-time GPS tracking using the `geolocator` and `flutter_map` packages.
- Start and Stop controls must be accessible in the bottom third of the screen.
- Draw the active run path in real-time.
- Apply GPS path smoothing/filtering (e.g., Kalman filter or rolling average) and post-run RDP simplification.
- Implement an anti-cheat speed cap at 25 km/h. Invalidate runs where speed exceeds this limit for more than a few seconds.

### R2. Interactive Map UI/UX
- Implement a fully polished, responsive map interface using `flutter_map`.
- Provide smooth zoom in/zoom out animations, manual zoom buttons, and double-tap zoom options.
- Support "Follow Me" mode that auto-centers and rotates/tilts the camera smoothly as the user runs.
- Fit map bounds dynamically to show both the start point and the current active path, especially upon stopping or loading.
- Use high-quality dark tiles (e.g., CartoDB Dark Matter) for visual alignment with the dark-only app theme.

### R3. Claim & Expand Territory
- Verify loop closure: final GPS coordinate must be within 20 meters of the starting coordinate.
- Enforce constraints: the run must have lasted at least 2 minutes, covered at least 200 meters of cumulative distance, and enclosed a loop area of at least 50 square meters.
- Merge overlapping territories owned by the same user into a single continuous polygon.
- Support a swappable repository pattern: offline local storage (Memory/SharedPreferences) when signed out, and Supabase PostGIS when signed in.

### R4. Steal Rival Territory
- Intersecting rival territories must be updated dynamically: subtract the overlapping area from the rival's territory and add it to the active runner's territory.
- Color updates on the map and leaderboard must reflect the transaction instantly.

### R5. Territory Decay & Warnings
- Territories that are not defended (run through or near) within 7 days must shrink (e.g., using `ST_Buffer` negative offset) or decay.
- Automatically schedule and trigger warning notifications (via `flutter_local_notifications` package) 1-2 days before the decay grace period expires.

### R6. Leaderboards
- Provide two leaderboard views:
  1. A Global leaderboard ranking users by total owned territory area.
  2. A Nearby leaderboard showing users within the local geographic bounding box.
- Implement tab navigation or a bottom navigation bar to switch between the Dashboard, Territory Map, and Leaderboard.

## Acceptance Criteria

### UI, Map & Navigation
- [ ] A bottom navigation bar or tab view is added to easily switch between Dashboard, Territory Map, and Leaderboard screens.
- [ ] The Map UI features responsive, smooth gesture controls (pan, pinch-zoom, double-tap zoom) and clear, custom +/- zoom buttons.
- [ ] A toggle or mode exists to auto-center the map smoothly on the user's current GPS location.
- [ ] Territory overlays on the dark map are rendered with a neon glow effect using colors from `AppColors`.

### Run Tracking & Anti-Cheat
- [ ] Live path drawing displays on the map screen during an active run.
- [ ] Runs exceeding 25 km/h are flagged and do not result in territory capture.
- [ ] Run stats (timer, distance, area) are styled with `AwakenTypography` extension fonts.

### Claim & Steal Logic
- [ ] Successful loop closure (within 20m) creates a filled polygon on the map.
- [ ] If the new loop overlaps own territory, it merges into a single continuous polygon.
- [ ] If the loop overlaps a rival's territory, the rival's area is reduced by the overlapping geometry, and the user gains that area.
- [ ] Invalid loops (too small, too short, or not closed) save workout stats but do not modify territories.

### Storage & Syncing
- [ ] The app automatically swaps between local storage (when logged out) and Supabase database (when logged in).
- [ ] Multi-user concurrent capture calls are processed safely on the database without double-subtraction.

### Decay & Notifications
- [ ] Daily/nightly decay logic shrinks older territories and deletes empty ones.
- [ ] A local notification warning is triggered when a territory is 1-2 days away from starting to decay.
