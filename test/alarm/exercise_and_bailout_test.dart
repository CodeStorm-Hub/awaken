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
      counter.processPose(up());
    }
    expect(counter.isCalibrated, isTrue);
    counter.processPose(down());
    final done = counter.processPose(up());
    expect(done.repCompleted, isTrue);
  });

  test('jumping jack counter completes open-close cycle', () {
    final counter = JumpingJackCounterService();
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
      counter.processPose(closed());
    }
    expect(counter.isCalibrated, isTrue);
    counter.processPose(open());
    final done = counter.processPose(closed());
    expect(done.repCompleted, isTrue);
  });

  test('high-knees counter completes a lift cycle', () {
    final counter = HighKneesCounterService();
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
      counter.processPose(stand());
    }
    expect(counter.isCalibrated, isTrue);
    counter.processPose(leftUp());
    final done = counter.processPose(stand());
    expect(done.repCompleted, isTrue);
  });
}
