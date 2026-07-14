import 'dart:ui';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/services/exact_alarm_permission_service.dart';
import 'package:awaken/core/services/territory_decay_notification_service.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_exercise_type.dart';
import 'package:awaken/features/alarm/domain/services/alarm_bailout_service.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_providers.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_schedule_providers.dart';
import 'package:awaken/features/alarm/presentation/providers/squad_providers.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:awaken/features/dashboard/presentation/widgets/armed_alarm_card.dart';
import 'package:awaken/features/dashboard/presentation/widgets/digital_clock.dart';
import 'package:awaken/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:awaken/features/dashboard/presentation/widgets/streak_ring.dart';
import 'package:awaken/features/dashboard/presentation/widgets/week_trend_card.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _moreExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final applied = await const AlarmBailoutService().applyBailoutPenalties(
        repository: ref.read(alarmRepositoryProvider),
      );
      if (applied > 0) {
        ref.invalidate(alarmListProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final nextAlarm = ref.watch(nextAlarmProvider);
    final exactAlarmGranted = ref.watch(exactAlarmPermissionProvider);
    final exactAlarmDismissed = ref.watch(exactAlarmBannerDismissedProvider);
    final bailoutDismissed = ref.watch(bailoutBannerDismissedProvider);
    final guestSyncDismissed = ref.watch(guestSyncPromptDismissedProvider);
    final isSignedIn = ref.watch(isSignedInProvider);
    final user = ref.watch(currentUserProvider);
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    final size = MediaQuery.sizeOf(context);
    final showBailoutBanner =
        (nextAlarm?.penaltyMultiplier ?? 1) > 1 && !bailoutDismissed;

    // Surface a local notification once per dashboard load if any owned
    // territory is within its decay grace period (Product Decision #4).
    ref.listen(decayWarningsProvider, (previous, next) {
      next.whenData(
        (warnings) => TerritoryDecayNotificationService.notifyIfDecaying(
          territoryCount: warnings.length,
        ),
      );
    });

    // Locale-aware weekday/month names — was a hand-rolled English-only table.
    final dateStr = DateFormat.yMMMEd().format(DateTime.now());

    final stats = statsAsync.value;

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
              // ── Header ────────────────────────────────────────────────
              _Header(
                isSignedIn: isSignedIn,
                displayName: user?.displayName,
                avatarUrl: user?.avatarUrl,
                onAddAlarm: () => context.push(AppRoutes.alarmSetup),
                onProfileTap: () => context.push(AppRoutes.profile),
              ),
              if (!isSignedIn && !guestSyncDismissed) ...[
                const SizedBox(height: 12),
                _GuestSyncPrompt(
                  onSignIn: () => context.push(AppRoutes.auth),
                  onDismiss: () {
                    ref.read(guestSyncPromptDismissedProvider.notifier).state =
                        true;
                  },
                ),
              ],
              SizedBox(height: size.height * 0.04),

              // ── Digital clock ─────────────────────────────────────────
              const Center(child: DigitalClock()),
              const SizedBox(height: 8),
              Center(child: Text(dateStr, style: tt.eyebrow)),

              SizedBox(height: size.height * 0.04),

              // ── Exact alarm permission warning (Android 12+) ───────────
              if (exactAlarmGranted.value == false && !exactAlarmDismissed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ExactAlarmWarningCard(
                    tt: tt,
                    onOpenSettings: () async {
                      await ExactAlarmPermissionService.openSettings();
                      ref.invalidate(exactAlarmPermissionProvider);
                    },
                    onDismiss: () {
                      ref
                              .read(exactAlarmBannerDismissedProvider.notifier)
                              .state =
                          true;
                    },
                  ),
                ),

              if (showBailoutBanner)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _BailoutBanner(
                    multiplier: nextAlarm?.penaltyMultiplier ?? 2,
                    onDismiss: () {
                      ref.read(bailoutBannerDismissedProvider.notifier).state =
                          true;
                    },
                  ),
                ),

              // ── Squad nudge inbox ─────────────────────────────────────
              if (isSignedIn &&
                  (ref.watch(unseenSquadNudgeCountProvider).value ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _SquadNudgeBanner(
                    onDismiss: () async {
                      await markSquadNudgesSeen();
                      ref.invalidate(unseenSquadNudgeCountProvider);
                    },
                  ),
                ),

              // ── Hero: next armed alarm ────────────────────────────────
              if (nextAlarm != null)
                ArmedAlarmCard(
                  alarmTime: nextAlarm.scheduledTime,
                  requiredReps: nextAlarm.requiredReps,
                  exerciseMode: nextAlarm.exerciseMode,
                  exerciseType: nextAlarm.exerciseType,
                  penaltyMultiplier: nextAlarm.penaltyMultiplier,
                )
              else
                _NoAlarmCard(
                  tt: tt,
                  onTap: () => context.push(AppRoutes.alarmSetup),
                ),

              const SizedBox(height: 20),

              // ── Secondary stats ───────────────────────────────────────
              Text('THIS WEEK', style: tt.eyebrow),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _StreakCard(
                        progress: stats?.streakProgress ?? 0,
                        current: stats?.currentStreak ?? 0,
                        best: stats?.bestStreak ?? 0,
                        loading: statsAsync.isLoading,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'This Week',
                              value: stats != null
                                  ? '${stats.weeklyReps}'
                                  : '—',
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
                              value: stats != null
                                  ? '${stats.monthlyCalories}'
                                  : '—',
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

              const SizedBox(height: 12),

              // ── Rep trend (last 4 weeks) ──────────────────────────────
              // Hidden until there is at least one rep on record — an
              // all-zero chart is noise for a brand-new user.
              if (stats != null && stats.repsTrend.any((v) => v > 0))
                WeekTrendCard(repsTrend: stats.repsTrend),

              const SizedBox(height: 24),

              // ── Alarm list (swipe-to-delete) ──────────────────────────
              _AlarmList(alarms: ref.watch(alarmListProvider).value ?? []),

              const SizedBox(height: 24),

              // ── More: territory, rivals, customization ────────────────
              _MoreToggle(
                expanded: _moreExpanded,
                onTap: () {
                  setState(() => _moreExpanded = !_moreExpanded);
                },
              ),
              if (_moreExpanded) ...[
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.3,
                  children: [
                    _DevNavCard(
                      label: 'TERRITORY MAP',
                      subtitle: 'Run a loop, claim territory',
                      icon: Icons.map_rounded,
                      color: AppColors.primary,
                      onTap: () => context.go(AppRoutes.territory),
                    ),
                    _DevNavCard(
                      label: 'SQUAD TAXES',
                      icon: Icons.groups_rounded,
                      color: AppColors.accent,
                      onTap: () => context.push(AppRoutes.squads),
                    ),
                    _DevNavCard(
                      label: 'ANALYTICS',
                      icon: Icons.bar_chart_rounded,
                      color: AppColors.primary,
                      onTap: () => context.push(AppRoutes.analytics),
                    ),
                    _DevNavCard(
                      label: 'HUD SHOP',
                      icon: Icons.color_lens_rounded,
                      color: AppColors.success,
                      onTap: () => context.push(AppRoutes.customization),
                    ),
                    _DevNavCard(
                      label: 'BATTLE LOGS',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.destructive,
                      onTap: () => context.push(AppRoutes.rivalry),
                    ),
                    _DevNavCard(
                      label: 'MAP SUMMARY',
                      icon: Icons.info_outline_rounded,
                      color: AppColors.foreground,
                      onTap: () => context.push(AppRoutes.territoryOverview),
                    ),
                  ],
                ).animate().fadeIn(duration: 200.ms),
              ],

              const SizedBox(height: 12),

              // ── Dev shortcut ──────────────────────────────────────────
              if (kDebugMode) _TestAlarmButton(nextAlarm: nextAlarm),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.isSignedIn,
    required this.displayName,
    required this.avatarUrl,
    required this.onAddAlarm,
    required this.onProfileTap,
  });

  final bool isSignedIn;
  final String? displayName;
  final String? avatarUrl;
  final VoidCallback onAddAlarm;
  final VoidCallback onProfileTap;

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              GestureDetector(
                onTap: onProfileTap,
                child: Semantics(
                  button: true,
                  label: 'Profile',
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSignedIn
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : AppColors.border,
                        width: 1.5,
                      ),
                      boxShadow: isSignedIn
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipOval(
                      child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                          ? Image.network(
                              avatarUrl!,
                              fit: BoxFit.cover,
                              // Renders at 40px — decode small (3x for high-DPI).
                              cacheWidth: 120,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.person_rounded,
                                    size: 20,
                                    color: AppColors.mutedForeground,
                                  ),
                            )
                          : Icon(
                              isSignedIn
                                  ? Icons.person_rounded
                                  : Icons.person_outline_rounded,
                              size: 20,
                              color: isSignedIn
                                  ? AppColors.primary
                                  : AppColors.mutedForeground,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
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
                      isSignedIn && displayName != null
                          ? '${_greeting()}, ${displayName!.split(' ').first}'
                          : _greeting(),
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Add alarm
        GestureDetector(
          onTap: onAddAlarm,
          child: Semantics(
            button: true,
            label: 'Add alarm',
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.add_alarm_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExactAlarmWarningCard extends StatelessWidget {
  const _ExactAlarmWarningCard({
    required this.tt,
    required this.onOpenSettings,
    required this.onDismiss,
  });

  final AwakenTypography tt;
  final VoidCallback onOpenSettings;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
          color: AppColors.destructive.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.destructive,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALARMS MAY NOT FIRE',
                      style: tt.eyebrow.copyWith(color: AppColors.destructive),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Allow "Alarms & reminders" so your wake-up alarm can ring on time — then return here.',
                      style: tt.statLabel.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.mutedForeground,
                visualDensity: VisualDensity.compact,
                tooltip: 'Dismiss for now',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onOpenSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.destructive,
                foregroundColor: AppColors.foreground,
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('ENABLE EXACT ALARMS'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BailoutBanner extends StatelessWidget {
  const _BailoutBanner({required this.multiplier, required this.onDismiss});

  final int multiplier;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.destructive.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: InkWell(
        onTap: () => _showExplainer(context),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(
              color: AppColors.destructive.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.gavel_rounded,
                color: AppColors.destructive,
                size: 18,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Yesterday\'s bailout · tomorrow\'s tax is doubled',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.mutedForeground,
                size: 16,
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 16),
                color: AppColors.mutedForeground,
                visualDensity: VisualDensity.compact,
                tooltip: 'Dismiss for now',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExplainer(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WAKE UP TAX — DOUBLED',
              style: tt.eyebrow.copyWith(color: AppColors.destructive),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.destructive.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppConstants.chipRadius),
                border: Border.all(
                  color: AppColors.destructive.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                'ACTIVE · NEXT TAX ×$multiplier',
                style: const TextStyle(
                  color: AppColors.destructive,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _ExplainerRow(
              icon: Icons.snooze_rounded,
              title: 'What happened',
              body:
                  'An alarm went unfinished for '
                  '${AppConstants.bailoutWindow.inHours}+ hours — that\'s a '
                  'bailout. A squadmate\'s bailout counts too; squads share '
                  'the pain.',
            ),
            const SizedBox(height: 16),
            const _ExplainerRow(
              icon: Icons.gavel_rounded,
              title: 'The penalty',
              body:
                  'Your next wake-up tax is doubled. It never stacks '
                  'higher than 2×.',
            ),
            const SizedBox(height: 16),
            const _ExplainerRow(
              icon: Icons.check_circle_outline_rounded,
              title: 'How to clear it',
              body:
                  'Complete the doubled tax and you\'re back to normal — '
                  'no lingering debt.',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('GOT IT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplainerRow extends StatelessWidget {
  const _ExplainerRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SquadNudgeBanner extends StatelessWidget {
  const _SquadNudgeBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            color: AppColors.accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Your squad nudged you — show up for the next tax.',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 16),
            color: AppColors.mutedForeground,
            visualDensity: VisualDensity.compact,
            tooltip: 'Got it',
          ),
        ],
      ),
    );
  }
}

class _GuestSyncPrompt extends StatelessWidget {
  const _GuestSyncPrompt({required this.onSignIn, required this.onDismiss});

  final VoidCallback onSignIn;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: InkWell(
        onTap: onSignIn,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_sync_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Sign in to sync streaks & leaderboard',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 16),
                color: AppColors.mutedForeground,
                visualDensity: VisualDensity.compact,
                tooltip: 'Dismiss for now',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreToggle extends StatelessWidget {
  const _MoreToggle({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              expanded ? 'LESS' : 'TERRITORY, RIVALS & MORE',
              style: tt.eyebrow.copyWith(color: AppColors.accent),
            ),
            const SizedBox(width: 6),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: AppConstants.shortAnim,
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.accent,
              ),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 12),
                child: Divider(color: AppColors.border, height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.progress,
    required this.current,
    required this.best,
    required this.loading,
  });

  final double progress;
  final int current;
  final int best;
  final bool loading;

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
          loading
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : StreakRing(
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
  const _NoAlarmCard({required this.tt, required this.onTap});

  final AwakenTypography tt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_alarm_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'Tap to set your alarm',
                  style: tt.statLabel.copyWith(
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ── Alarm list with swipe-to-delete ──────────────────────────────────────────

class _AlarmList extends ConsumerWidget {
  const _AlarmList({required this.alarms});

  final List<AlarmEntity> alarms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (alarms.isEmpty) return const SizedBox.shrink();

    final tt = Theme.of(context).extension<AwakenTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SCHEDULED', style: tt.eyebrow),
        const SizedBox(height: 12),
        ...alarms.map(
          (alarm) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Dismissible(
              key: ValueKey(alarm.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: AppColors.destructive.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.destructive,
                ),
              ),
              onDismissed: (_) {
                ref.read(alarmListProvider.notifier).removeAlarm(alarm);
                // One accidental swipe shouldn't silently kill a wake-up
                // alarm — offer a short undo that re-saves and reschedules.
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: const Text('Alarm deleted'),
                      duration: const Duration(seconds: 5),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () {
                          ref
                              .read(alarmListProvider.notifier)
                              .restoreAlarm(alarm);
                        },
                      ),
                    ),
                  );
              },
              child: _AlarmTile(alarm: alarm),
            ),
          ),
        ),
      ],
    );
  }
}

class _AlarmTile extends ConsumerWidget {
  const _AlarmTile({required this.alarm});

  final AlarmEntity alarm;

  /// "20 SQUATS", "15 PUSH-UPS", or "20 ROULETTE" — mirrors ArmedAlarmCard.
  String get _taxLabel {
    final exercise = alarm.exerciseMode == AlarmExerciseMode.roulette
        ? 'ROULETTE'
        : (alarm.exerciseType ?? AlarmExerciseType.squats).taxStampLabel;
    return '${alarm.requiredReps} $exercise';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    // Respects the device's 12/24-hour clock setting.
    final timeLabel = TimeOfDay.fromDateTime(
      alarm.scheduledTime,
    ).format(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(timeLabel, style: tt.statValue.copyWith(fontSize: 22)),
              if (alarm.label != null) Text(alarm.label!, style: tt.statLabel),
            ],
          ),
          const Spacer(),
          Text(_taxLabel, style: tt.eyebrow.copyWith(color: AppColors.primary)),
          const SizedBox(width: 12),
          Semantics(
            label: 'Alarm $timeLabel',
            child: Switch(
              value: alarm.isActive,
              onChanged: (_) {
                ref.read(alarmListProvider.notifier).toggleAlarm(alarm);
              },
              activeThumbColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TestAlarmButton extends ConsumerWidget {
  const _TestAlarmButton({required this.nextAlarm});

  final AlarmEntity? nextAlarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.go(AppRoutes.activeAlarm, extra: nextAlarm),
        icon: const Icon(Icons.play_arrow_rounded, size: 18),
        label: const Text('Test Active Alarm'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          foregroundColor: AppColors.mutedForeground,
        ),
      ),
    );
  }
}

class _DevNavCard extends StatelessWidget {
  const _DevNavCard({
    required this.label,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 9,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

