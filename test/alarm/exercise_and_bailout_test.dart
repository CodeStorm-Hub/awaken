import 'dart:isolate';

import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_exercise_type.dart';
import 'package:awaken/features/alarm/domain/repositories/alarm_repository.dart';
import 'package:awaken/features/alarm/domain/services/alarm_bailout_service.dart';
import 'package:awaken/features/alarm/domain/services/exercise_counter_router.dart';
import 'package:awaken/features/alarm/domain/services/high_knees_counter_service.dart';
import 'package:awaken/features/alarm/domain/services/jumping_jack_counter_service.dart';
import 'package:awaken/features/alarm/domain/services/push_up_counter_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemAlarmRepo implements AlarmRepository {
  final List<AlarmEntity> alarms = [];

  @override
  Future<List<AlarmEntity>> getAlarms() async => List.of(alarms);

  @override
  Future<void> saveAlarm(AlarmEntity alarm) async {
    alarms.removeWhere((a) => a.id == alarm.id);
    alarms.add(alarm);
  }

  @override
  Future<void> deleteAlarm(String id) async {
    alarms.removeWhere((a) => a.id == id);
  }
}

/// Monotonically increasing synthetic timestamp for feeding [ExerciseCounter]
/// implementations deterministically in tests, without real `Duration`
/// delays. Defaults to ~66ms steps (the pipeline's throttled ~15 FPS).
class _FakeClock {
  _FakeClock([DateTime? start]) : _now = start ?? DateTime(2026, 7, 11);
  DateTime _now;

  DateTime tick([Duration step = const Duration(milliseconds: 66)]) {
    _now = _now.add(step);
    return _now;
  }
}

