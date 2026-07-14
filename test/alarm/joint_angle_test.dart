import 'package:awaken/features/alarm/domain/services/joint_angle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('right angle (90°)', () {
    final angle = JointAngle.between(
      const Offset(0, -10), // straight up from vertex
      const Offset(0, 0), // vertex
      const Offset(10, 0), // straight right from vertex
    );
    expect(angle, closeTo(90, 1e-6));
  });

  test('straight line (180°)', () {
    final angle = JointAngle.between(
      const Offset(-10, 0),
      const Offset(0, 0),
      const Offset(10, 0),
    );
    expect(angle, closeTo(180, 1e-6));
  });

  test('45° angle', () {
    final angle = JointAngle.between(
      const Offset(10, 0),
      const Offset(0, 0),
      const Offset(10, -10),
    );
    expect(angle, closeTo(45, 1e-6));
  });

  test('near-0° degenerate case (rays nearly coincident)', () {
    final angle = JointAngle.between(
      const Offset(10, 0.001),
      const Offset(0, 0),
      const Offset(10, 0),
    );
    expect(angle, closeTo(0, 0.01));
  });

  test('symmetric regardless of a/c order', () {
    final ab = JointAngle.between(
      const Offset(3, 7),
      const Offset(1, 1),
      const Offset(9, 2),
    );
    final ba = JointAngle.between(
      const Offset(9, 2),
      const Offset(1, 1),
      const Offset(3, 7),
    );
    expect(ab, closeTo(ba, 1e-9));
  });
}
