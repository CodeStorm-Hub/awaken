import 'dart:math' as math;
import 'dart:ui' show Offset;

/// Shared joint-angle geometry for exercise counters — the angle at [vertex]
/// formed by rays to [a] and [c], in degrees (0–180).
///
/// Uses `atan2(cross, dot)` rather than `acos(dot/magnitude)`: numerically
/// preferable near the 0°/180° extremes, where `acos` needs an explicit
/// `.clamp(-1.0, 1.0)` to guard against floating-point drift pushing the
/// cosine argument just outside its domain.
abstract final class JointAngle {
  static double between(Offset a, Offset vertex, Offset c) {
    final ba = Offset(a.dx - vertex.dx, a.dy - vertex.dy);
    final bc = Offset(c.dx - vertex.dx, c.dy - vertex.dy);
    final dot = ba.dx * bc.dx + ba.dy * bc.dy;
    final cross = (ba.dx * bc.dy - ba.dy * bc.dx).abs();
    return math.atan2(cross, dot) * (180.0 / math.pi);
  }
}
