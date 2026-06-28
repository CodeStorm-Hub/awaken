import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_providers.dart';
import 'package:awaken/features/alarm/presentation/widgets/camera_hud_overlay.dart';
import 'package:awaken/features/alarm/presentation/widgets/rep_counter_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ActiveAlarmScreen extends ConsumerWidget {
  const ActiveAlarmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedback = ref.watch(repFeedbackProvider);
    final repCount = ref.watch(repCountProvider);
    final requiredReps = ref.watch(requiredRepsProvider);

    final borderColor = switch (feedback) {
      RepFeedback.neutral => AppColors.border,
      RepFeedback.success => AppColors.success,
      RepFeedback.failure => AppColors.destructive,
    };

    final glowColor = switch (feedback) {
      RepFeedback.neutral => Colors.transparent,
      RepFeedback.success => AppColors.successGlow,
      RepFeedback.failure => AppColors.destructiveGlow,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onTap(context, ref, repCount, requiredReps),
          child: AnimatedContainer(
            duration: AppConstants.shortAnim,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(AppConstants.cardRadius),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(color: glowColor, blurRadius: 24, spreadRadius: 6),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Layer 1: Camera feed + skeleton + scan line
                const CameraHudOverlay(),

                // Layer 2: Rep counter centred
                Center(
                  child: RepCounterDisplay(
                    current: repCount,
                    required: requiredReps,
                  ),
                ),

                // Layer 3: Top instruction bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _InstructionBar(feedback: feedback),
                ),

                // Layer 4: Bottom "wake up tax" label
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: _WakeUpTaxLabel(
                    repCount: repCount,
                    required: requiredReps,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(
    BuildContext context,
    WidgetRef ref,
    int current,
    int required,
  ) {
    if (current >= required) return;

    final next = current + 1;
    ref.read(repCountProvider.notifier).state = next;
    ref.read(repFeedbackProvider.notifier).state = RepFeedback.success;

    Future.delayed(AppConstants.shortAnim, () {
      ref.read(repFeedbackProvider.notifier).state = RepFeedback.neutral;
    });

    if (next >= required) {
      Future.delayed(AppConstants.mediumAnim, () {
        if (context.mounted) {
          _resetSession(ref);
          context.go(AppRoutes.success);
        }
      });
    }
  }

  void _resetSession(WidgetRef ref) {
    ref.read(repCountProvider.notifier).state = 0;
    ref.read(repFeedbackProvider.notifier).state = RepFeedback.neutral;
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _InstructionBar extends StatelessWidget {
  const _InstructionBar({required this.feedback});

  final RepFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final label = switch (feedback) {
      RepFeedback.neutral => 'TAP TO SIMULATE REP',
      RepFeedback.success => 'PERFECT REP ✓',
      RepFeedback.failure => 'BAD FORM — TRY AGAIN',
    };
    final color = switch (feedback) {
      RepFeedback.neutral => AppColors.mutedForeground,
      RepFeedback.success => AppColors.success,
      RepFeedback.failure => AppColors.destructive,
    };

    return AnimatedContainer(
      duration: AppConstants.shortAnim,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.5,
        ),
      ),
    );
  }
}

class _WakeUpTaxLabel extends StatelessWidget {
  const _WakeUpTaxLabel({required this.repCount, required this.required});

  final int repCount;
  final int required;

  @override
  Widget build(BuildContext context) {
    final remaining = required - repCount;
    final isDone = remaining <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Text(
        isDone ? 'COMPLETE — WAKING UP...' : '$remaining SQUATS REMAINING',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDone ? AppColors.success : AppColors.mutedForeground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
