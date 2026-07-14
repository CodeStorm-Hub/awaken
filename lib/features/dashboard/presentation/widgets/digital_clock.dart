import 'dart:ui';

import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ticking digital clock — updates once per minute.
/// Watches [clockDisplayProvider] (not [clockProvider]) so the widget
/// rebuilds at most once per minute, not every second.
class DigitalClock extends ConsumerWidget {
  const DigitalClock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    final timeAsync = ref.watch(clockDisplayProvider);
    final display = timeAsync.value ?? '--:--';

    final hh = display.substring(0, 2);
    final mm = display.substring(3, 5);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.8,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
                  child: child,
                ),
              ),
              child: Text.rich(
                key: ValueKey(display),
                TextSpan(
                  style: tt.hudClock,
                  children: [
                    TextSpan(text: hh),
                    TextSpan(
                      text: ':',
                      style: tt.hudClock.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    TextSpan(text: mm),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
