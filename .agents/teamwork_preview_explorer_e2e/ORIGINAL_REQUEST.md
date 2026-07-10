## 2026-07-01T12:14:54Z
Explore the codebase of the Awaken Flutter app to understand the Territory Capture feature.
Your working directory is: c:\Users\afsan\Workspace\awaken\.agents\teamwork_preview_explorer_e2e
Identify:
1. The file layout and structure of the territory capture feature (domain entities, repositories, data sources, providers, widgets, screens, etc.).
2. The mechanism for GPS tracking/smoothing (Kalman filter, RDP simplifier), Speed Cap validation, Loop closure checking, territory merging, rival stealing, territory decay & warnings, and Leaderboard (Global & Nearby) views.
3. How dependencies like Supabase, Geolocator, flutter_map, and flutter_local_notifications are wired and can be mocked.
4. How standard tests are structured and run in the project, and how we should write E2E tests that can run headlessly (e.g., standard Dart unit/integration tests with fully mocked layers, or Flutter integration tests).
5. Produce a detailed handoff/analysis report at c:\Users\afsan\Workspace\awaken\.agents\teamwork_preview_explorer_e2e\analysis.md summarizing your findings.
