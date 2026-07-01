import 'dart:async';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/features/territory/domain/entities/capture_result_entity.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/run_track_entity.dart';
import 'package:awaken/features/territory/domain/services/geo_utils.dart';
import 'package:awaken/features/territory/domain/services/gps_kalman_filter.dart';
import 'package:awaken/features/territory/domain/services/rdp_simplifier.dart';
import 'package:awaken/features/territory/domain/services/run_validation_service.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

enum RunSessionStatus { idle, requestingPermission, tracking, finishing, finished, error }

class ActiveRunState {
  const ActiveRunState({
    this.status = RunSessionStatus.idle,
    this.points = const [],
    this.distanceMeters = 0,
    this.elapsed = Duration.zero,
    this.isOverSpeed = false,
    this.result,
    this.captureResult,
    this.errorMessage,
  });

  final RunSessionStatus status;
  final List<GeoPointEntity> points;
  final double distanceMeters;
  final Duration elapsed;

  /// True when the most recent rolling-window check found sustained
  /// over-speed — drives a live "vehicle detected" HUD warning.
  final bool isOverSpeed;

  final RunTrackEntity? result;
  final CaptureResultEntity? captureResult;
  final String? errorMessage;

  ActiveRunState copyWith({
    RunSessionStatus? status,
    List<GeoPointEntity>? points,
    double? distanceMeters,
    Duration? elapsed,
    bool? isOverSpeed,
    RunTrackEntity? result,
    CaptureResultEntity? captureResult,
    String? errorMessage,
  }) {
    return ActiveRunState(
      status: status ?? this.status,
      points: points ?? this.points,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      elapsed: elapsed ?? this.elapsed,
      isOverSpeed: isOverSpeed ?? this.isOverSpeed,
      result: result ?? this.result,
      captureResult: captureResult ?? this.captureResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Owns the full GPS run-tracking lifecycle: permission, live position
/// stream, Kalman smoothing, rolling speed-cap anti-cheat, and — on
/// stop — classification + territory capture.
class ActiveRunNotifier extends Notifier<ActiveRunState> {
  StreamSubscription<Position>? _positionSubscription;
  Timer? _tickTimer;
  final GpsKalmanFilter _kalmanFilter = GpsKalmanFilter();
  DateTime? _startTime;
  bool _sawSustainedOverSpeed = false;

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

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        status: RunSessionStatus.error,
        errorMessage: 'Location services are disabled.',
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        status: RunSessionStatus.error,
        errorMessage: 'Location permission denied.',
      );
      return;
    }

    _kalmanFilter.reset();
    _sawSustainedOverSpeed = false;
    _startTime = DateTime.now();
    state = const ActiveRunState(status: RunSessionStatus.tracking);

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime == null) return;
      state = state.copyWith(elapsed: DateTime.now().difference(_startTime!));
    });

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);
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

    state = state.copyWith(
      points: updatedPoints,
      distanceMeters: GeoUtils.pathDistanceMeters(updatedPoints),
      isOverSpeed: overSpeed,
    );
  }

  /// Stops tracking, classifies the run, records it, and — if a valid
  /// loop was closed — calls the capture RPC. Always persists the run
  /// (closed or not) per Story #2's "counts as a normal workout" rule.
  Future<void> finishRun() async {
    _positionSubscription?.cancel();
    _tickTimer?.cancel();
    if (state.status != RunSessionStatus.tracking) return;

    state = state.copyWith(status: RunSessionStatus.finishing);

    final simplifiedPoints = state.points.length < 3
        ? state.points
        : RdpSimplifier.simplify(state.points, AppConstants.rdpSimplificationEpsilonMeters);

    var outcome = RunValidationService.classify(
      points: simplifiedPoints,
      distanceMeters: state.distanceMeters,
      duration: state.elapsed,
      wasInvalidatedBySpeed: _sawSustainedOverSpeed,
    );

    final repo = ref.read(territoryRepositoryProvider);
    CaptureResultEntity? captureResult;

    try {
      // Attempt capture BEFORE recording the run, so a server-side rejection
      // (e.g. `loop_too_small`, enforced against the true polygon area rather
      // than the raw path) downgrades the outcome we actually persist.
      if (outcome == RunOutcome.territoryClaimed) {
        try {
          captureResult = await repo.captureTerritory(simplifiedPoints);
        } on Object catch (_) {
          outcome = RunOutcome.invalidatedTooSmall;
        }
      }

      if (outcome != RunOutcome.territoryClaimed) {
        await repo.touchDefense(simplifiedPoints);
      }

      final run = RunTrackEntity(
        points: simplifiedPoints,
        distanceMeters: state.distanceMeters,
        duration: state.elapsed,
        outcome: outcome,
      );
      await repo.recordRun(run);

      state = state.copyWith(
        status: RunSessionStatus.finished,
        result: run,
        captureResult: captureResult,
      );
    } catch (error) {
      final run = RunTrackEntity(
        points: simplifiedPoints,
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

  void reset() {
    _positionSubscription?.cancel();
    _tickTimer?.cancel();
    state = const ActiveRunState();
  }
}

final activeRunProvider = NotifierProvider<ActiveRunNotifier, ActiveRunState>(
  ActiveRunNotifier.new,
);
