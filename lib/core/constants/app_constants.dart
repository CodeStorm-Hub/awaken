import 'package:flutter/foundation.dart';

/// Shared numeric and timing constants across all features.
/// No magic numbers anywhere else in the codebase — always reference here.
abstract final class AppConstants {
  // ── Alarm ──────────────────────────────────────────────────────────
  static const int defaultSquatCount = 10;

  /// Out-of-frame audio ramp interval (shorter = more urgent).
  static const int outOfFramePenaltySeconds = 8;

  /// Hip-to-knee depth ratio below which a squat is rejected as partial
  static const double squatDepthThreshold = 0.6;

  /// Max left/right shoulder height delta (normalized by torso) before bad form.
  static const double maxShoulderTiltRatio = 0.18;

  /// Volume ramp-up step when user leaves frame (per penalty tick)
  static const double volumeRampStep = 0.15;

  /// Max tap-counted reps when camera permission is denied (accessibility).
  /// Further taps require enabling the camera via Settings.
  static const int accessibilityMaxTapReps = 3;

  /// Unresolved alarm trigger older than this incurs a bailout penalty.
  static const Duration bailoutWindow = Duration(hours: 2);

  /// Tax reveal stamp duration on active alarm entry.
  static const Duration taxRevealDuration = Duration(milliseconds: 1200);

  /// Auto-pause run when speed stays near zero for this long.
  static const Duration runGracePauseDelay = Duration(seconds: 8);

  /// Speed (m/s) at or below which grace pause may arm.
  static const double runGracePauseSpeedMps = 0.4;

  /// Explored fog cell size (~70 m).
  static const double fogCellDegrees = 0.00065;

  /// Leaderboard "Around you" window half-width (ranks myRank±N).
  static const int leaderboardNeighborhoodRadius = 5;

  // ── Layout ────────────────────────────────────────────────────────
  static const double screenPaddingH = 20.0;
  static const double screenPaddingV = 24.0;
  static const double cardRadius = 24.0;
  static const double chipRadius = 16.0;
  static const double borderRadius = 12.0;
  static const double ringStrokeWidth = 10.0;

  // ── Animation durations ───────────────────────────────────────────
  static const Duration shortAnim = Duration(milliseconds: 150);
  static const Duration mediumAnim = Duration(milliseconds: 300);
  static const Duration longAnim = Duration(milliseconds: 600);
  static const Duration scanLineDuration = Duration(milliseconds: 2000);
  static const Duration streakBadgeDuration = Duration(milliseconds: 500);
  static const Duration floatUpStagger = Duration(milliseconds: 120);
  static const Duration clockTickInterval = Duration(seconds: 1);

  // ── Animation delays (staggered success reveals) ──────────────────
  static const Duration floatUpDelay0 = Duration(milliseconds: 100);
  static const Duration floatUpDelay1 = Duration(milliseconds: 220);
  static const Duration floatUpDelay2 = Duration(milliseconds: 340);
  static const Duration floatUpDelay3 = Duration(milliseconds: 460);

  // ── Glow effects ──────────────────────────────────────────────────
  static const double glowBlurRadius = 12.0;
  static const double skeletonStrokeWidth = 2.5;
  static const double skeletonJointRadius = 4.0;

  // ── Territory capture: anti-cheat & loop validation ────────────────
  /// Single source of truth for the speed cap — the user story's own
  /// acceptance criteria (>25 km/h) and "Drive-by Cheat" refinement
  /// (20–25 km/h) disagree; resolved once here.
  static const double maxRunSpeedKmh = 25.0;
  static const double loopClosureRadiusMeters = 50.0;
  static const double minLoopAreaSqMeters = 50.0;

  /// Production: 2 minutes. Debug/emulator: 45s so GPS sims can finish quickly.
  static Duration get minRunDuration =>
      kDebugMode ? const Duration(seconds: 45) : const Duration(minutes: 2);

  static const double minRunDistanceMeters = 200.0;

  /// Per-loop path length minimum — below session [minRunDistanceMeters] so
  /// a single valid loop can be captured without requiring the overrun tail.
  static const double minLoopSegmentDistanceMeters = 150.0;

  /// Runner must travel this far from the segment anchor before a return
  /// within [loopClosureRadiusMeters] counts as closure (GPS drift guard).
  static const double loopClosureGraceMeters = 50.0;

  /// After closing a loop, runner must exit this radius before another
  /// closure at the same anchor can arm (prevents double-counting).
  static const double loopExitRadiusMeters = 30.0;

  /// Minimum GPS fixes in a segment before closure is accepted (~30 m at 5 m
  /// distance filter).
  static const int minLoopSegmentPointCount = 6;

  /// Anti-farming cap on territory captures per run session.
  static const int maxLoopsPerSession = 5;
  static const Duration territoryDecayGracePeriod = Duration(days: 7);

  /// Rolling window size (GPS pings) for sustained-speed-cap checks —
  /// a single noisy ping should not invalidate a run.
  static const int speedRollingWindowSize = 6;

  /// RDP simplification epsilon (meters) applied to the run path before
  /// it's sent to Supabase as the capture polygon.
  static const double rdpSimplificationEpsilonMeters = 3.0;

  // ── Territory map ─────────────────────────────────────────────────
  static const double territoryMapMinZoom = 2.0;

  /// Client overzoom cap — OpenMapTiles vector data is native to z14; z18 is
  /// the comfortable overzoom limit per OpenMapTiles guidance.
  static const double territoryMapMaxZoom = 18.0;
  static const double territoryMapInitialZoom = 14.0;
  static const double territoryMapUserZoom = 16.5;

  /// Native max zoom of the OpenFreeMap / OpenMapTiles vector source.
  static const int territoryVectorTileMaxZoom = 14;

  /// Max GPS points drawn on the run trail overlay (full path kept for capture).
  static const int territoryTrailDisplayMaxPoints = 500;

  /// Below this zoom, territory polygon glow rings are skipped (core only).
  static const double territoryPolygonGlowMinZoom = 12.0;
}