Pose _pose(Map<PoseLandmarkType, Offset> points) {
  final landmarks = <PoseLandmarkType, PoseLandmark>{};
  for (final e in points.entries) {
    landmarks[e.key] = PoseLandmark(
      type: e.key,
      x: e.value.dx,
      y: e.value.dy,
      z: 0,
      likelihood: 0.99,
    );
  }
  return Pose(landmarks: landmarks);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('roulette pick is stable for same alarm and day', () {
    final a = pickRouletteExercise(
      alarmId: 'alarm-1',
      now: DateTime(2026, 7, 11),
    );
    final b = pickRouletteExercise(
      alarmId: 'alarm-1',
      now: DateTime(2026, 7, 11),
    );
    expect(a, b);
  });

  test('roulette pick is stable across process/isolate restarts', () async {
    // Object.hash/String.hashCode are salted per isolate for hash-flooding
    // protection, so spawning two independent isolates (each gets its own
    // salt, same as two separate app launches) is the only way to catch a
    // regression back to the unstable Object.hash-based implementation —
    // a same-isolate test can't, since the salt is fixed for its lifetime.
    final a = await Isolate.run(
      () => pickRouletteExercise(
        alarmId: 'alarm-cross-isolate',
        now: DateTime(2026, 7, 11),
      ).name,
    );
    final b = await Isolate.run(
      () => pickRouletteExercise(
        alarmId: 'alarm-cross-isolate',
        now: DateTime(2026, 7, 11),
      ).name,
    );
    expect(a, b);
  });

  test('bailout applies 2x after window', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = _MemAlarmRepo()
      ..alarms.add(
        AlarmEntity(
          id: 'a1',
          scheduledTime: DateTime(2026, 7, 11, 7),
          requiredReps: 10,
          isActive: true,
        ),
      );
    const service = AlarmBailoutService();
    final firedAt = DateTime.now().subtract(const Duration(hours: 3));
    await service.recordFire(
      alarm: repo.alarms.first,
      exerciseType: AlarmExerciseType.squats,
      requiredReps: 10,
      now: firedAt,
    );
    final applied = await service.applyBailoutPenalties(
      repository: repo,
      now: DateTime.now(),
    );
    expect(applied, 1);
    expect(repo.alarms.single.penaltyMultiplier, 2);
  });

  test('push-up counter completes a full cycle', () {
    final counter = PushUpCounterService();
    final clock = _FakeClock();
    Pose up() => _pose({
      PoseLandmarkType.leftShoulder: const Offset(40, 40),
      PoseLandmarkType.leftElbow: const Offset(40, 80),
      PoseLandmarkType.leftWrist: const Offset(40, 120),
      PoseLandmarkType.rightShoulder: const Offset(80, 40),
      PoseLandmarkType.rightElbow: const Offset(80, 80),
      PoseLandmarkType.rightWrist: const Offset(80, 120),
    });
    Pose down() => _pose({
      PoseLandmarkType.leftShoulder: const Offset(40, 40),
      PoseLandmarkType.leftElbow: const Offset(70, 50),
      PoseLandmarkType.leftWrist: const Offset(40, 60),
      PoseLandmarkType.rightShoulder: const Offset(80, 40),
      PoseLandmarkType.rightElbow: const Offset(50, 50),
      PoseLandmarkType.rightWrist: const Offset(80, 60),
    });

    for (var i = 0; i < 8; i++) {
      counter.processPose(up(), clock.tick());
    }
    expect(counter.isCalibrated, isTrue);
    for (var i = 0; i < 15; i++) {
      counter.processPose(down(), clock.tick());
    }
    bool repCompleted = false;
    for (var i = 0; i < 15; i++) {
      final res = counter.processPose(up(), clock.tick());
      if (res.repCompleted) {
        repCompleted = true;
      }
    }
    expect(repCompleted, isTrue);
  });

  test('jumping jack counter completes open-close cycle', () {
    final counter = JumpingJackCounterService();
    final clock = _FakeClock();
    Pose closed() => _pose({
      PoseLandmarkType.nose: const Offset(50, 10),
      PoseLandmarkType.leftWrist: const Offset(30, 80),
      PoseLandmarkType.rightWrist: const Offset(70, 80),
      PoseLandmarkType.leftHip: const Offset(40, 100),
      PoseLandmarkType.rightHip: const Offset(60, 100),
      PoseLandmarkType.leftAnkle: const Offset(42, 180),
      PoseLandmarkType.rightAnkle: const Offset(58, 180),
    });
    Pose open() => _pose({
      PoseLandmarkType.nose: const Offset(50, 10),
      PoseLandmarkType.leftWrist: const Offset(20, 5),
      PoseLandmarkType.rightWrist: const Offset(80, 5),
      PoseLandmarkType.leftHip: const Offset(40, 100),
      PoseLandmarkType.rightHip: const Offset(60, 100),
      PoseLandmarkType.leftAnkle: const Offset(20, 180),
      PoseLandmarkType.rightAnkle: const Offset(80, 180),
    });

    for (var i = 0; i < 8; i++) {
      counter.processPose(closed(), clock.tick());
    }
    expect(counter.isCalibrated, isTrue);
    for (var i = 0; i < 15; i++) {
      counter.processPose(open(), clock.tick());
    }
    bool repCompleted = false;
    for (var i = 0; i < 15; i++) {
      final res = counter.processPose(closed(), clock.tick());
      if (res.repCompleted) {
        repCompleted = true;
      }
    }
    expect(repCompleted, isTrue);
  });

  test('push-up descent does not flash bad form; shallow rep flags once', () {
    final counter = PushUpCounterService();
    final clock = _FakeClock();
    Pose atElbowExtended() => _pose({
      PoseLandmarkType.leftShoulder: const Offset(0, 0),
      PoseLandmarkType.leftElbow: const Offset(0, 50),
      PoseLandmarkType.leftWrist: const Offset(0, 100),
      PoseLandmarkType.rightShoulder: const Offset(100, 0),
      PoseLandmarkType.rightElbow: const Offset(100, 50),
      PoseLandmarkType.rightWrist: const Offset(100, 100),
    });
    // ~110° elbow — a dip that starts but never reaches the 90° depth gate.
    Pose atShallowDip() => _pose({
      PoseLandmarkType.leftShoulder: const Offset(0, 0),
      PoseLandmarkType.leftElbow: const Offset(0, 50),
      PoseLandmarkType.leftWrist: const Offset(47, 67),
      PoseLandmarkType.rightShoulder: const Offset(100, 0),
      PoseLandmarkType.rightElbow: const Offset(100, 50),
      PoseLandmarkType.rightWrist: const Offset(53, 67),
    });

    for (var i = 0; i < 8; i++) {
      counter.processPose(atElbowExtended(), clock.tick());
    }
    expect(counter.isCalibrated, isTrue);

    // Mid-descent frames must never be flagged as bad form.
    for (var i = 0; i < 10; i++) {
      final res = counter.processPose(atShallowDip(), clock.tick());
      expect(res.badForm, isFalse, reason: 'frame $i flagged during descent');
      expect(res.repCompleted, isFalse);
    }

    // Returning to extension without reaching depth = one bad-form flag.
    var badFormCount = 0;
    for (var i = 0; i < 15; i++) {
      final res = counter.processPose(atElbowExtended(), clock.tick());
      if (res.badForm) badFormCount++;
      expect(res.repCompleted, isFalse);
    }
    expect(badFormCount, 1);
  });

  test('jumping jack transient arm/feet asynchrony is not bad form', () {
    final counter = JumpingJackCounterService();
    final clock = _FakeClock();
    Pose closed() => _pose({
      PoseLandmarkType.nose: const Offset(50, 10),
      PoseLandmarkType.leftWrist: const Offset(30, 80),
      PoseLandmarkType.rightWrist: const Offset(70, 80),
      PoseLandmarkType.leftHip: const Offset(40, 100),
      PoseLandmarkType.rightHip: const Offset(60, 100),
      PoseLandmarkType.leftAnkle: const Offset(42, 180),
      PoseLandmarkType.rightAnkle: const Offset(58, 180),
    });
    // Arms already up, feet not yet out — the normal mid-jump state.
    Pose armsFirst() => _pose({
      PoseLandmarkType.nose: const Offset(50, 10),
      PoseLandmarkType.leftWrist: const Offset(20, 5),
      PoseLandmarkType.rightWrist: const Offset(80, 5),
      PoseLandmarkType.leftHip: const Offset(40, 100),
      PoseLandmarkType.rightHip: const Offset(60, 100),
      PoseLandmarkType.leftAnkle: const Offset(42, 180),
      PoseLandmarkType.rightAnkle: const Offset(58, 180),
    });

    for (var i = 0; i < 8; i++) {
      counter.processPose(closed(), clock.tick());
    }
    expect(counter.isCalibrated, isTrue);

    // 5 frames × 66ms ≈ 330ms — well under the 700ms wall-clock window.
    for (var i = 0; i < 5; i++) {
      final res = counter.processPose(armsFirst(), clock.tick());
      expect(res.badForm, isFalse, reason: 'transient frame $i flagged');
    }
  });

  test('jumping jack asymmetry flags bad form after ~700ms wall-clock, '
      'not a fixed frame count', () {
    final counter = JumpingJackCounterService();
    final clock = _FakeClock();
    Pose closed() => _pose({
      PoseLandmarkType.nose: const Offset(50, 10),
      PoseLandmarkType.leftWrist: const Offset(30, 80),
      PoseLandmarkType.rightWrist: const Offset(70, 80),
      PoseLandmarkType.leftHip: const Offset(40, 100),
      PoseLandmarkType.rightHip: const Offset(60, 100),
      PoseLandmarkType.leftAnkle: const Offset(42, 180),
      PoseLandmarkType.rightAnkle: const Offset(58, 180),
    });
    Pose armsFirst() => _pose({
      PoseLandmarkType.nose: const Offset(50, 10),
      PoseLandmarkType.leftWrist: const Offset(20, 5),
      PoseLandmarkType.rightWrist: const Offset(80, 5),
      PoseLandmarkType.leftHip: const Offset(40, 100),
      PoseLandmarkType.rightHip: const Offset(60, 100),
      PoseLandmarkType.leftAnkle: const Offset(42, 180),
      PoseLandmarkType.rightAnkle: const Offset(58, 180),
    });

    for (var i = 0; i < 8; i++) {
      counter.processPose(closed(), clock.tick());
    }
    expect(counter.isCalibrated, isTrue);

    // Sustained asymmetry at the normal ~66ms throttle rate: fires once
    // elapsed time crosses ~700ms, regardless of exact frame count.
    DateTime? asymmetryStartedAt;
    DateTime? firedAt;
    for (var i = 0; i < 20 && firedAt == null; i++) {
      final ts = clock.tick();
      asymmetryStartedAt ??= ts;
      final res = counter.processPose(armsFirst(), ts);
      if (res.badForm) firedAt = ts;
    }
    expect(firedAt, isNotNull, reason: 'bad form never fired');
    final elapsed = firedAt!.difference(asymmetryStartedAt!).inMilliseconds;
    expect(
      elapsed,
      inInclusiveRange(700, 700 + 132),
      reason: 'fired at $elapsed ms, expected ~700ms ±2 frames',
    );
  });

  test('jumping jack asymmetry does not fire prematurely under a slow, '
      'low frame-rate sequence', () {
    final counter = JumpingJackCounterService();
    final clock = _FakeClock();
    Pose closed() => _pose({
      PoseLandmarkType.nose: const Offset(50, 10),
      PoseLandmarkType.leftWrist: const Offset(30, 80),
      PoseLandmarkType.rightWrist: const Offset(70, 80),
      PoseLandmarkType.leftHip: const Offset(40, 100),
      PoseLandmarkType.rightHip: const Offset(60, 100),
      PoseLandmarkType.leftAnkle: const Offset(42, 180),
      PoseLandmarkType.rightAnkle: const Offset(58, 180),
    });
    Pose armsFirst() => _pose({
      PoseLandmarkType.nose: const Offset(50, 10),
      PoseLandmarkType.leftWrist: const Offset(20, 5),
      PoseLandmarkType.rightWrist: const Offset(80, 5),
      PoseLandmarkType.leftHip: const Offset(40, 100),
      PoseLandmarkType.rightHip: const Offset(60, 100),
      PoseLandmarkType.leftAnkle: const Offset(42, 180),
      PoseLandmarkType.rightAnkle: const Offset(58, 180),
    });

    for (var i = 0; i < 8; i++) {
      counter.processPose(closed(), clock.tick());
    }
    expect(counter.isCalibrated, isTrue);

    // Only 3 frames (a raw frame-count gate of 10 would never fire here),
    // but 250ms apart — 500ms elapsed by the 3rd, still under the window.
    for (var i = 0; i < 3; i++) {
      final res = counter.processPose(
        armsFirst(),
        clock.tick(const Duration(milliseconds: 250)),
      );
      expect(res.badForm, isFalse, reason: 'frame $i fired prematurely');
    }
    // The 4th frame crosses 750ms elapsed — should now fire despite only
    // 4 total frames, proving the gate tracks wall-clock time, not count.
    final res = counter.processPose(
      armsFirst(),
      clock.tick(const Duration(milliseconds: 250)),
    );
    expect(res.badForm, isTrue);
  });

  test('high-knees plant requires clear hysteresis before next rep', () {
    final counter = HighKneesCounterService();
    final clock = _FakeClock();
    Pose stand() => _pose({
      PoseLandmarkType.leftHip: const Offset(40, 100),
      PoseLandmarkType.rightHip: const Offset(60, 100),
      PoseLandmarkType.leftKnee: const Offset(40, 140),
      PoseLandmarkType.rightKnee: const Offset(60, 140),
    });
    Pose leftUp() => _pose({
      PoseLandmarkType.leftHip: const Offset(40, 100),
      PoseLandmarkType.rightHip: const Offset(60, 100),
      PoseLandmarkType.leftKnee: const Offset(40, 70),
      PoseLandmarkType.rightKnee: const Offset(60, 140),
    });
    // Knee hovering mid-way (~30% of thigh below hip) — not planted.
    Pose leftHover() => _pose({
      PoseLandmarkType.leftHip: const Offset(40, 100),
      PoseLandmarkType.rightHip: const Offset(60, 100),
      PoseLandmarkType.leftKnee: const Offset(40, 112),
      PoseLandmarkType.rightKnee: const Offset(60, 140),
    });

    for (var i = 0; i < 8; i++) {
      counter.processPose(stand(), clock.tick());
    }
    expect(counter.isCalibrated, isTrue);

    for (var i = 0; i < 15; i++) {
      counter.processPose(leftUp(), clock.tick());
    }
    expect(counter.isInActivePhase, isTrue);

    // Hovering near hip height must not complete the rep.
    for (var i = 0; i < 15; i++) {
      final res = counter.processPose(leftHover(), clock.tick());
      expect(res.repCompleted, isFalse, reason: 'hover frame $i counted');
    }

    bool repCompleted = false;
    for (var i = 0; i < 15; i++) {
      if (counter.processPose(stand(), clock.tick()).repCompleted) {
        repCompleted = true;
      }
    }
    expect(repCompleted, isTrue);
  });

  test('high-knees counter completes a lift cycle', () {
    final counter = HighKneesCounterService();
    final clock = _FakeClock();
    Pose stand() => _pose({
      PoseLandmarkType.leftHip: const Offset(40, 100),
      PoseLandmarkType.rightHip: const Offset(60, 100),
      PoseLandmarkType.leftKnee: const Offset(40, 140),
      PoseLandmarkType.rightKnee: const Offset(60, 140),
    });
    Pose leftUp() => _pose({
      PoseLandmarkType.leftHip: const Offset(40, 100),
      PoseLandmarkType.rightHip: const Offset(60, 100),
      PoseLandmarkType.leftKnee: const Offset(40, 70),
      PoseLandmarkType.rightKnee: const Offset(60, 140),
    });

    for (var i = 0; i < 8; i++) {
      counter.processPose(stand(), clock.tick());
    }
    expect(counter.isCalibrated, isTrue);
    for (var i = 0; i < 15; i++) {
      counter.processPose(leftUp(), clock.tick());
    }
    bool repCompleted = false;
    for (var i = 0; i < 15; i++) {
      final res = counter.processPose(stand(), clock.tick());
      if (res.repCompleted) {
        repCompleted = true;
      }
    }
    expect(repCompleted, isTrue);
  });
}
