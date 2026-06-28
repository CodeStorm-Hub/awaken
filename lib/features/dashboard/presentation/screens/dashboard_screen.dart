import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:awaken/features/dashboard/presentation/widgets/armed_alarm_card.dart';
import 'package:awaken/features/dashboard/presentation/widgets/digital_clock.dart';
import 'package:awaken/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:awaken/features/dashboard/presentation/widgets/streak_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    final size = MediaQuery.sizeOf(context);

    // Date string — weekday + full date
    final now = DateTime.now();
    final weekday = _weekday(now.weekday);
    final dateStr =
        '$weekday, ${_month(now.month)} ${now.day}, ${now.year}';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────
              _Header(dateStr: dateStr),
              SizedBox(height: size.height * 0.05),

              // ── Oversized digital clock ───────────────────────────
              const Center(child: DigitalClock()),
              const SizedBox(height: 8),

              // Date sub-label
              Center(
                child: Text(dateStr, style: tt.eyebrow),
              ),

              SizedBox(height: size.height * 0.05),

              // ── Armed alarm card ──────────────────────────────────
              if (stats.nextAlarm != null)
                ArmedAlarmCard(
                  alarmTime: stats.nextAlarm!,
                  requiredReps: stats.nextAlarmReps,
                )
              else
                _NoAlarmCard(tt: tt),

              const SizedBox(height: 16),

              // ── Stats row ─────────────────────────────────────────
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Streak ring card
                    Expanded(
                      child: _StreakCard(
                        progress: stats.streakProgress,
                        current: stats.currentStreak,
                        best: stats.bestStreak,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Right column: reps + calories
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'This Week',
                              value: '${stats.weeklyReps}',
                              unit: 'reps',
                              icon: const Icon(
                                Icons.fitness_center_rounded,
                                color: AppColors.primary,
                                size: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: StatCard(
                              label: 'This Month',
                              value: '${stats.monthlyCalories}',
                              unit: 'cal',
                              accentColor: AppColors.accent,
                              icon: const Icon(
                                Icons.local_fire_department_rounded,
                                color: AppColors.accent,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Test alarm trigger (Phase 3 only — remove in Phase 4) ──
              const _TestAlarmButton(),
            ],
          ),
        ),
      ),
    );
  }

  static String _weekday(int d) => const [
        '',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ][d];

  static String _month(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][m];
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.dateStr});

  final String dateStr;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AWAKEN',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 4,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'Good morning',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),

        // Settings icon placeholder
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.settings_outlined, size: 18),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.progress,
    required this.current,
    required this.best,
  });

  final double progress;
  final int current;
  final int best;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('STREAK', style: tt.eyebrow),
          const SizedBox(height: 12),
          StreakRing(
            progress: progress,
            currentStreak: current,
            bestStreak: best,
          ),
        ],
      ),
    );
  }
}

class _NoAlarmCard extends StatelessWidget {
  const _NoAlarmCard({required this.tt});

  final AwakenTypography tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_alarm_rounded, color: AppColors.mutedForeground),
          const SizedBox(width: 12),
          Text('No alarm set', style: tt.statLabel.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}

class _TestAlarmButton extends ConsumerWidget {
  const _TestAlarmButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.go(AppRoutes.activeAlarm),
        icon: const Icon(Icons.play_arrow_rounded, size: 20),
        label: const Text('Test Alarm Now'),
      ),
    );
  }
}
