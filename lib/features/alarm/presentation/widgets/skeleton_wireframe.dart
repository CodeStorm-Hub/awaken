import 'package:awaken/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Glowing skeletal wireframe overlay, drawn via CustomPainter.
/// Joint positions are normalized (0.0–1.0) representing a squatting pose.
/// Phase 4: replace [_staticJoints] with live ML Kit PoseLandmark data.
class SkeletonWireframe extends StatelessWidget {
  const SkeletonWireframe({super.key, this.accentColor});

  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _SkeletonPainter(accent: accentColor ?? AppColors.primary),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter({required this.accent});

  final Color accent;

  // Normalized joint positions (x, y) in a partial squat
  static const Map<String, Offset> _joints = {
    'head': Offset(0.50, 0.10),
    'neck': Offset(0.50, 0.18),
    'lShoulder': Offset(0.36, 0.25),
    'rShoulder': Offset(0.64, 0.25),
    'lElbow': Offset(0.27, 0.38),
    'rElbow': Offset(0.73, 0.38),
    'lWrist': Offset(0.20, 0.52),
    'rWrist': Offset(0.80, 0.52),
    'lHip': Offset(0.41, 0.50),
    'rHip': Offset(0.59, 0.50),
    'lKnee': Offset(0.37, 0.67),
    'rKnee': Offset(0.63, 0.67),
    'lAnkle': Offset(0.36, 0.83),
    'rAnkle': Offset(0.64, 0.83),
  };

  static const List<(String, String)> _connections = [
    ('head', 'neck'),
    ('neck', 'lShoulder'),
    ('neck', 'rShoulder'),
    ('lShoulder', 'lElbow'),
    ('lElbow', 'lWrist'),
    ('rShoulder', 'rElbow'),
    ('rElbow', 'rWrist'),
    ('lShoulder', 'lHip'),
    ('rShoulder', 'rHip'),
    ('lHip', 'rHip'),
    ('lHip', 'lKnee'),
    ('lKnee', 'lAnkle'),
    ('rHip', 'rKnee'),
    ('rKnee', 'rAnkle'),
  ];

  Offset _px(String joint, Size size) {
    final n = _joints[joint]!;
    return Offset(n.dx * size.width, n.dy * size.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final glowLinePaint = Paint()
      ..color = accent.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final sharpLinePaint = Paint()
      ..color = accent.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final jointGlowPaint = Paint()
      ..color = accent.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final jointSolidPaint = Paint()..color = accent;

    // ── Lines ──────────────────────────────────────────────────────
    for (final (from, to) in _connections) {
      final a = _px(from, size);
      final b = _px(to, size);
      canvas.drawLine(a, b, glowLinePaint);
      canvas.drawLine(a, b, sharpLinePaint);
    }

    // ── Joints ─────────────────────────────────────────────────────
    for (final key in _joints.keys) {
      final pos = _px(key, size);
      final radius = key == 'head' ? 6.0 : 3.5;
      canvas.drawCircle(pos, radius + 4, jointGlowPaint);
      canvas.drawCircle(pos, radius, jointSolidPaint);
    }
  }

  @override
  bool shouldRepaint(_SkeletonPainter old) => old.accent != accent;
}
