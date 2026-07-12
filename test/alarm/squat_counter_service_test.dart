import 'package:awaken/features/alarm/domain/services/squat_counter_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

void main() {
  group('SquatCounterService', () {
    late SquatCounterService service;

    setUp(() {
      service = SquatCounterService();
      _calibrate(service, _pose(
        hip: (200, 80),
        knee: (200, 200),
        ankle: (200, 320),
      ));
    });

    test('full depth rep counts', () {
      final standing = _pose(
        hip: (200, 80),
        knee: (200, 200),
        ankle: (200, 320),
      );
      final deepSquat = _pose(
        hip: (50, 175),
        knee: (200, 200),
        ankle: (200, 300),
      );

      for (var i = 0; i < 15; i++) {
        service.processPose(standing);
      }
      expect(service.isInSquat, isFalse);

      SquatProcessResult squatDown = const SquatProcessResult();
      for (var i = 0; i < 15; i++) {
        squatDown = service.processPose(deepSquat);
      }
      expect(squatDown.repCompleted, isFalse);
      expect(service.isInSquat, isTrue);
      expect(squatDown.depthRatio, isNotNull);
      expect(squatDown.depthRatio!, greaterThanOrEqualTo(0.6));

      SquatProcessResult completed = const SquatProcessResult();
      bool repCompletedAny = false;
      for (var i = 0; i < 15; i++) {
        completed = service.processPose(standing);
        if (completed.repCompleted) repCompletedAny = true;
      }
      expect(repCompletedAny, isTrue);
      expect(completed.badForm, isFalse);
      expect(service.isInSquat, isFalse);
    });

    test('partial squat is rejected as bad form', () {
      final standing = _pose(
        hip: (200, 80),
        knee: (200, 200),
        ankle: (200, 320),
      );
      final shallowSquat = _pose(
        hip: (-130, 147),
        knee: (200, 200),
        ankle: (200, 300),
      );

      for (var i = 0; i < 15; i++) {
        service.processPose(standing);
      }
      SquatProcessResult squatDown = const SquatProcessResult();
      for (var i = 0; i < 15; i++) {
        squatDown = service.processPose(shallowSquat);
      }
      expect(squatDown.repCompleted, isFalse);
      expect(service.isInSquat, isTrue);
      expect(squatDown.depthRatio, isNotNull);
      expect(squatDown.depthRatio!, lessThan(0.6));

      SquatProcessResult rejected = const SquatProcessResult();
      bool badFormAny = false;
      for (var i = 0; i < 15; i++) {
        rejected = service.processPose(standing);
        if (rejected.badForm) badFormAny = true;
      }
      expect(rejected.repCompleted, isFalse);
      expect(badFormAny, isTrue);
      expect(service.isInSquat, isFalse);
    });

    test('partial pose with one knee missing still works', () {
      final standing = _leftLegPose(
        hip: (200, 80),
        knee: (200, 200),
        ankle: (200, 320),
      );
      final deepSquat = _leftLegPose(
        hip: (50, 175),
        knee: (200, 200),
        ankle: (200, 300),
      );

      for (var i = 0; i < 15; i++) {
        service.processPose(standing);
      }
      SquatProcessResult squatDown = const SquatProcessResult();
      for (var i = 0; i < 15; i++) {
        squatDown = service.processPose(deepSquat);
      }
      expect(squatDown.hasPose, isTrue);
      expect(service.isInSquat, isTrue);

      SquatProcessResult completed = const SquatProcessResult();
      bool repCompletedAny = false;
      for (var i = 0; i < 15; i++) {
        completed = service.processPose(standing);
        if (completed.repCompleted) repCompletedAny = true;
      }
      expect(repCompletedAny, isTrue);
      expect(completed.hasPose, isTrue);
    });

    test('empty pose returns hasPose false', () {
      final result = service.processPose(Pose(landmarks: {}));
      expect(result.hasPose, isFalse);
      expect(result.repCompleted, isFalse);
      expect(result.badForm, isFalse);
      expect(result.depthRatio, isNull);
    });

    test('low likelihood landmarks are treated as no pose', () {
      final lowConfidence = _pose(
        hip: (200, 80),
        knee: (200, 200),
        ankle: (200, 320),
        likelihood: 0.3,
      );
      final result = service.processPose(lowConfidence);
      expect(result.hasPose, isFalse);
      expect(service.isInSquat, isFalse);
    });

    test('partial pose with only right leg still counts reps', () {
      final standing = _rightLegPose(
        hip: (200, 80),
        knee: (200, 200),
        ankle: (200, 320),
      );
      final deepSquat = _rightLegPose(
        hip: (50, 175),
        knee: (200, 200),
        ankle: (200, 300),
      );

      for (var i = 0; i < 15; i++) {
        service.processPose(standing);
      }
      for (var i = 0; i < 15; i++) {
        service.processPose(deepSquat);
      }
      expect(service.isInSquat, isTrue);

      SquatProcessResult completed = const SquatProcessResult();
      bool repCompletedAny = false;
      for (var i = 0; i < 15; i++) {
        completed = service.processPose(standing);
        if (completed.repCompleted) repCompletedAny = true;
      }
      expect(repCompletedAny, isTrue);
      expect(completed.hasPose, isTrue);
    });

    test('missing ankle on one leg falls back to the other leg', () {
      final standing = _leftLegPose(
        hip: (200, 80),
        knee: (200, 200),
        ankle: (200, 320),
      );
      final deepSquat = _leftLegPose(
        hip: (50, 175),
        knee: (200, 200),
        ankle: (200, 300),
      );

      for (var i = 0; i < 15; i++) {
        service.processPose(standing);
      }
      for (var i = 0; i < 15; i++) {
        service.processPose(deepSquat);
      }

      final standingRightOnly = Pose(
        landmarks: {
          PoseLandmarkType.rightHip: PoseLandmark(
            type: PoseLandmarkType.rightHip,
            x: 200,
            y: 80,
            z: 0,
            likelihood: 0.99,
          ),
          PoseLandmarkType.rightKnee: PoseLandmark(
            type: PoseLandmarkType.rightKnee,
            x: 200,
            y: 200,
            z: 0,
            likelihood: 0.99,
          ),
          PoseLandmarkType.rightAnkle: PoseLandmark(
            type: PoseLandmarkType.rightAnkle,
            x: 200,
            y: 320,
            z: 0,
            likelihood: 0.99,
          ),
          PoseLandmarkType.rightShoulder: PoseLandmark(
            type: PoseLandmarkType.rightShoulder,
            x: 200,
            y: 20,
            z: 0,
            likelihood: 0.99,
          ),
        },
      );

      SquatProcessResult completed = const SquatProcessResult();
      bool repCompletedAny = false;
      for (var i = 0; i < 15; i++) {
        completed = service.processPose(standingRightOnly);
        if (completed.repCompleted) repCompletedAny = true;
      }
      expect(repCompletedAny, isTrue);
      expect(completed.hasPose, isTrue);
    });

    test('standing without prior squat does not complete a rep', () {
      final standing = _pose(
        hip: (200, 80),
        knee: (200, 200),
        ankle: (200, 320),
      );

      SquatProcessResult first = const SquatProcessResult();
      for (var i = 0; i < 15; i++) {
        first = service.processPose(standing);
      }
      SquatProcessResult second = const SquatProcessResult();
      for (var i = 0; i < 15; i++) {
        second = service.processPose(standing);
      }

      expect(first.repCompleted, isFalse);
      expect(second.repCompleted, isFalse);
      expect(service.isInSquat, isFalse);
    });

    test('squatting without returning to stand does not complete a rep', () {
      final standing = _pose(
        hip: (200, 80),
        knee: (200, 200),
        ankle: (200, 320),
      );
      final deepSquat = _pose(
        hip: (50, 175),
        knee: (200, 200),
        ankle: (200, 300),
      );

      for (var i = 0; i < 15; i++) {
        service.processPose(standing);
      }
      for (var i = 0; i < 15; i++) {
        service.processPose(deepSquat);
      }

      SquatProcessResult stillSquatting = const SquatProcessResult();
      for (var i = 0; i < 15; i++) {
        stillSquatting = service.processPose(deepSquat);
      }
      expect(stillSquatting.repCompleted, isFalse);
      expect(stillSquatting.badForm, isFalse);
      expect(service.isInSquat, isTrue);
    });

    test('reset clears squat state', () {
      final standing = _pose(
        hip: (200, 80),
        knee: (200, 200),
        ankle: (200, 320),
      );
      final deepSquat = _pose(
        hip: (50, 175),
        knee: (200, 200),
        ankle: (200, 300),
      );

      for (var i = 0; i < 15; i++) {
        service.processPose(standing);
      }
      for (var i = 0; i < 15; i++) {
        service.processPose(deepSquat);
      }
      expect(service.isInSquat, isTrue);

      service.reset();
      expect(service.isInSquat, isFalse);

      _calibrate(service, standing);

      SquatProcessResult afterReset = const SquatProcessResult();
      for (var i = 0; i < 15; i++) {
        afterReset = service.processPose(standing);
      }
      expect(afterReset.repCompleted, isFalse);
      expect(afterReset.badForm, isFalse);
      expect(service.isInSquat, isFalse);
    });
  });
}

