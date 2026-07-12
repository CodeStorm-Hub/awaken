import 'dart:ui';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/services/exact_alarm_permission_service.dart';
import 'package:awaken/core/services/territory_decay_notification_service.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/domain/services/alarm_bailout_service.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_providers.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_schedule_providers.dart';
import 'package:awaken/features/alarm/presentation/widgets/squad_sheet.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:awaken/features/dashboard/presentation/widgets/armed_alarm_card.dart';
import 'package:awaken/features/dashboard/presentation/widgets/digital_clock.dart';
import 'package:awaken/features/dashboard/presentation/widgets/hud_theme_picker.dart';
import 'package:awaken/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:awaken/features/dashboard/presentation/widgets/streak_ring.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:awaken/features/territory/presentation/widgets/nemesis_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
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
    final isSignedIn = ref.watch(isSignedInProvider);
    final user = ref.watch(currentUserProvider);
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    final size = MediaQuery.sizeOf(context);
    final showBailoutBanner = (nextAlarm?.penaltyMultiplier ?? 1) > 1 &&
        !bailoutDismissed;

    // Surface a local notification once per dashboard load if any owned
    // territory is within its decay grace period (Product Decision #4).
    ref.listen(decayWarningsProvider, (previous, next) {
      next.whenData(
        (warnings) => TerritoryDecayNotificationService.notifyIfDecaying(
          territoryCount: warnings.length,
        ),
      );
    });

    final now = DateTime.now();
    final dateStr =
        '${_weekday(now.weekday)}, ${_month(now.month)} ${now.day}, ${now.year}';

    final stats = statsAsync.valueOrNull;

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
              if (!isSignedIn) ...[
                const SizedBox(height: 12),
                _GuestSyncPrompt(
                  onSignIn: () => context.push(AppRoutes.auth),
                ),
              ],
              SizedBox(height: size.height * 0.04),

              // ── Digital clock ─────────────────────────────────────────
              const Center(child: DigitalClock()),
              const SizedBox(height: 8),
              Center(child: Text(dateStr, style: tt.eyebrow)),

              SizedBox(height: size.height * 0.04),

              // ── Exact alarm permission warning (Android 12+) ───────────
              if (exactAlarmGranted.valueOrNull == false &&
                  !exactAlarmDismissed)
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
                          .state = true;
                    },
                  ),
                ),

              if (showBailoutBanner)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _BailoutBanner(
                    onDismiss: () {
                      ref.read(bailoutBannerDismissedProvider.notifier).state =
                          true;
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

              // ── Nemesis card (signed-in only) ─────────────────────────
              if (isSignedIn)
                ref.watch(nemesisProvider).whenOrNull(
                      data: (nemesis) => nemesis != null
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: NemesisCard(nemesis: nemesis),
                            )
                          : null,
                    ) ??
                const SizedBox.shrink(),

              // ── Territory capture entry point ──────────────────────────
              _TerritoryCard(
                tt: tt,
                onTap: () => context.go(AppRoutes.territory),
                onViewDetails: () => context.push(AppRoutes.territoryOverview),
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
                              value: stats != null ? '${stats.weeklyReps}' : '—',
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

              const SizedBox(height: 16),
              const HudThemePicker(),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => SquadSheet.show(context),
                child: const Text(
                  'SQUAD TAXES',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Alarm list (swipe-to-delete) ──────────────────────────
              _AlarmList(
                  alarms: ref.watch(alarmListProvider).valueOrNull ?? []),

              const SizedBox(height: 12),

              // ── Dev shortcut ──────────────────────────────────────────
              if (kDebugMode) _TestAlarmButton(nextAlarm: nextAlarm),
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
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: ClipOval(
                    child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                        ? Image.network(
                            avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
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
                      isSignedIn
                          ? 'Good morning${displayName != null ? ', ${displayName!.split(' ').first}' : ''}'
                          : 'Good morning',
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
  const _BailoutBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.destructive.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.gavel_rounded, color: AppColors.destructive, size: 18),
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
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 16),
            color: AppColors.mutedForeground,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _GuestSyncPrompt extends StatelessWidget {
  const _GuestSyncPrompt({required this.onSignIn});

  final VoidCallback onSignIn;

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.cloud_sync_outlined,
                  size: 18, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sign in to sync streaks & leaderboard',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18, color: AppColors.mutedForeground),
            ],
          ),
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
                  style: tt.statLabel.copyWith(fontSize: 14, color: AppColors.primary),
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

class _TerritoryCard extends StatelessWidget {
  const _TerritoryCard({
    required this.tt,
    required this.onTap,
    required this.onViewDetails,
  });

  final AwakenTypography tt;
  final VoidCallback onTap;
  final VoidCallback onViewDetails;

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
                color: AppColors.accent.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.map_rounded, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Run a loop, claim territory',
                    style: tt.statLabel.copyWith(fontSize: 14, color: AppColors.accent),
                  ),
                ),
                GestureDetector(
                  onTap: onViewDetails,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      'Details',
                      style: tt.statLabel.copyWith(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: AppColors.accent, size: 18),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    final time = TimeOfDay.fromDateTime(alarm.scheduledTime);
    final hour = time.hourOfPeriod.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

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
              Text(
                '$hour:$minute $period',
                style: tt.statValue.copyWith(fontSize: 22),
              ),
              if (alarm.label != null)
                Text(alarm.label!, style: tt.statLabel),
            ],
          ),
          const Spacer(),
          Text(
            '${alarm.requiredReps} squats',
            style: tt.eyebrow.copyWith(color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Switch(
            value: alarm.isActive,
            onChanged: (_) {
              ref.read(alarmListProvider.notifier).toggleAlarm(alarm);
            },
            activeThumbColor: AppColors.primary,
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
        onPressed: () => context.go(
          AppRoutes.activeAlarm,
          extra: nextAlarm,
        ),
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
