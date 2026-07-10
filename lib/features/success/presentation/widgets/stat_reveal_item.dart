import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Single stat row that floats up with a staggered delay on the success screen.
/// Converts to stateful to animate counting up from 0 to the target value
/// over 1 second, playing light haptic ticks on increment.
class StatRevealItem extends StatefulWidget {
  const StatRevealItem({
    super.key,
    required this.icon,
    required this.label,
    required this.targetValue,
    required this.unit,
    required this.delay,
    this.accentColor = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final int targetValue;
  final String unit;
  final Duration delay;
  final Color accentColor;

  @override
  State<StatRevealItem> createState() => _StatRevealItemState();
}

class _StatRevealItemState extends State<StatRevealItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int _lastValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0.0, end: widget.targetValue.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _animation.addListener(() {
      final current = _animation.value.round();
      if (current != _lastValue) {
        _lastValue = current;
        HapticFeedback.lightImpact();
      }
    });

    // Start count up after staggered entry delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final displayVal = _animation.value.round();
          return Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.accentColor, size: 18),
              ),
              const SizedBox(width: 14),

              // Label
              Expanded(
                child: Text(
                  widget.label,
                  style: tt.statLabel.copyWith(fontSize: 13),
                ),
              ),

              // Value + unit
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$displayVal',
                      style: tt.statValue.copyWith(
                        fontSize: 22,
                        color: widget.accentColor,
                      ),
                    ),
                    TextSpan(text: ' ${widget.unit}', style: tt.statLabel),
                  ],
                ),
              ),
            ],
          );
        },
      )
          .animate(delay: widget.delay)
          .fadeIn(duration: 400.ms)
          .slideY(
            begin: 0.25,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }
}
