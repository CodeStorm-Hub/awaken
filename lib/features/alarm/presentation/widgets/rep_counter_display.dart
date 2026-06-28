import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Oversized monospace rep counter centred on the camera HUD.
///
/// Displays:
///   [current]   ← 72px bold
///   ─────────
///   [required]  ← 36px muted
///
/// [AnimatedSwitcher] on [current] produces a quick fade when the count lands.
class RepCounterDisplay extends StatelessWidget {
  const RepCounterDisplay({
    super.key,
    required this.current,
    required this.required,
  });

  final int current;
  // ignore: avoid_field_initializers_in_const_classes
  final int required;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    final isComplete = current >= required;
    final countColor = isComplete ? AppColors.success : AppColors.foreground;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current count — animates on change
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: Tween<double>(begin: 0.7, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Text(
            '$current',
            key: ValueKey(current),
            style: tt.hudRepCounter.copyWith(color: countColor),
          ),
        ),

        // Divider
        Container(
          width: 52,
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: 6),
          color: AppColors.border,
        ),

        // Required count
        Text(
          '$required',
          style: tt.hudRepFraction,
        ),
      ],
    );
  }
}
