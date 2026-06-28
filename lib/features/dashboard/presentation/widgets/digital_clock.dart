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
    final display = timeAsync.valueOrNull ?? '--:--';

    final hh = display.substring(0, 2);
    final mm = display.substring(3, 5);

    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
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
    );
  }
}
