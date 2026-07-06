import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Oversized monospace rep counter centred on the camera HUD.
/// Converts to stateful to trigger a expanding neon ring shockwave behind
/// the numbers whenever the rep count increases.
class RepCounterDisplay extends StatefulWidget {
  const RepCounterDisplay({
    super.key,
    required this.current,
    required this.required,
  });

  final int current;
  final int required;

  @override
  State<RepCounterDisplay> createState() => _RepCounterDisplayState();
}

class _RepCounterDisplayState extends State<RepCounterDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shockwaveCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _shockwaveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.4, end: 1.6).animate(
      CurvedAnimation(parent: _shockwaveCtrl, curve: Curves.easeOutCubic),
    );
    _opacityAnim = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _shockwaveCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant RepCounterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.current > oldWidget.current) {
      _shockwaveCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _shockwaveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    final isComplete = widget.current >= widget.required;
    final countColor = isComplete ? AppColors.success : AppColors.foreground;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Concentric Shockwave Ring
        AnimatedBuilder(
          animation: _shockwaveCtrl,
          builder: (context, child) {
            if (!_shockwaveCtrl.isAnimating) return const SizedBox.shrink();
            final size = 120.0 * _scaleAnim.value;
            final isSuccess = widget.current >= widget.required;
            final ringColor = isSuccess ? AppColors.success : AppColors.primary;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ringColor.withValues(alpha: _opacityAnim.value),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ringColor.withValues(alpha: _opacityAnim.value * 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            );
          },
        ),

        // Text & Layout Column
        Column(
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
                '${widget.current}',
                key: ValueKey(widget.current),
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
              '${widget.required}',
              style: tt.hudRepFraction,
            ),
          ],
        ),
      ],
    );
  }
}