void _calibrate(SquatCounterService service, Pose pose) {
  for (var i = 0; i < 8; i++) {
    service.processPose(pose);
  }
}

Pose _pose({
  required (double, double) hip,
  required (double, double) knee,
  required (double, double) ankle,
  double likelihood = 0.99,
}) {
  PoseLandmark landmark(PoseLandmarkType type, (double, double) point) {
    return PoseLandmark(
      type: type,
      x: point.$1,
      y: point.$2,
      z: 0,
      likelihood: likelihood,
    );
  }

  return Pose(
    landmarks: {
      PoseLandmarkType.leftHip: landmark(PoseLandmarkType.leftHip, hip),
      PoseLandmarkType.rightHip: landmark(PoseLandmarkType.rightHip, hip),
      PoseLandmarkType.leftKnee: landmark(PoseLandmarkType.leftKnee, knee),
      PoseLandmarkType.rightKnee: landmark(PoseLandmarkType.rightKnee, knee),
      PoseLandmarkType.leftAnkle: landmark(PoseLandmarkType.leftAnkle, ankle),
      PoseLandmarkType.rightAnkle: landmark(PoseLandmarkType.rightAnkle, ankle),
      PoseLandmarkType.leftShoulder: landmark(PoseLandmarkType.leftShoulder, (hip.$1, hip.$2 - 60)),
      PoseLandmarkType.rightShoulder: landmark(PoseLandmarkType.rightShoulder, (hip.$1, hip.$2 - 60)),
    },
  );
}

