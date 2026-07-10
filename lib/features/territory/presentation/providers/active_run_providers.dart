import 'dart:async';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/features/territory/data/datasources/pending_capture_queue.dart';
import 'package:awaken/features/territory/domain/entities/capture_result_entity.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/loop_segment_entity.dart';
import 'package:awaken/features/territory/domain/entities/run_track_entity.dart';
import 'package:awaken/features/territory/domain/services/geo_utils.dart';
import 'package:awaken/features/territory/domain/services/gps_kalman_filter.dart';
import 'package:awaken/features/territory/domain/services/location_permission_helper.dart';
import 'package:awaken/features/territory/domain/services/loop_segment_extractor.dart';
import 'package:awaken/features/territory/domain/services/rdp_simplifier.dart';
import 'package:awaken/features/territory/domain/services/run_validation_service.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum RunSessionStatus { idle, requestingPermission, tracking, finishing, finished, error }

/// Coarse bucketing of `Position.accuracy` (meters) for the run HUD's GPS
/// quality chip. Thresholds are typical of consumer GPS/GNSS fixes, not tied
/// to any anti-cheat constant — this is a UX signal, not a validation rule.
enum GpsQuality { unknown, good, fair, poor }

GpsQuality gpsQualityFromAccuracy(double? accuracyMeters) {
  if (accuracyMeters == null) return GpsQuality.unknown;
  if (accuracyMeters <= 8) return GpsQuality.good;
  if (accuracyMeters <= 20) return GpsQuality.fair;
  return GpsQuality.poor;
}

class ActiveRunState {
  const ActiveRunState({
    this.status = RunSessionStatus.idle,
    this.points = const [],
    this.distanceMeters = 0,
    this.elapsed = Duration.zero,
    this.isOverSpeed = false,
    this.gpsAccuracyMeters,
    this.pendingLoops = const [],
    this.currentSegmentAnchorIndex = 0,
    this.result,
    this.sessionCaptureResult,
    this.errorMessage,
  });

  final RunSessionStatus status;
  final List<GeoPointEntity> points;
  final double distanceMeters;
  final Duration elapsed;

  /// True when the most recent rolling-window check found sustained
  /// over-speed — drives a live "vehicle detected" HUD warning.
  final bool isOverSpeed;

  /// `Position.accuracy` (meters) of the most recent GPS fix — drives the
  /// HUD's GPS quality chip. Null before the first fix arrives.
  final double? gpsAccuracyMeters;

  /// Loops detected live during the run — finalized on Stop.
  final List<LoopSegmentEntity> pendingLoops;

  /// Anchor index for the active segment (HUD "to segment start" distance).
  final int currentSegmentAnchorIndex;

  final RunTrackEntity? result;
  final SessionCaptureResultEntity? sessionCaptureResult;
  final String? errorMessage;

