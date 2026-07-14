import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AnalyticsHistoryScreen extends ConsumerWidget {
  const AnalyticsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final tt = Theme.of(context).extension<AwakenTypography>()!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('ANALYTICS', style: tt.eyebrow),
        centerTitle: true,
      ),
      body: SafeArea(
        child: statsAsync.when(
          data: (stats) {
            final maxTrendVal = stats.repsTrend.isEmpty
                ? 10
                : stats.repsTrend.reduce((a, b) => a > b ? a : b);
            final double heightScale = maxTrendVal == 0 ? 1.0 : maxTrendVal.toDouble();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.screenPaddingH,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Streak details cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                              topRight: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                            border: Border.all(color: AppColors.border, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CURRENT STREAK', style: tt.statLabel),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.local_fire_department_rounded, color: AppColors.primary, size: 24),
                                  const SizedBox(width: 8),
                                  Text('${stats.currentStreak} Days', style: tt.statValue.copyWith(color: AppColors.primary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                              topRight: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                            border: Border.all(color: AppColors.border, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BEST STREAK', style: tt.statLabel),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.workspace_premium_rounded, color: AppColors.accent, size: 24),
                                  const SizedBox(width: 8),
                                  Text('${stats.bestStreak} Days', style: tt.statValue.copyWith(color: AppColors.accent)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 24),

                  // Trend Graph Card
                  Text('WEEKLY TRENDS (LAST 4 WEEKS)', style: tt.eyebrow),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SQUATS REPRESENTATION', style: tt.statLabel),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (int i = 0; i < stats.repsTrend.length; i++)
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: (stats.repsTrend[i] / heightScale) * 80 + 4,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            AppColors.primaryGlow.withValues(alpha: 0.2),
                                            AppColors.primary,
                                          ],
                                        ),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: AppColors.primaryGlow,
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'W${i + 1}',
                                      style: const TextStyle(
                                        fontFamily: 'SpaceMono',
                                        fontSize: 10,
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                    Text(
                                      '${stats.repsTrend[i]}',
                                      style: const TextStyle(
                                        fontFamily: 'SpaceMono',
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.foreground,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                  const SizedBox(height: 32),

                  // Achievements shelf
                  Text('ACHIEVEMENT BADGES', style: tt.eyebrow),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _BadgeIcon(icon: Icons.wb_sunny_rounded, title: 'Early Bird', unlocked: stats.currentStreak >= 3),
                          const SizedBox(width: 16),
                          _BadgeIcon(icon: Icons.shield_rounded, title: 'Defended', unlocked: stats.currentStreak >= 7),
                          const SizedBox(width: 16),
                          _BadgeIcon(icon: Icons.bolt_rounded, title: 'Loop Master', unlocked: stats.weeklyReps >= 30),
                          const SizedBox(width: 16),
                          _BadgeIcon(icon: Icons.workspace_premium_rounded, title: 'Legend', unlocked: stats.bestStreak >= 30),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading stats: $e')),
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({
    required this.icon,
    required this.title,
    required this.unlocked,
  });

  final IconData icon;
  final String title;
  final bool unlocked;

  @override
  Widget build(htmlContext) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: unlocked ? AppColors.primary.withValues(alpha: 0.1) : AppColors.secondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unlocked ? AppColors.primary : AppColors.border,
              width: unlocked ? 1.5 : 0.8,
            ),
            boxShadow: unlocked
                ? [
                    const BoxShadow(
                      color: AppColors.primaryGlow,
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: unlocked ? AppColors.primary : AppColors.mutedForeground.withValues(alpha: 0.5),
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: unlocked ? AppColors.foreground : AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
