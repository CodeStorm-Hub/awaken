import 'dart:async';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/services/alarm_notification_service.dart';
import 'package:awaken/features/territory/data/datasources/active_run_checkpoint_store.dart';
import 'package:awaken/features/territory/data/datasources/pending_capture_queue.dart';
import 'package:awaken/features/territory/domain/entities/bounty_zone_entity.dart';
import 'package:awaken/features/territory/domain/entities/capture_result_entity.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/loop_segment_entity.dart';
import 'package:awaken/features/territory/domain/entities/run_track_entity.dart';
import 'package:awaken/features/territory/domain/services/bounty_capture_service.dart';
import 'package:awaken/features/territory/domain/services/explored_cells_sync_service.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum RunSessionStatus {
  idle,
  requestingPermission,
  tracking,
  paused,
  finishing,
  finished,
  error,
}

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
    this.speedKmh = 0,
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

  /// Instantaneous speed from the latest pair of GPS fixes (km/h).
  final double speedKmh;

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
    double? speedKmh,
    double? gpsAccuracyMeters,
    List<LoopSegmentEntity>? pendingLoops,
    int? currentSegmentAnchorIndex,
    RunTrackEntity? result,
    SessionCaptureResultEntity? sessionCaptureResult,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ActiveRunState(
      status: status ?? this.status,
      points: points ?? this.points,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      elapsed: elapsed ?? this.elapsed,
      isOverSpeed: isOverSpeed ?? this.isOverSpeed,
      speedKmh: speedKmh ?? this.speedKmh,
      gpsAccuracyMeters: gpsAccuracyMeters ?? this.gpsAccuracyMeters,
      pendingLoops: pendingLoops ?? this.pendingLoops,
      currentSegmentAnchorIndex:
          currentSegmentAnchorIndex ?? this.currentSegmentAnchorIndex,
      result: result ?? this.result,
      sessionCaptureResult: sessionCaptureResult ?? this.sessionCaptureResult,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Owns the full GPS run-tracking lifecycle: permission, live position
/// stream, Kalman smoothing, rolling speed-cap anti-cheat, and — on
/// stop — classification + territory capture.
///
/// Not reset by [resetAlarmSession] when an alarm overlay opens — only
/// explicit `reset()` (after finish UI) or `finishRun()` completion clears
/// state. Navigating to other tabs / backgrounding the app does **not** stop
/// tracking; the Android foreground-service notification keeps GPS alive
/// until the user taps Stop.
///
/// Progress is also checkpointed to SharedPreferences so a process kill
/// (swipe-away / OS reclaim) can restore the session on next launch and
/// resume the GPS stream.
///
/// Deliberately NOT `autoDispose`: an in-flight `finishRun()` awaits a
/// Supabase round-trip, and autoDispose can tear the notifier down mid-await
/// if watcher count transiently hits zero during a rebuild, silently
/// orphaning the final `state = ...` write (and with it, the finished-state
/// transition the UI listens for). Tab switches leave this notifier (and its
/// position stream / timer) running so the session survives shell navigation.
class ActiveRunNotifier extends Notifier<ActiveRunState> {
  StreamSubscription<Position>? _positionSubscription;
  Timer? _tickTimer;
  Timer? _checkpointDebounce;
  final GpsKalmanFilter _kalmanFilter = GpsKalmanFilter();
  DateTime? _startTime;
  bool _sawSustainedOverSpeed = false;
  LoopClosureTracker? _loopTracker;
  DateTime? _stationarySince;
  Duration _pausedAccumulated = Duration.zero;
  bool _didAttemptRestore = false;
  bool _isListening = false;
  static const _checkpointStore = ActiveRunCheckpointStore();

  @override
  ActiveRunState build() {
    ref.onDispose(() {
      _positionSubscription?.cancel();
      _tickTimer?.cancel();
      _checkpointDebounce?.cancel();
    });
    return const ActiveRunState();
  }

  /// Reloads a durable checkpoint (if any) and restarts GPS tracking.
  ///
  /// Call once at app startup (see [AwakenApp]) so a process kill mid-run
  /// resumes instead of dropping the session.
  Future<void> restoreFromCheckpoint() async {
    if (_didAttemptRestore) return;
    _didAttemptRestore = true;
    if (state.status != RunSessionStatus.idle) return;

    final checkpoint = await _checkpointStore.load();
    if (checkpoint == null || !checkpoint.isResumable) return;

    final status = checkpoint.statusName == 'paused'
        ? RunSessionStatus.paused
        : RunSessionStatus.tracking;

    _kalmanFilter.reset();
    _sawSustainedOverSpeed = checkpoint.sawSustainedOverSpeed;
    _startTime = checkpoint.startTime;
    _pausedAccumulated = checkpoint.pausedAccumulated;
    _stationarySince = null;
    _loopTracker = LoopClosureTracker(
      anchorIndex: checkpoint.loopTrackerAnchorIndex,
      maxDistFromAnchor: checkpoint.loopTrackerMaxDistFromAnchor,
      closureArmed: checkpoint.loopTrackerClosureArmed,
    );

    ref.read(territoryRunGpsKeepAliveProvider.notifier).state = true;
    ref.read(runOwnsHighAccuracyGpsProvider.notifier).state = true;
    state = ActiveRunState(
      status: status,
      points: checkpoint.points,
      distanceMeters: checkpoint.distanceMeters,
      elapsed: checkpoint.elapsed,
      pendingLoops: checkpoint.pendingLoops,
      currentSegmentAnchorIndex: checkpoint.currentSegmentAnchorIndex,
      gpsAccuracyMeters: checkpoint.gpsAccuracyMeters,
      isOverSpeed: checkpoint.sawSustainedOverSpeed,
    );

    _startTickTimer();
    await _ensureTrackingPermissions();
    _startPositionStream();
  }

  Future<void> startRun() async {
    state = const ActiveRunState(status: RunSessionStatus.requestingPermission);

    try {
      await _ensureTrackingPermissions();
    } on LocationAccessException catch (e) {
      state = state.copyWith(
        status: RunSessionStatus.error,
        errorMessage: e.message,
      );
      return;
    }

    _kalmanFilter.reset();
    _sawSustainedOverSpeed = false;
    _loopTracker = LoopClosureTracker();
    _startTime = clock.now();
    _pausedAccumulated = Duration.zero;
    _stationarySince = null;
    ref.read(territoryRunGpsKeepAliveProvider.notifier).state = true;
    ref.read(runOwnsHighAccuracyGpsProvider.notifier).state = true;
    state = const ActiveRunState(status: RunSessionStatus.tracking);

    _startTickTimer();
    _startPositionStream();
    unawaited(_persistCheckpoint());
  }

  Future<void> _ensureTrackingPermissions() async {
    // Android 13+: FGS notification requires POST_NOTIFICATIONS. Best-effort —
    // never block GPS start if the plugin/channel is unavailable (tests).
    try {
      await AlarmNotificationService.requestPermissions();
    } on Object catch (error) {
      debugPrint('[ActiveRun] notification permission skipped: $error');
    }
    await LocationPermissionHelper.ensureLocationAccess(
      serviceDisabledMessage:
          'Turn on location services to start a territory run.',
      permissionDeniedMessage:
          'Allow location access so we can track your run.',
    );
  }

  void _startTickTimer() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime == null) return;
      if (state.status == RunSessionStatus.paused) {
        _pausedAccumulated += const Duration(seconds: 1);
        return;
      }
      if (state.status != RunSessionStatus.tracking) return;
      state = state.copyWith(
        elapsed: clock.now().difference(_startTime!) - _pausedAccumulated,
      );
    });
  }

  void _startPositionStream() {
    _positionSubscription?.cancel();
    _isListening = true;
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: _runLocationSettings(),
        ).listen(
          _onPosition,
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('[ActiveRun] position stream error: $error');
            // Keep the session — pause + checkpoint so a reopen can resume.
            _positionSubscription = null;
            _isListening = false;
            if (state.status == RunSessionStatus.tracking ||
                state.status == RunSessionStatus.paused) {
              state = state.copyWith(
                status: RunSessionStatus.paused,
                errorMessage:
                    'Location briefly interrupted. Resume when ready — your run is saved.',
              );
              unawaited(_persistCheckpoint());
            }
          },
          onDone: () {
            _isListening = false;
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
          notificationChannelName: 'Territory run',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.fitness,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );
  }

  void _onPosition(Position position) {
    if (state.status != RunSessionStatus.tracking &&
        state.status != RunSessionStatus.paused) {
      return;
    }

    final speed = position.speed.isNaN ? 0.0 : position.speed;
    final candidate = GeoPointEntity(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
    );
    final last = state.points.isEmpty ? null : state.points.last;
    final movedMeters = last == null
        ? double.infinity
        : GeoUtils.haversineMeters(last, candidate);
    // Prefer displacement over GPS speed — many devices report speed 0 on
    // walking fixes, which would false-trigger traffic grace.
    const stationaryRadiusMeters = 2.5;
    final looksStationary =
        movedMeters <= stationaryRadiusMeters &&
        speed <= AppConstants.runGracePauseSpeedMps;

    if (state.status == RunSessionStatus.tracking && looksStationary) {
      _stationarySince ??= clock.now();
      if (clock.now().difference(_stationarySince!) >=
          AppConstants.runGracePauseDelay) {
        pauseRun(auto: true);
        return;
      }
    } else if (!looksStationary) {
      _stationarySince = null;
    }

    if (state.status == RunSessionStatus.paused) {
      if (looksStationary) return;
      resumeRun();
    }

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

    var speedKmh = 0.0;
    if (updatedPoints.length >= 2) {
      speedKmh = GeoUtils.speedKmh(
        updatedPoints[updatedPoints.length - 2],
        updatedPoints.last,
      );
      if (!speedKmh.isFinite || speedKmh < 0) speedKmh = 0;
    }

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
      speedKmh: speedKmh,
      gpsAccuracyMeters: position.accuracy,
      pendingLoops: pendingLoops,
      currentSegmentAnchorIndex: anchorIndex,
      clearErrorMessage: true,
    );
    _scheduleCheckpointPersist();
  }

  void pauseRun({bool auto = false}) {
    if (state.status != RunSessionStatus.tracking) return;
    _stationarySince = null;
    state = state.copyWith(status: RunSessionStatus.paused, speedKmh: 0);
    unawaited(_persistCheckpoint());
  }

  void resumeRun() {
    if (state.status != RunSessionStatus.paused) return;
    _stationarySince = null;
    state = state.copyWith(
      status: RunSessionStatus.tracking,
      clearErrorMessage: true,
    );
    if (!_isListening) {
      _startPositionStream();
    }
    unawaited(_persistCheckpoint());
  }

  /// Re-attaches the GPS stream after the app returns to foreground if an
  /// in-progress run lost its listener (common after process death recovery
  /// races or transient FGS interruptions).
  Future<void> ensureBackgroundTracking() async {
    if (state.status != RunSessionStatus.tracking &&
        state.status != RunSessionStatus.paused) {
      return;
    }
    if (_isListening && _positionSubscription != null) return;
    try {
      await _ensureTrackingPermissions();
    } on LocationAccessException catch (e) {
      state = state.copyWith(
        status: RunSessionStatus.paused,
        errorMessage: e.message,
      );
      unawaited(_persistCheckpoint());
      return;
    }
    if (_tickTimer == null || !(_tickTimer?.isActive ?? false)) {
      _startTickTimer();
    }
    _startPositionStream();
  }

  /// Stops tracking, classifies the run, records it, and — if valid loop
  /// segments were detected — calls capture RPC for each. Always persists the
  /// run (closed or not) per Story #2's "counts as a normal workout" rule.
  Future<void> finishRun() async {
    // Guard before any await — a second Stop tap must not double-capture.
    if (state.status != RunSessionStatus.tracking &&
        state.status != RunSessionStatus.paused) {
      return;
    }
    state = state.copyWith(status: RunSessionStatus.finishing);

    _checkpointDebounce?.cancel();
    await _checkpointStore.clear();
    _positionSubscription?.cancel();
    _tickTimer?.cancel();
    _isListening = false;
    ref.read(runOwnsHighAccuracyGpsProvider.notifier).state = false;

    final rawPoints = state.points;
    final simplifiedFullPath = rawPoints.length < 3
        ? rawPoints
        : RdpSimplifier.simplify(
            rawPoints,
            AppConstants.rdpSimplificationEpsilonMeters,
          );

    // Prefer live-detected loops when finish-time re-extraction finds none —
    // the HUD "loop closed" pill is driven by pendingLoops, and ignoring them
    // here drops claims the runner already earned mid-run.
    var loopSegments = RunValidationService.extractLoopSegments(rawPoints);
    if (loopSegments.isEmpty && state.pendingLoops.isNotEmpty) {
      loopSegments = state.pendingLoops;
    }

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
        var rejectedTooFast = 0;

        for (final segment in loopSegments) {
          // Never RDP before capture — server anti-cheat rejects segments
          // longer than 80 m (`path_segment_too_fast`). Densify instead.
          final capturePoints = GeoUtils.densifyPath(segment.points);
          try {
            final result = await repo.captureTerritory(capturePoints);
            captureResults.add(result);
          } on PostgrestException catch (error) {
            if (_isLoopTooSmallRejection(error)) {
              rejectedTooSmall++;
            } else if (_isPathTooFastRejection(error)) {
              rejectedTooFast++;
            } else {
              rethrow;
            }
          } on Exception catch (error) {
            if (_isLoopTooSmallRejectionMessage(error.toString())) {
              rejectedTooSmall++;
            } else if (_isPathTooFastRejectionMessage(error.toString())) {
              rejectedTooFast++;
            } else {
              rethrow;
            }
          }
        }

        if (captureResults.isEmpty) {
          outcome = rejectedTooSmall > 0
              ? RunOutcome.invalidatedTooSmall
              : rejectedTooFast > 0
              ? RunOutcome.invalidatedSpeedCap
              : RunOutcome.loopNotClosed;
        } else {
          final zones = await ref
              .read(bountyZonesProvider.future)
              .catchError((_) => const <BountyZoneEntity>[]);
          final bounty = BountyCaptureService.evaluate(
            loops: [for (final segment in loopSegments) segment.points],
            zones: zones,
          );
          sessionCaptureResult = SessionCaptureResultEntity(
            captures: captureResults,
            loopsCaptured: captureResults.length,
            loopsAttempted: loopSegments.length,
            loopsRejectedTooSmall: rejectedTooSmall,
            bountyMultiplier: bounty?.multiplier ?? 1.0,
            bountyLabel: bounty?.label,
          );
          // Force map / leaderboard refresh even if Realtime is slow.
          ref.invalidate(territoryListProvider);
          ref.invalidate(leaderboardProvider);
          if (bounty != null) {
            try {
              await SharedPreferences.getInstance().then((prefs) async {
                await prefs.setString(
                  'awaken_last_bounty_badge',
                  '${bounty.label}|${bounty.multiplier}|${DateTime.now().toIso8601String()}',
                );
              });
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId != null) {
                await Supabase.instance.client.from('bounty_claims').insert({
                  'user_id': userId,
                  'label': bounty.label,
                  'multiplier': bounty.multiplier,
                });
              }
            } on Object catch (_) {}
          }
        }
      }

      if (outcome != RunOutcome.territoryClaimed &&
          outcome != RunOutcome.invalidatedSpeedCap) {
        try {
          await repo.touchDefense(simplifiedFullPath);
        } on Object catch (_) {
          // Ignored — defense-touch is a nice-to-have, not required to save the run.
        }
      }

      final claimedArea = sessionCaptureResult?.totalClaimedAreaSqMeters;
      final run = RunTrackEntity(
        points: simplifiedFullPath,
        distanceMeters: state.distanceMeters,
        duration: state.elapsed,
        outcome: outcome,
        areaClaimedSqMeters: claimedArea,
      );
      await repo.recordRun(run);

      // Chart fog grid from this run's path (best-effort; never block finish).
      unawaited(() async {
        try {
          final fogStore = ref.read(exploredCellsStoreProvider);
          await fogStore.revealPath(simplifiedFullPath);
          ref.read(exploredCellsVersionProvider.notifier).state++;
          await ExploredCellsSyncService.push(fogStore);
        } on Object catch (_) {
          // Fog is best-effort.
        }
      }());

      // Always refresh ranks after a capture so the shell tab never shows
      // pre-steal totals (IndexedStack keeps the old AsyncData otherwise).
      ref.invalidate(territoryListProvider);
      ref.invalidate(leaderboardProvider);

      state = state.copyWith(
        status: RunSessionStatus.finished,
        result: run,
        sessionCaptureResult: sessionCaptureResult,
        pendingLoops: loopSegments,
      );
    } catch (error) {
      // Queue closed loops for retry so a network blip doesn't drop captures.
      // Keep points dense — RDP here would recreate path_segment_too_fast.
      if (outcome == RunOutcome.territoryClaimed && loopSegments.isNotEmpty) {
        const queue = PendingCaptureQueue();
        for (var i = 0; i < loopSegments.length; i++) {
          final segment = loopSegments[i];
          await queue.enqueue(
            PendingCapture(
              id: '${clock.now().microsecondsSinceEpoch}_$i',
              points: GeoUtils.densifyPath(segment.points),
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
        areaClaimedSqMeters: sessionCaptureResult?.totalClaimedAreaSqMeters,
      );
      try {
        await repo.recordRun(run);
      } on Object catch (_) {
        // Local finished state still surfaces below.
      }
      state = state.copyWith(
        status: RunSessionStatus.finished,
        result: run,
        errorMessage: error.toString(),
        pendingLoops: loopSegments,
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
        await repo.captureTerritory(GeoUtils.densifyPath(item.points));
        await queue.remove(item.id);
        flushed++;
      } catch (e) {
        final message = e.toString();
        // Permanent server rejections will never succeed on retry — drop them
        // so they stop spamming logs and blocking attention on live runs.
        if (_isPathTooFastRejectionMessage(message) ||
            _isLoopTooSmallRejectionMessage(message)) {
          debugPrint(
            '[CaptureQueue] dropping permanent rejection for ${item.id}: $e',
          );
          await queue.remove(item.id);
          continue;
        }
        debugPrint('[CaptureQueue] retry failed for ${item.id}: $e');
      }
    }
    if (flushed > 0) {
      ref.invalidate(territoryListProvider);
      ref.invalidate(leaderboardProvider);
    }
    return flushed;
  }

  void reset() {
    _checkpointDebounce?.cancel();
    unawaited(_checkpointStore.clear());
    _positionSubscription?.cancel();
    _tickTimer?.cancel();
    _isListening = false;
    _loopTracker = null;
    ref.read(territoryRunGpsKeepAliveProvider.notifier).state = false;
    ref.read(runOwnsHighAccuracyGpsProvider.notifier).state = false;
    state = const ActiveRunState();
  }

  void _scheduleCheckpointPersist() {
    _checkpointDebounce?.cancel();
    _checkpointDebounce = Timer(const Duration(seconds: 2), () {
      unawaited(_persistCheckpoint());
    });
  }

  /// Flushes the latest run snapshot immediately (used on app background).
  Future<void> persistCheckpointNow() => _persistCheckpoint();

  Future<void> _persistCheckpoint() async {
    final status = state.status;
    if (status != RunSessionStatus.tracking &&
        status != RunSessionStatus.paused) {
      await _checkpointStore.clear();
      return;
    }
    if (_startTime == null) return;

    final tracker = _loopTracker;
    await _checkpointStore.save(
      ActiveRunCheckpoint(
        statusName: status.name,
        points: state.points,
        distanceMeters: state.distanceMeters,
        elapsed: state.elapsed,
        startTime: _startTime!,
        pausedAccumulated: _pausedAccumulated,
        sawSustainedOverSpeed: _sawSustainedOverSpeed,
        pendingLoops: state.pendingLoops,
        currentSegmentAnchorIndex: state.currentSegmentAnchorIndex,
        loopTrackerAnchorIndex: tracker?.anchorIndex ?? 0,
        loopTrackerMaxDistFromAnchor: tracker?.maxDistFromAnchor ?? 0,
        loopTrackerClosureArmed: tracker?.closureArmed ?? false,
        gpsAccuracyMeters: state.gpsAccuracyMeters,
      ),
    );
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

  static bool _isPathTooFastRejection(PostgrestException error) {
    return _isPathTooFastRejectionMessage(
      '${error.message} ${error.details ?? ''} ${error.hint ?? ''}',
    );
  }

  static bool _isPathTooFastRejectionMessage(String haystack) {
    final lower = haystack.toLowerCase();
    return lower.contains('path_segment_too_fast') ||
        lower.contains('segment_too_fast');
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

  final territories = ref.watch(territoryListProvider).value;
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