  ActiveRunState copyWith({
    RunSessionStatus? status,
    List<GeoPointEntity>? points,
    double? distanceMeters,
    Duration? elapsed,
    bool? isOverSpeed,
    double? gpsAccuracyMeters,
    List<LoopSegmentEntity>? pendingLoops,
    int? currentSegmentAnchorIndex,
    RunTrackEntity? result,
    SessionCaptureResultEntity? sessionCaptureResult,
    String? errorMessage,
  }) {
    return ActiveRunState(
      status: status ?? this.status,
      points: points ?? this.points,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      elapsed: elapsed ?? this.elapsed,
      isOverSpeed: isOverSpeed ?? this.isOverSpeed,
      gpsAccuracyMeters: gpsAccuracyMeters ?? this.gpsAccuracyMeters,
      pendingLoops: pendingLoops ?? this.pendingLoops,
      currentSegmentAnchorIndex:
          currentSegmentAnchorIndex ?? this.currentSegmentAnchorIndex,
      result: result ?? this.result,
      sessionCaptureResult: sessionCaptureResult ?? this.sessionCaptureResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Owns the full GPS run-tracking lifecycle: permission, live position
/// stream, Kalman smoothing, rolling speed-cap anti-cheat, and — on
/// stop — classification + territory capture.
///
/// Not reset by [resetAlarmSession] when an alarm overlay opens — only
/// explicit `reset()` (run discard) or `finishRun()` completion clears state.
///
/// Deliberately NOT `autoDispose`: an in-flight `finishRun()` awaits a
/// Supabase round-trip, and autoDispose can tear the notifier down mid-await
/// if watcher count transiently hits zero during a rebuild, silently
/// orphaning the final `state = ...` write (and with it, the finished-state
/// transition the UI listens for). Instead, navigating away from the run
/// screen while tracking is intercepted (see `TerritoryRunScreen`'s
/// `PopScope`) and explicitly calls `reset()`, which is what actually stops
/// the position stream and timer — that's the real fix for the leak this
/// used to guard against, without the orphaned-future risk.
class ActiveRunNotifier extends Notifier<ActiveRunState> {
  StreamSubscription<Position>? _positionSubscription;
  Timer? _tickTimer;
  final GpsKalmanFilter _kalmanFilter = GpsKalmanFilter();
  DateTime? _startTime;
  bool _sawSustainedOverSpeed = false;
  LoopClosureTracker? _loopTracker;

  @override
  ActiveRunState build() {
    ref.onDispose(() {
      _positionSubscription?.cancel();
      _tickTimer?.cancel();
    });
    return const ActiveRunState();
  }

  Future<void> startRun() async {
    state = const ActiveRunState(status: RunSessionStatus.requestingPermission);

    try {
      await LocationPermissionHelper.ensureLocationAccess(
        serviceDisabledMessage: 'Turn on location services to start a territory run.',
        permissionDeniedMessage: 'Allow location access so we can track your run.',
      );
    } on LocationAccessException catch (e) {
      state = state.copyWith(status: RunSessionStatus.error, errorMessage: e.message);
      return;
    }

    _kalmanFilter.reset();
    _sawSustainedOverSpeed = false;
    _loopTracker = LoopClosureTracker();
    _startTime = clock.now();
    ref.read(territoryRunGpsKeepAliveProvider.notifier).state = true;
    ref.read(runOwnsHighAccuracyGpsProvider.notifier).state = true;
    state = const ActiveRunState(status: RunSessionStatus.tracking);

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime == null) return;
      state = state.copyWith(elapsed: clock.now().difference(_startTime!));
    });

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _runLocationSettings(),
    ).listen(
      _onPosition,
      onError: (Object error, StackTrace stackTrace) {
        // Surface FGS / permission failures instead of an unhandled
        // EventChannel PlatformException that leaves the run stuck.
        _tickTimer?.cancel();
        _positionSubscription = null;
        ref.read(runOwnsHighAccuracyGpsProvider.notifier).state = false;
        state = state.copyWith(
          status: RunSessionStatus.error,
          errorMessage:
              'Location tracking failed. Check that location permission is allowed.',
        );
      },
    );
  }

  LocationSettings _runLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Awaken territory run',
          notificationText: 'Tracking your GPS path for territory capture',
          enableWakeLock: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.fitness,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );
  }

  void _onPosition(Position position) {
    if (state.status != RunSessionStatus.tracking) return;

    final (smoothedLat, smoothedLng) = _kalmanFilter.filter(
      position.latitude,
      position.longitude,
      position.accuracy,
    );

    final point = GeoPointEntity(
      latitude: smoothedLat,
      longitude: smoothedLng,
      timestamp: position.timestamp,
    );

    final updatedPoints = [...state.points, point];
    final overSpeed = RunValidationService.isSustainedOverSpeed(updatedPoints);
    if (overSpeed) _sawSustainedOverSpeed = true;

    var pendingLoops = state.pendingLoops;
    var anchorIndex = state.currentSegmentAnchorIndex;

    final tracker = _loopTracker;
    if (tracker != null &&
        pendingLoops.length < AppConstants.maxLoopsPerSession) {
      final closed = tracker.evaluate(
        updatedPoints,
        gpsAccuracyMeters: position.accuracy,
      );
      if (closed != null) {
        pendingLoops = [...pendingLoops, closed];
        anchorIndex = tracker.anchorIndex;
      }
    }

    state = state.copyWith(
      points: updatedPoints,
      distanceMeters: GeoUtils.pathDistanceMeters(updatedPoints),
      isOverSpeed: overSpeed,
      gpsAccuracyMeters: position.accuracy,
      pendingLoops: pendingLoops,
      currentSegmentAnchorIndex: anchorIndex,
    );
  }

  /// Stops tracking, classifies the run, records it, and — if valid loop
  /// segments were detected — calls capture RPC for each. Always persists the
  /// run (closed or not) per Story #2's "counts as a normal workout" rule.
  Future<void> finishRun() async {
    _positionSubscription?.cancel();
    _tickTimer?.cancel();
    ref.read(runOwnsHighAccuracyGpsProvider.notifier).state = false;
    if (state.status != RunSessionStatus.tracking) return;

    state = state.copyWith(status: RunSessionStatus.finishing);

    final rawPoints = state.points;
    final simplifiedFullPath = rawPoints.length < 3
        ? rawPoints
        : RdpSimplifier.simplify(rawPoints, AppConstants.rdpSimplificationEpsilonMeters);

    // Authoritative re-extraction on raw points (RDP must not shift closure).
    final loopSegments = RunValidationService.extractLoopSegments(rawPoints);

    var outcome = RunValidationService.classify(
      points: simplifiedFullPath,
      distanceMeters: state.distanceMeters,
      duration: state.elapsed,
      wasInvalidatedBySpeed: _sawSustainedOverSpeed,
      loopSegments: loopSegments,
    );

    final repo = ref.read(territoryRepositoryProvider);
    SessionCaptureResultEntity? sessionCaptureResult;

    try {
      if (outcome == RunOutcome.territoryClaimed && loopSegments.isNotEmpty) {
        final captureResults = <CaptureResultEntity>[];
        var rejectedTooSmall = 0;

        for (final segment in loopSegments) {
          final simplifiedSegment = segment.points.length < 3
              ? segment.points
              : RdpSimplifier.simplify(
                  segment.points,
                  AppConstants.rdpSimplificationEpsilonMeters,
                );
          try {
            final result = await repo.captureTerritory(simplifiedSegment);
            captureResults.add(result);
          } on PostgrestException catch (error) {
            if (_isLoopTooSmallRejection(error)) {
              rejectedTooSmall++;
            } else {
              rethrow;
            }
          } on Exception catch (error) {
            if (_isLoopTooSmallRejectionMessage(error.toString())) {
              rejectedTooSmall++;
            } else {
              rethrow;
            }
          }
        }

        if (captureResults.isEmpty) {
          outcome = rejectedTooSmall > 0
              ? RunOutcome.invalidatedTooSmall
              : RunOutcome.loopNotClosed;
        } else {
          sessionCaptureResult = SessionCaptureResultEntity(
            captures: captureResults,
            loopsCaptured: captureResults.length,
            loopsAttempted: loopSegments.length,
            loopsRejectedTooSmall: rejectedTooSmall,
          );
        }
      }

      if (outcome != RunOutcome.territoryClaimed && outcome != RunOutcome.invalidatedSpeedCap) {
        try {
          await repo.touchDefense(simplifiedFullPath);
        } on Object catch (_) {
          // Ignored — defense-touch is a nice-to-have, not required to save the run.
        }
      }

      final run = RunTrackEntity(
        points: simplifiedFullPath,
        distanceMeters: state.distanceMeters,
        duration: state.elapsed,
        outcome: outcome,
      );
      await repo.recordRun(run);

      state = state.copyWith(
        status: RunSessionStatus.finished,
        result: run,
        sessionCaptureResult: sessionCaptureResult,
        pendingLoops: loopSegments,
      );
    } catch (error) {
      // Queue closed loops for retry so a network blip doesn't drop captures.
      if (outcome == RunOutcome.territoryClaimed && loopSegments.isNotEmpty) {
        const queue = PendingCaptureQueue();
        for (var i = 0; i < loopSegments.length; i++) {
          final segment = loopSegments[i];
          final simplifiedSegment = segment.points.length < 3
              ? segment.points
              : RdpSimplifier.simplify(
                  segment.points,
                  AppConstants.rdpSimplificationEpsilonMeters,
                );
          await queue.enqueue(
            PendingCapture(
              id: '${clock.now().microsecondsSinceEpoch}_$i',
              points: simplifiedSegment,
              enqueuedAt: clock.now(),
            ),
          );
        }
      }

      final run = RunTrackEntity(
        points: simplifiedFullPath,
        distanceMeters: state.distanceMeters,
        duration: state.elapsed,
        outcome: outcome,
      );
      state = state.copyWith(
        status: RunSessionStatus.finished,
        result: run,
        errorMessage: error.toString(),
      );
    }
  }

  /// Retries any captures that failed to sync on a previous finish.
  Future<int> flushPendingCaptures() async {
    const queue = PendingCaptureQueue();
    final pending = await queue.peek();
    if (pending.isEmpty) return 0;

    final repo = ref.read(territoryRepositoryProvider);
    var flushed = 0;
    for (final item in pending) {
      try {
        await repo.captureTerritory(item.points);
        await queue.remove(item.id);
        flushed++;
      } catch (e) {
        debugPrint('[CaptureQueue] retry failed for ${item.id}: $e');
      }
    }
    return flushed;
  }

  void reset() {
    _positionSubscription?.cancel();
    _tickTimer?.cancel();
    _loopTracker = null;
    ref.read(territoryRunGpsKeepAliveProvider.notifier).state = false;
    ref.read(runOwnsHighAccuracyGpsProvider.notifier).state = false;
    state = const ActiveRunState();
  }

  static bool _isLoopTooSmallRejection(PostgrestException error) {
    return _isLoopTooSmallRejectionMessage(
      '${error.message} ${error.details ?? ''} ${error.hint ?? ''}',
    );
  }

  static bool _isLoopTooSmallRejectionMessage(String haystack) {
    final lower = haystack.toLowerCase();
    return lower.contains('loop_too_small') ||
        lower.contains('too_small') ||
        lower.contains('minimum area');
  }
}

final activeRunProvider = NotifierProvider<ActiveRunNotifier, ActiveRunState>(
  ActiveRunNotifier.new,
);

/// True when the runner's current position lies inside a rival's owned
/// territory. Surfaces a "Crossing rival territory" HUD cue so a closed
/// loop that steals land doesn't come as a surprise — pure UX signal, the
/// actual steal/contest outcome is still decided server-side in
/// `capture_territory`.
final rivalConflictProvider = Provider<bool>((ref) {
  final points = ref.watch(activeRunProvider.select((s) => s.points));
  if (points.isEmpty) return false;
  final current = points.last;

  final territories = ref.watch(territoryListProvider).valueOrNull;
  if (territories == null) return false;

  for (final territory in territories) {
    if (territory.isOwnedByCurrentUser) continue;
    for (final ring in territory.polygons) {
      if (ring.length >= 3 && GeoUtils.isPointInPolygon(current, ring)) {
        return true;
      }
    }
  }
  return false;
});
