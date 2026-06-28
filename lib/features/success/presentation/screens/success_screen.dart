import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:awaken/features/success/presentation/widgets/stat_reveal_item.dart';
import 'package:awaken/features/success/presentation/widgets/streak_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SuccessScreen extends ConsumerWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final tt = Theme.of(context).extension<AwakenTypography>()!;

    // Simulate session values — Phase 4 will pass these via route extra
    const sessionReps = 10;
    const sessionCalories = 28;
    const sessionSeconds = 47;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPaddingH,
            vertical: AppConstants.screenPaddingV,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // ── Streak badge ───────────────────────────────────────
              StreakBadge(streak: stats.currentStreak),

              const SizedBox(height: 48),

              // ── Divider ───────────────────────────────────────────
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 28),

              // ── Session stats — staggered reveal ──────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text('SESSION SUMMARY', style: tt.eyebrow),
              ),
              const SizedBox(height: 16),

              const StatRevealItem(
                icon: Icons.fitness_center_rounded,
                label: 'Squats completed',
                value: '$sessionReps',
                unit: 'reps',
                delay: AppConstants.floatUpDelay0,
              ),
              const SizedBox(height: 14),

              const StatRevealItem(
                icon: Icons.local_fire_department_rounded,
                label: 'Calories burned',
                value: '$sessionCalories',
                unit: 'kcal',
                delay: AppConstants.floatUpDelay1,
                accentColor: AppColors.accent,
              ),
              const SizedBox(height: 14),

              const StatRevealItem(
                icon: Icons.timer_outlined,
                label: 'Wake-up time',
                value: '$sessionSeconds',
                unit: 'sec',
                delay: AppConstants.floatUpDelay2,
                accentColor: AppColors.success,
              ),

              const SizedBox(height: 40),

              // ── Motivational quote ────────────────────────────────
              const _MotivationalQuote(delay: AppConstants.floatUpDelay3),

              const SizedBox(height: 40),

              // ── CTA ───────────────────────────────────────────────
              const _StartMyDayButton(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _MotivationalQuote extends StatelessWidget {
  const _MotivationalQuote({required this.delay});

  final Duration delay;

  static const _quotes = [
    'The morning is the foundation of the day.',
    'Discipline is choosing between what you want now and what you want most.',
    'Every rep is a vote for the person you want to become.',
    'Rise and conquer.',
  ];

  @override
  Widget build(BuildContext context) {
    // Fixed quote per day — no random to keep it deterministic per session
    final idx = DateTime.now().day % _quotes.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '"${_quotes[idx]}"',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.mutedForeground,
              height: 1.6,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _StartMyDayButton extends ConsumerWidget {
  const _StartMyDayButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.go(AppRoutes.dashboard),
        child: const Text('Start My Day'),
      ),
    );
  }
}
