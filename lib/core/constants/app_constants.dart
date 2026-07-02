/// Shared numeric and timing constants across all features.
/// No magic numbers anywhere else in the codebase — always reference here.
abstract final class AppConstants {
  // ── Alarm ──────────────────────────────────────────────────────────
  static const int defaultSquatCount = 10;
  static const int outOfFramePenaltySeconds = 15;

  /// Hip-to-knee depth ratio below which a squat is rejected as partial
  static const double squatDepthThreshold = 0.6;

  /// Volume ramp-up step when user leaves frame (per penalty tick)
  static const double volumeRampStep = 0.15;

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
  static const double loopClosureRadiusMeters = 20.0;
  static const double minLoopAreaSqMeters = 50.0;
  static const Duration minRunDuration = Duration(minutes: 2);
  static const double minRunDistanceMeters = 200.0;
  static const Duration territoryDecayGracePeriod = Duration(days: 7);

  /// Rolling window size (GPS pings) for sustained-speed-cap checks —
  /// a single noisy ping should not invalidate a run.
  static const int speedRollingWindowSize = 6;

  /// RDP simplification epsilon (meters) applied to the run path before
  /// it's sent to Supabase as the capture polygon.
  static const double rdpSimplificationEpsilonMeters = 3.0;

  // ── Territory map ─────────────────────────────────────────────────
  static const double territoryMapMinZoom = 2.0;
  static const double territoryMapMaxZoom = 20.0;
  static const double territoryMapInitialZoom = 14.0;
  static const double territoryMapUserZoom = 16.5;

  /// Natural Earth shaded relief tiles — visible at low zoom where vector
  /// style layers are sparse.
  static const String territoryLowZoomTileUrl =
      'https://tiles.openfreemap.org/natural_earth/ne2sr/{z}/{x}/{y}.png';
  static const int territoryLowZoomTileMaxNativeZoom = 6;
}
