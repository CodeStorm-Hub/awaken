# Territory Capture Feature Implementation Plan

This plan details the milestone decomposition, dependencies, verification strategy, and team roles for implementing the Territory Capture feature in the Awaken app.

## Milestone Decompositions

| Milestone | Name | Objective | Files Involved | Verification |
|---|---|---|---|---|
| **M1** | Test Infra & Suite Setup | Create the E2E test suite covering Tiers 1-4 (Feature, Boundary, Combinations, Real-World) and publish `TEST_READY.md`. | `test/e2e/`, `TEST_READY.md`, `TEST_INFRA.md` | Execute E2E runner. |
| **M2** | DB Schema & Spatial Math | Set up PostGIS tables, indexes, and database RPCs (`capture_territory`, `touch_territory_defense`) with concurrency safety. | `supabase/migrations/` (or SQL script executed on DB) | Execute SQL tests, verify area calculation and multi-rival contestation. |
| **M3** | Swappable Repository | Create local repository fallback (SharedPreferences/Memory) for signed-out state and dynamic repository swapper provider. | `lib/features/territory/data/repositories/`, `lib/features/territory/presentation/providers/territory_providers.dart` | Unit tests for swapper reacting to auth state. |
| **M4** | Live Map Updates & Steal | Ensure map overlays listen to Realtime changes, displaying color updates instantly when rival territory is stolen. | `lib/features/territory/presentation/screens/territory_run_screen.dart`, `lib/features/territory/presentation/widgets/territory_polygon_layer.dart` | Simulate two users stealing from each other and verify live visual update. |
| **M5** | Decay Warnings & Notif | Schedule local notifications (reusing alarm notification plumbing) 1-2 days before the 7-day decay grace period expires. | `lib/core/services/territory_decay_notification_service.dart`, database cron tasks | Trigger decay check query and assert notification fires correctly. |
| **M6** | UI Refinements & Leaderboard | Polish the Map UI: neon glow overlays, +/- manual zoom buttons, double-tap zoom, Follow Me mode, and Nearby/Global leaderboard toggle. | `lib/features/territory/presentation/screens/territory_leaderboard_screen.dart`, map widgets | Visual verification in emulator/device, verify toggle logic. |
| **M7** | E2E Validation & Hardening | Run all test tiers, resolve failures, run adversarial white-box coverage hardening (Tier 5) with Challengers. | Entire territory feature | 100% E2E test suite pass + Challenger-confirmed coverage. |

## Team Roster & Archetypes
- **teamwork_preview_explorer**: Analyzes code, details database and repository implementations, highlights potential issues.
- **teamwork_preview_worker**: Implements dart files, configures database tables/RPCs via migration SQL.
- **teamwork_preview_reviewer**: Performs static analysis check, code review, correctness review.
- **teamwork_preview_challenger**: Generates stress-test scripts and test cases for concurrency and edge cases.
- **teamwork_preview_auditor**: Verifies implementation integrity, flags hardcoded or fake implementations.
