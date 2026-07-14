import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/domain/services/alarm_bailout_service.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_providers.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_schedule_providers.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:awaken/features/sessions/domain/entities/session_entity.dart';
import 'package:awaken/features/sessions/presentation/providers/session_providers.dart';
import 'package:awaken/features/success/presentation/widgets/stat_reveal_item.dart';
import 'package:awaken/features/success/presentation/widgets/streak_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SuccessScreen extends ConsumerStatefulWidget {
  const SuccessScreen({super.key, this.alarm});
  final AlarmEntity? alarm;

  @override
  ConsumerState<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends ConsumerState<SuccessScreen> {
  late final int _repsCompleted;
  late final int _durationSeconds;
  late final int _caloriesBurned;
  late final bool _usedAccessibilityMode;
  late final int _streakBefore;
  bool _sessionRecorded = false;
  bool _isSaving = true;

  @override
  void initState() {
    super.initState();
    _repsCompleted = ref.read(repCountProvider);
    _usedAccessibilityMode = ref.read(accessibilitySessionProvider);
    _streakBefore = ref.read(dashboardStatsProvider).value?.currentStreak ?? 0;
    final startTime = ref.read(sessionStartTimeProvider);
    _durationSeconds = startTime != null
        ? DateTime.now().difference(startTime).inSeconds
        : 0;
    _caloriesBurned = SessionEntity.estimateCalories(_repsCompleted);

    // Record session to Supabase if signed in (fire-and-forget — don't block UI)
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordSession());
  }

  Future<void> _recordSession() async {
    if (_sessionRecorded) return;
    _sessionRecorded = true;

    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? SessionEntity.localGuestUserId;

    try {
      // Persist workout first so a notification cancel failure cannot drop it.
      await ref
          .read(sessionRepositoryProvider)
          .recordSession(
            SessionEntity(
              userId: userId,
              alarmId: widget.alarm?.id,
              completedAt: DateTime.now(),
              repsCompleted: _repsCompleted,
              durationSeconds: _durationSeconds,
              caloriesBurned: _caloriesBurned,
            ),
          );

      if (widget.alarm != null) {
        await ref.read(alarmListProvider.notifier).markCompleted(widget.alarm!);
        await const AlarmBailoutService().resolveForAlarm(widget.alarm!.id);
      }

      ref.invalidate(dashboardStatsProvider);
      await ref.read(dashboardStatsProvider.future);
    } catch (e) {
      debugPrint('[Session] Failed to record: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _startMyDay() {
    ref.read(repCountProvider.notifier).setCount(0);
    ref.read(repFeedbackProvider.notifier).setFeedback(RepFeedback.neutral);
    ref.read(sessionStartTimeProvider.notifier).setStartTime(null);
    ref.read(accessibilitySessionProvider.notifier).setUsed(false);
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    final statsAsync = ref.watch(dashboardStatsProvider);
    final currentStreak = statsAsync.value?.currentStreak ?? 0;

    return PopScope(
      canPop: false,
      child: Scaffold(
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
                if (_isSaving)
                  const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  StreakBadge(
                    streak: currentStreak,
                    previousStreak: _streakBefore,
                  ),

                if (_usedAccessibilityMode && !_isSaving) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Some reps were counted in accessibility mode',
                    textAlign: TextAlign.center,
                    style: tt.statLabel.copyWith(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ],

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

                StatRevealItem(
                  icon: Icons.fitness_center_rounded,
                  label: 'Squats completed',
                  targetValue: _repsCompleted,
                  unit: 'reps',
                  delay: AppConstants.floatUpDelay0,
                ),
                const SizedBox(height: 14),

                StatRevealItem(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Calories burned',
                  targetValue: _caloriesBurned,
                  unit: 'kcal',
                  delay: AppConstants.floatUpDelay1,
                  accentColor: AppColors.accent,
                ),
                const SizedBox(height: 14),

                StatRevealItem(
                  icon: Icons.timer_outlined,
                  label: 'Wake-up time',
                  targetValue: _durationSeconds,
                  unit: 'sec',
                  delay: AppConstants.floatUpDelay2,
                  accentColor: AppColors.success,
                ),

                const SizedBox(height: 40),

                // ── Motivational quote ────────────────────────────────
                const _MotivationalQuote(delay: AppConstants.floatUpDelay3),

                const SizedBox(height: 40),

                // ── CTA ───────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _startMyDay,
                    child: const Text('Start My Day'),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _MotivationalQuote extends StatefulWidget {
  const _MotivationalQuote({required this.delay});

  final Duration delay;

  @override
  State<_MotivationalQuote> createState() => _MotivationalQuoteState();
}

class _MotivationalQuoteState extends State<_MotivationalQuote>
    with SingleTickerProviderStateMixin {
  late final String _quote;
  late final AnimationController _charCtrl;
  late final Animation<int> _charCountAnim;
  int _lastCharCount = 0;

  static const _quotes = [
    'The morning is the foundation of the day.',
    'Discipline is choosing between what you want now and what you want most.',
    'Every rep is a vote for the person you want to become.',
    'Rise and conquer.',
  ];

  @override
  void initState() {
    super.initState();
    final idx = DateTime.now().day % _quotes.length;
    _quote = '"${_quotes[idx]}"';

    final duration = Duration(milliseconds: _quote.length * 30);
    _charCtrl = AnimationController(vsync: this, duration: duration);

    _charCountAnim = IntTween(
      begin: 0,
      end: _quote.length,
    ).animate(CurvedAnimation(parent: _charCtrl, curve: Curves.linear));

    _charCountAnim.addListener(() {
      final current = _charCountAnim.value;
      if (current != _lastCharCount) {
        _lastCharCount = current;
        if (current % 2 == 0) {
          HapticFeedback.lightImpact();
        }
      }
    });

    Future.delayed(widget.delay, () {
      if (mounted) {
        _charCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _charCtrl.dispose();
    super.dispose();
  }

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
      child: AnimatedBuilder(
        animation: _charCountAnim,
        builder: (context, child) {
          final visibleText = _quote.substring(0, _charCountAnim.value);
          return Text(
            visibleText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.mutedForeground,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          );
        },
      ),
    );
  }
}
