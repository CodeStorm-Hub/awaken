---
globs:
  - "lib/features/territory/**/*.dart"
---

# Territory Capture & Mapping Guidelines
- Territory capture uses GPS run tracking with vector map layers (`vector_map_tiles`).
- Route paths must be filtered via Kalman filtering (`GpsKalmanFilter`) and simplified via RDP algorithm before validation.
- Active run tracking is persistent; do not stop or prompt users about GPS tracking on tab switches (indicate via red badge).
- Closed path loops are verified using `RunValidationService`.
- Submission happens through `TerritoryRepository` (Supabase if authenticated, else offline stub).
