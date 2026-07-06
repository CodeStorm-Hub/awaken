import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/services/alarm_notification_service.dart';
import 'package:awaken/core/services/exact_alarm_permission_service.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_schedule_providers.dart';
import 'package:awaken/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AlarmSetupScreen extends ConsumerStatefulWidget {
  const AlarmSetupScreen({super.key});

  @override
  ConsumerState<AlarmSetupScreen> createState() => _AlarmSetupScreenState();
}

class _AlarmSetupScreenState extends ConsumerState<AlarmSetupScreen> {
  TimeOfDay _time = TimeOfDay.now();
  int _reps = 10;
  String _label = '';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPaddingH,
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ────────────────────────────────────────────────
              Text('SET ALARM', style: tt.eyebrow)
                  .animate()
                  .fadeIn(duration: 300.ms),
              const SizedBox(height: 32),

              // ── Time picker ──────────────────────────────────────────
              _TimeTile(
                time: _time,
                onTap: _pickTime,
                typography: tt,
              ).animate().fadeIn(delay: 80.ms, duration: 300.ms),

              const SizedBox(height: 32),

              // ── Rep count ────────────────────────────────────────────
              Text('WAKE UP TAX', style: tt.eyebrow),
              const SizedBox(height: 16),
              _RepSelector(
                value: _reps,
                onDecrement: () {
                  HapticFeedback.lightImpact();
                  setState(() => _reps = (_reps - 5).clamp(5, 50));
                },
                onIncrement: () {
                  HapticFeedback.lightImpact();
                  setState(() => _reps = (_reps + 5).clamp(5, 50));
                },
              ).animate().fadeIn(delay: 140.ms, duration: 300.ms),

              const SizedBox(height: 32),

              // ── Label ────────────────────────────────────────────────
              Text('LABEL (OPTIONAL)', style: tt.eyebrow),
              const SizedBox(height: 12),
              _LabelField(
                onChanged: (v) => _label = v,
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

              const SizedBox(height: 48),

              // ── ARM button ───────────────────────────────────────────
              _ArmButton(
                saving: _saving,
                onPressed: _save,
              ).animate().fadeIn(delay: 280.ms, duration: 300.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'SELECT ALARM TIME',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          materialTapTargetSize: MaterialTapTargetSize.padded,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await AlarmNotificationService.requestPermissions();

      if (ExactAlarmPermissionService.isAndroid &&
          !await ExactAlarmPermissionService.isGranted()) {
        if (!mounted) return;
        final action = await _showExactAlarmPermissionDialog();
        if (action == _ExactAlarmDialogAction.cancel) {
          setState(() => _saving = false);
          return;
        }
        if (action == _ExactAlarmDialogAction.openSettings) {
          await ExactAlarmPermissionService.openSettings();
          ref.invalidate(exactAlarmPermissionProvider);
          if (!mounted) return;
          final granted = await ExactAlarmPermissionService.isGranted();
          if (!mounted) return;
          if (!granted) {
            final messenger = ScaffoldMessenger.of(context);
            setState(() => _saving = false);
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                  'Exact alarm permission still denied — your alarm may not fire on time.',
                ),
                backgroundColor: AppColors.destructive,
              ),
            );
            return;
          }
        }
      }

      final now = DateTime.now();
      // Next occurrence of the selected time (today or tomorrow if past)
      var scheduled = DateTime(
        now.year,
        now.month,
        now.day,
        _time.hour,
        _time.minute,
      );
      if (scheduled.isBefore(now.add(const Duration(minutes: 1)))) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final alarm = AlarmEntity(
        id: scheduled.millisecondsSinceEpoch.toString(),
        scheduledTime: scheduled,
        requiredReps: _reps,
        isActive: true,
        label: _label.isEmpty ? null : _label.trim(),
      );

      await ref.read(alarmListProvider.notifier).addAlarm(alarm);

      if (mounted) {
        setState(() => _saving = false);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save alarm: $e'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    }
  }

  Future<_ExactAlarmDialogAction> _showExactAlarmPermissionDialog() {
    return showDialog<_ExactAlarmDialogAction>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Allow exact alarms'),
        content: const Text(
          'Awaken needs "Alarms & reminders" permission so your wake-up alarm '
          'fires at the exact time you set — even when the phone is locked.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _ExactAlarmDialogAction.cancel),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.mutedForeground),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              _ExactAlarmDialogAction.saveWithoutPermission,
            ),
            child: const Text('Save Anyway'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              _ExactAlarmDialogAction.openSettings,
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    ).then((value) => value ?? _ExactAlarmDialogAction.cancel);
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

enum _ExactAlarmDialogAction {
  cancel,
  openSettings,
  saveWithoutPermission,
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.time,
    required this.onTap,
    required this.typography,
  });

  final TimeOfDay time;
  final VoidCallback onTap;
  final AwakenTypography typography;

  @override
  Widget build(BuildContext context) {
    final hour = time.hourOfPeriod.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$hour:$minute',
              style: typography.hudClock.copyWith(fontSize: 64),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                period,
                style: typography.statValue.copyWith(
                  color: AppColors.primary,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepSelector extends StatelessWidget {
  const _RepSelector({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;

    const totalTicks = 10;
    final currentTickIndex = (value - 5) ~/ 5; // 0 to 9

    final (tierLabel, tierColor) = _getTaxTier(value);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Decrement
              _RepButton(
                icon: Icons.remove_rounded,
                onTap: onDecrement,
              ),

              // Count + label
              Column(
                children: [
                  AnimatedSwitcher(
                    duration: AppConstants.shortAnim,
                    child: Text(
                      '$value',
                      key: ValueKey(value),
                      style: tt.statValue.copyWith(fontSize: 48),
                    ),
                  ),
                  Text('squats', style: tt.statLabel),
                ],
              ),

              // Increment
              _RepButton(
                icon: Icons.add_rounded,
                onTap: onIncrement,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Segmented Ticks Visualizer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalTicks, (index) {
              final isActive = index <= currentTickIndex;
              final isTarget = index == currentTickIndex;
              final dotColor = isTarget
                  ? tierColor
                  : (isActive ? tierColor.withValues(alpha: 0.5) : AppColors.secondary);
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.symmetric(
                    horizontal: index == 0 || index == totalTicks - 1 ? 0 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: dotColor,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isTarget
                        ? [
                            BoxShadow(
                              color: tierColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Colored Tax Tier Chip
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.chipRadius),
              border: Border.all(color: tierColor.withValues(alpha: 0.3), width: 1),
            ),
            child: Text(
              tierLabel,
              style: TextStyle(
                color: tierColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _getTaxTier(int reps) {
    if (reps <= 15) return ('CHILL TAX', AppColors.success);
    if (reps <= 35) return ('ENFORCED WAKEUP', AppColors.primary);
    return ('GRAVEYARD PROTOCOL', AppColors.destructive);
  }
}

class _RepButton extends StatelessWidget {
  const _RepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.secondary,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.foreground, size: 22),
      ),
    );
  }
}

class _LabelField extends StatelessWidget {
  const _LabelField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'e.g. Morning Grind',
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedForeground,
            ),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.chipRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.chipRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.chipRadius),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _ArmButton extends StatelessWidget {
  const _ArmButton({required this.saving, required this.onPressed});

  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: saving ? null : onPressed,
        child: saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            : const Text('ARM ALARM'),
      ),
    );
  }
}
