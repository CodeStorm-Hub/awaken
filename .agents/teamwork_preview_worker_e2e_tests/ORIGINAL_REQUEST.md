## 2026-07-01T12:25:38Z
You are the Worker agent responsible for Milestones 2-5: E2E Test Cases Implementation (Tiers 1-4).
Your working directory is: c:\Users\afsan\Workspace\awaken\.agents\teamwork_preview_worker_e2e_tests

Your task is to implement the comprehensive set of E2E tests in c:\Users\afsan\Workspace\awaken\test\territory\territory_e2e_test.dart.
You must satisfy the following thresholds exactly:
- Tier 1 (Feature Coverage): 35 tests (5 tests for each of the 7 features F1-F7)
- Tier 2 (Boundary & Corner Cases): 35 tests (5 tests for each of the 7 features F1-F7)
- Tier 3 (Cross-Feature Combinations): 7 tests (interactions)
- Tier 4 (Real-World Application Scenarios): 5 tests (E2E workflows)
Total: 82 tests!

Features (N = 7):
- F1: GPS Tracking & Kalman Smoothing
- F2: Speed Cap Anti-Cheat
- F3: RDP Simplification
- F4: Loop Claiming & Validation (start/end proximity, min duration, min distance, min area)
- F5: Territory Merging & Stealing (self-union, rival difference, sliver cleanup)
- F6: Territory Decay & Warnings (negative buffer, warning notification triggers)
- F7: Leaderboards & Realtime Sync (global, nearby, live updates)

Please implement the following test cases:

Tier 1 (Feature Coverage):
1. F1: Kalman filter stabilizes small GPS jitter.
2. F1: Kalman filter ignores huge GPS jumps (low accuracy/high measurement variance).
3. F1: Kalman filter follows consistent coordinate stream.
4. F1: Active run path is recorded correctly with smoothed coordinates.
5. F1: Distance calculation updates dynamically during run tracking using smoothed path.
6. F2: Slow run (e.g. 8 km/h) is not flagged as over-speed.
7. F2: Sustained high speed (e.g. 30 km/h) over 6 points is flagged as over-speed.
8. F2: Run is invalidated with `invalidatedSpeedCap` when sustained over-speed is detected.
9. F2: Short-lived speed spike (1 point at 40 km/h, 5 points at 8 km/h) does NOT trigger sustained over-speed.
10. F2: Speed cap check resets properly on start of a new run session.
11. F3: Straight collinear path is simplified from N points to 2 points.
12. F3: Circular path is simplified but retains main shape (within epsilon).
13. F3: Zig-zag path with small deviations (under epsilon 3m) is flattened to a straight line.
14. F3: Zig-zag path with large deviations (over epsilon 3m) retains intermediate vertices.
15. F3: Simplified vertices are used for database capture.
16. F4: Closed loop (start/end distance <= 20m) with min duration (2m) and min distance (200m) and area (>50m²) is valid.
17. F4: Loop not closed (start/end distance > 20m) is classified as normal workout (not claimed).
18. F4: Closed loop but too short duration (<2m) is classified as `invalidatedTooShort`.
19. F4: Closed loop but too short distance (<200m) is classified as `invalidatedTooShort`.
20. F4: Closed loop but too small area (<50 m²) is rejected as `invalidatedTooSmall`.
21. F5: Claims overlapping own territory -> merges into a single polygon (ST_Union).
22. F5: Claims overlapping rival territory -> rival territory is reduced (ST_Difference).
23. F5: Rival territory is split into multiple polygons if user's claim cuts through the middle.
24. F5: Sliver cleanup: rival territory area reduced to < 1.0 m² is deleted.
25. F5: Multi-rival stealing: user's claim intersects and steals from multiple rivals in a single capture.
26. F6: Territory last defended within 7 days does not decay.
27. F6: Territory last defended > 7 days decays by shrinking 5 meters (ST_Buffer negative offset).
28. F6: Decay warning triggers when last defended is 5-6 days ago (1-2 days before decay).
29. F6: Warning triggers a local push notification on app launch.
30. F6: Defending a territory (running through/near it) updates `last_defended_at` and resets decay timer.
31. F7: Global leaderboard ranks users correctly by total area owned.
32. F7: Nearby leaderboard ranks users within 5000m radius of current viewer location.
33. F7: Realtime stream notifies listeners when territory map updates.
34. F7: Leaderboard provider automatically invalidates and refetches when map updates.
35. F7: Tab navigation switches between map, run screen, and leaderboard UI smoothly (verify UI screens and tabs can switch).