Pose _leftLegPose({
  required (double, double) hip,
  required (double, double) knee,
  required (double, double) ankle,
  double likelihood = 0.99,
}) {
  PoseLandmark landmark(PoseLandmarkType type, (double, double) point) {
    return PoseLandmark(
      type: type,
      x: point.$1,
      y: point.$2,
      z: 0,
      likelihood: likelihood,
    );
  }

  return Pose(
    landmarks: {
      PoseLandmarkType.leftHip: landmark(PoseLandmarkType.leftHip, hip),
      PoseLandmarkType.leftKnee: landmark(PoseLandmarkType.leftKnee, knee),
      PoseLandmarkType.leftAnkle: landmark(PoseLandmarkType.leftAnkle, ankle),
      PoseLandmarkType.leftShoulder: landmark(PoseLandmarkType.leftShoulder, (hip.$1, hip.$2 - 60)),
    },
  );
}

Pose _rightLegPose({
  required (double, double) hip,
  required (double, double) knee,
  required (double, double) ankle,
  double likelihood = 0.99,
}) {
  PoseLandmark landmark(PoseLandmarkType type, (double, double) point) {
    return PoseLandmark(
      type: type,
      x: point.$1,
      y: point.$2,
      z: 0,
      likelihood: likelihood,
    );
  }

  return Pose(
    landmarks: {
      PoseLandmarkType.rightHip: landmark(PoseLandmarkType.rightHip, hip),
      PoseLandmarkType.rightKnee: landmark(PoseLandmarkType.rightKnee, knee),
      PoseLandmarkType.rightAnkle: landmark(PoseLandmarkType.rightAnkle, ankle),
      PoseLandmarkType.rightShoulder: landmark(PoseLandmarkType.rightShoulder, (hip.$1, hip.$2 - 60)),
    },
  );
}