Tier 2 (Boundary & Corner Cases):
36. F1: Empty coordinates list (run starts and stops immediately with no fixes).
37. F1: Single coordinate fix (run starts, gets one fix, stops).
38. F1: Two identical coordinate fixes (runner is stationary, distance should be 0).
39. F1: High noise Kalman filter adaptation (very noisy track eventually stabilizes).
40. F1: Distance filter boundary: coordinates closer than 5 meters are filtered by Geolocator settings.
41. F2: Exact boundary speed of 25.0 km/h is NOT flagged as over-speed.
42. F2: Exact boundary speed of 25.01 km/h is flagged as over-speed.
43. F2: Speed cap with exactly 5 over-speed points (rolling window needs 6 points) - not flagged.
44. F2: Speed cap with exactly 6 over-speed points - flagged.
45. F2: Extremely high speed (e.g., plane speed 500 km/h) instantly flags over-speed when rolling window is satisfied.
46. F3: Simplification of empty path list returns empty list.
47. F3: Simplification of a single point returns that point.
48. F3: Simplification of exactly two points returns those two points unchanged.
49. F3: Epsilon boundary: vertex deviation of exactly 2.99m is simplified away, exactly 3.01m is kept.
50. F3: Simplification of closed loop: start and end vertices are preserved.
51. F4: Start/end distance of exactly 20.0m is closed.
52. F4: Start/end distance of exactly 20.01m is not closed.
53. F4: Run duration of exactly 2 minutes (120 seconds) is valid.
54. F4: Run duration of exactly 119 seconds is invalid.
55. F4: Cumulative distance of exactly 200.0m is valid.
56. F4: Cumulative distance of exactly 199.9m is invalid.
57. F5: Capturing a loop completely enclosing a rival's territory (rival is fully consumed and deleted).
58. F5: Capturing a loop completely inside an existing own territory (no change in total area, merges cleanly).
59. F5: Rival territory reduced to exactly 1.0 m² is kept.
60. F5: Rival territory reduced to exactly 0.99 m² is deleted (sliver cleanup).
61. F5: Merging non-overlapping user territories (remain as separate polygons).
62. F6: Exact boundary: age of exactly 7 days (168 hours) does NOT trigger decay.
63. F6: Exact boundary: age of exactly 7.01 days triggers decay.
64. F6: Decayed territory shrinking to 0 m² or empty is deleted.
65. F6: Warning boundary: warning triggers at exactly 1.99 days before decay, but not at 2.01 days.
66. F6: Touching defense within exactly 20.0m of territory boundary updates defense timestamp.
67. F7: Empty leaderboard (no territories registered).
68: F7: User outside the 5000m nearby radius is excluded from Nearby leaderboard.
69. F7: Exact boundary: user at exactly 5000.0m from viewer is included in Nearby leaderboard.
70. F7: Exact boundary: user at exactly 5000.1m is excluded.
71. F7: Realtime sync updates multiple screens concurrently (Leaderboard and Map both react to change).

Tier 3 (Cross-Feature Combinations):
72. F1+F3+F4: Noisy GPS stream gets Kalman-smoothed and simplified, closing a loop that passes validation.
73. F2+F4+F5: Run has short over-speed spikes but doesn't trigger sustained speed cap, closes loop, and successfully merges with own territory.
74. F4+F5+F7: User closes valid loop, steals rival territory, and instantly rises in the Nearby leaderboard.
75. F4+F6+F7: Decayed territory shrinks, dropping a user in the leaderboard; user runs through it, defending it, resetting decay, and updating the leaderboard.
76. F3+F4+F5+F6: Running a loop to defend and expand a territory that is about to decay, simplifying the vertices, and performing self-union.
77. F2+F4+F6: Speed cap invalidates a loop capture run, meaning territory does not get defended and continues to decay.
78. F1+F2+F5+F7: Smoothing prevents over-speed flag by filtering jitter, allowing loop capture that steals rival and shifts leaderboard live.

Tier 4 (Real-World Application Scenarios):
79. E2E Scenario 1: Standard loop capture updates map and leaderboards.
80. E2E Scenario 2: Inactive decay triggers warnings and shrinks size.
81. E2E Scenario 3: Rivalry Battle. User A claims territory. User B runs a loop cutting User A's territory in half (stealing). User A runs a new loop to merge and retake the stolen area. Verify leaderboard and map updates.
82. E2E Scenario 4: Cheating runner. User starts run in vehicle (exceeding 25 km/h), slows down to jog, then speeds up again. Speed cap invalidates run. No territory claimed.
83. E2E Scenario 5: Defense Run. User has decaying territory. User runs a path (not a loop) through/near their territory to defend it. Verify `last_defended_at` updates, warning disappears, and decay is avoided.
