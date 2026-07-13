import 'dart:async';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart' show AppRoutes, appRouterProvider;
import 'package:awaken/core/services/alarm_audio_service.dart';
import 'package:awaken/core/services/wake_lock_service.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/hud_theme.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_exercise_type.dart';
import 'package:awaken/features/alarm/domain/services/alarm_bailout_service.dart';
import 'package:awaken/features/alarm/domain/services/exercise_counter_router.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_providers.dart';
import 'package:awaken/features/alarm/presentation/providers/squad_providers.dart';
import 'package:awaken/features/alarm/presentation/services/alarm_pose_pipeline.dart';
import 'package:awaken/features/alarm/presentation/widgets/camera_hud_overlay.dart';
import 'package:awaken/features/alarm/presentation/widgets/rep_counter_display.dart';
import 'package:awaken/features/alarm/presentation/widgets/squad_tax_rail.dart';
import 'package:awaken/features/alarm/presentation/widgets/tax_reveal_stamp.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class ActiveAlarmScreen extends ConsumerStatefulWidget {
  const ActiveAlarmScreen({super.key, this.alarm});

  final AlarmEntity? alarm;

  @override
  ConsumerState<ActiveAlarmScreen> createState() => _ActiveAlarmScreenState();
}

class _ActiveAlarmScreenState extends ConsumerState<ActiveAlarmScreen>
    with WidgetsBindingObserver {
  late final AlarmPosePipeline _pipeline;
  late final ExerciseCounterRouter _exerciseRouter;
  Timer? _outOfFramePenaltyTimer;
  late final GoRouter _router;
  bool _cameraPermissionDenied = false;
  bool _cameraReady = false;
  bool _showTaxReveal = true;
  bool _isActivePhase = false;
  bool _isCalibrated = false;
  String? _liveCue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = ref.read(appRouterProvider);

    final alarm = widget.alarm;
    final exercise = resolveSessionExercise(
      mode: alarm?.exerciseMode ?? AlarmExerciseMode.fixed,
      fixedType: alarm?.exerciseType,
      alarmId: alarm?.id ?? 'orphan',
    );
    _exerciseRouter = ExerciseCounterRouter(type: exercise);
    _exerciseRouter.reset();

    _pipeline = AlarmPosePipeline(onPoseResult: _onPoseResult);
    _pipeline.permissionDenied.addListener(_onPermissionChanged);
    _pipeline.isReady.addListener(_onReadyChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetAlarmSession(ref);
      ref.read(activeExerciseTypeProvider.notifier).setType(exercise);
      final multiplier = alarm?.penaltyMultiplier ?? 1;
      ref.read(activePenaltyMultiplierProvider.notifier).setMultiplier(multiplier);
      final int reps = alarm != null
          ? alarm.effectiveRequiredReps
          : ref.read(requiredRepsProvider);
      ref.read(requiredRepsProvider.notifier).setRequired(reps);

      if (alarm != null) {
        unawaited(
          const AlarmBailoutService().recordFire(
            alarm: alarm,
            exerciseType: exercise,
            requiredReps: reps,
          ),
        );
      }

      Future.delayed(AppConstants.taxRevealDuration, () {
        if (mounted) setState(() => _showTaxReveal = false);
      });
    });

    WakeLockService.enable();
    AlarmAudioService.start();
    AlarmAudioService.resetVolume();
    _pipeline.start();
  }

  void _onPermissionChanged() {
    if (!mounted) return;
    setState(() => _cameraPermissionDenied = _pipeline.permissionDenied.value);
  }

  void _onReadyChanged() {
    if (!mounted) return;
    setState(() => _cameraReady = _pipeline.isReady.value);
  }

  /// Release the camera while backgrounded and re-open it on return —
  /// holding the camera in the background breaks it on many Android devices.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        unawaited(_pipeline.pauseForLifecycle());
      case AppLifecycleState.resumed:
        unawaited(_pipeline.resumeAfterLifecycle());
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _outOfFramePenaltyTimer?.cancel();
    _pipeline.permissionDenied.removeListener(_onPermissionChanged);
    _pipeline.isReady.removeListener(_onReadyChanged);
    unawaited(_pipeline.dispose());
    WakeLockService.disable();
    AlarmAudioService.stop();
    super.dispose();
  }

  void _onPoseResult(Pose? pose) {
    if (!mounted) return;

    if (pose == null) {
      _setOutOfFrame(true);
      if (_isActivePhase || _isCalibrated) {
        setState(() {
          _isActivePhase = _exerciseRouter.counter.isInActivePhase;
          _isCalibrated = _exerciseRouter.counter.isCalibrated;
        });
      }
      return;
    }

    _setOutOfFrame(false);
    final wasCalibratedBefore = _exerciseRouter.counter.isCalibrated;
    final result = _exerciseRouter.counter.processPose(pose);

    final phaseChanged = _isActivePhase != _exerciseRouter.counter.isInActivePhase ||
        _isCalibrated != _exerciseRouter.counter.isCalibrated ||
        _liveCue != result.cue;
    if (phaseChanged) {
      setState(() {
        _isActivePhase = _exerciseRouter.counter.isInActivePhase;
        _isCalibrated = _exerciseRouter.counter.isCalibrated;
        _liveCue = result.cue;
      });
    }

    if (result.cue != null) {
      ref.read(exerciseCueProvider.notifier).setCue(result.cue);
    }

    if (!wasCalibratedBefore && _exerciseRouter.counter.isCalibrated) {
      HapticFeedback.mediumImpact();
    }

    if (result.repCompleted) {
      _onRepCompleted();
    } else if (result.badForm) {
      _onBadForm();
    }

    if (result.depthRatio != null) {
      ref.read(squatDepthRatioProvider.notifier).setRatio(result.depthRatio!);
    }
  }

  void _setOutOfFrame(bool outOfFrame) {
    ref.read(outOfFrameProvider.notifier).setOutOfFrame(outOfFrame);
    if (outOfFrame) {
      _outOfFramePenaltyTimer ??= Timer.periodic(
        const Duration(seconds: AppConstants.outOfFramePenaltySeconds),
        (_) => AlarmAudioService.rampVolumeUp(),
      );
      return;
    }

    _outOfFramePenaltyTimer?.cancel();
    _outOfFramePenaltyTimer = null;
    AlarmAudioService.resetVolume();
  }

  void _onBadForm() {
    ref.read(repFeedbackProvider.notifier).setFeedback(RepFeedback.failure);
    Future.delayed(AppConstants.shortAnim, () {
      if (mounted) {
        ref.read(repFeedbackProvider.notifier).setFeedback(RepFeedback.neutral);
      }
    });
  }

  void _onRepCompleted() {
    final current = ref.read(repCountProvider);
    final required = ref.read(requiredRepsProvider);
    if (current >= required) return;

    final next = current + 1;
    ref.read(repCountProvider.notifier).setCount(next);
    ref.read(repFeedbackProvider.notifier).setFeedback(RepFeedback.success);

    if (next >= required) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    Future.delayed(AppConstants.shortAnim, () {
      if (mounted) {
        ref.read(repFeedbackProvider.notifier).setFeedback(RepFeedback.neutral);
      }
    });

    if (next >= required) {
      Future.delayed(AppConstants.mediumAnim, () {
        if (!mounted) return;
        _router.go(AppRoutes.success, extra: widget.alarm);
      });
    }
  }

  /// Accessibility fallback when camera permission is denied — labeled in HUD.
  void _onTap() {
    if (!_cameraPermissionDenied) return;
    final current = ref.read(repCountProvider);
    final required = ref.read(requiredRepsProvider);
    if (current >= required) return;
    if (current >= AppConstants.accessibilityMaxTapReps) return;

    ref.read(accessibilitySessionProvider.notifier).setUsed(true);
    final next = current + 1;
    ref.read(repCountProvider.notifier).setCount(next);
    ref.read(repFeedbackProvider.notifier).setFeedback(RepFeedback.success);
    if (next >= required) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
    Future.delayed(AppConstants.shortAnim, () {
      if (mounted) {
        ref.read(repFeedbackProvider.notifier).setFeedback(RepFeedback.neutral);
      }
    });
    if (next >= required) {
      Future.delayed(AppConstants.mediumAnim, () {
        if (!mounted) return;
        _router.go(AppRoutes.success, extra: widget.alarm);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedback = ref.watch(repFeedbackProvider);
    final repCount = ref.watch(repCountProvider);
    final requiredReps = ref.watch(requiredRepsProvider);
    final outOfFrame = ref.watch(outOfFrameProvider);
    final depthRatio = ref.watch(squatDepthRatioProvider);
    final exerciseType = ref.watch(activeExerciseTypeProvider);
    final penaltyMultiplier = ref.watch(activePenaltyMultiplierProvider);
    final exerciseCue = ref.watch(exerciseCueProvider);
    final accessibilityCapped =
        _cameraPermissionDenied && repCount >= AppConstants.accessibilityMaxTapReps;

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

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onTap,
            child: AnimatedContainer(
              duration: AppConstants.shortAnim,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  BoxShadow(color: glowColor, blurRadius: 24, spreadRadius: 6),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ValueListenableBuilder<PoseFrame>(
                    valueListenable: _pipeline.poseFrame,
                    builder: (context, frame, _) {
                      return CameraHudOverlay(
                        cameraController: _pipeline.cameraController,
                        pose: frame.pose,
                        imageSize: frame.imageSize,
                        rotation: frame.rotation,
                        isFrontCamera: frame.isFrontCamera,
                        isSquatting: _isActivePhase,
                      );
                    },
                  ),

                  ValueListenableBuilder<PoseFrame>(
                    valueListenable: _pipeline.poseFrame,
                    builder: (context, frame, _) {
                      final pose = frame.pose;
                      final squat = _exerciseRouter.counter;
                      if (pose == null || squat is! SquatExerciseCounter) {
                        return const SizedBox.shrink();
                      }
                      return Stack(
                        children: [
                          Positioned(
                            left: 24,
                            top: MediaQuery.sizeOf(context).height * 0.45,
                            child: _TelemetryLabel(
                              label: 'L_KNEE',
                              angle: squat.inner.getLeftKneeAngle(pose),
                              isSquatting: _isActivePhase,
                            ),
                          ),
                          Positioned(
                            right: 24,
                            top: MediaQuery.sizeOf(context).height * 0.45,
                            child: _TelemetryLabel(
                              label: 'R_KNEE',
                              angle: squat.inner.getRightKneeAngle(pose),
                              isSquatting: _isActivePhase,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  Center(
                    child: RepCounterDisplay(
                      current: repCount,
                      required: requiredReps,
                    ),
                  ),

                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ValueListenableBuilder<PoseFrame>(
                      valueListenable: _pipeline.poseFrame,
                      builder: (context, frame, _) {
                        return _InstructionBar(
                          feedback: feedback,
                          hasPose: frame.pose != null,
                          isSquatting: _isActivePhase,
                          isCalibrated: _isCalibrated,
                          outOfFrame: outOfFrame,
                          depthRatio: depthRatio,
                          exerciseCue: exerciseCue ?? _liveCue,
                          exerciseType: exerciseType,
                          penaltyMultiplier: penaltyMultiplier,
                          cameraPermissionDenied: _cameraPermissionDenied,
                          accessibilityCapped: accessibilityCapped,
                          cameraLoading:
                              !_cameraReady && !_cameraPermissionDenied,
                          onOpenSettings: () => openAppSettings(),
                        );
                      },
                    ),
                  ),

                  if (_cameraPermissionDenied)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 88,
                      child: _AccessibilityModeBanner(
                        capped: accessibilityCapped,
                        maxTapReps: AppConstants.accessibilityMaxTapReps,
                        onOpenSettings: () => openAppSettings(),
                      ),
                    ),

                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: _WakeUpTaxLabel(
                      repCount: repCount,
                      required: requiredReps,
                      exerciseType: exerciseType,
                    ),
                  ),

                  TaxRevealOverlay(
                    visible: _showTaxReveal,
                    child: TaxRevealStamp(
                      exercise: exerciseType,
                      reps: requiredReps,
                      penaltyMultiplier: penaltyMultiplier,
                    ),
                  ),

                  // ── Squad tax rail ─────────────────────────────────
                  _SquadRailLayer(repCount: repCount),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Right-side squad progress rail — only shown when the user is in a squad.
class _SquadRailLayer extends ConsumerWidget {
  const _SquadRailLayer({required this.repCount});

  final int repCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squadIdAsync = ref.watch(currentSquadIdProvider);
    final squadId = squadIdAsync.valueOrNull;
    if (squadId == null) return const SizedBox.shrink();

    final matesAsync = ref.watch(squadMateProgressProvider);
    final mates = matesAsync.valueOrNull ?? const [];
    if (mates.isEmpty) return const SizedBox.shrink();

    // Upsert own progress on each rep change.
    final user = ref.watch(currentUserProvider);
    if (user != null) {
      final requiredReps = ref.watch(requiredRepsProvider);
      final exerciseType = ref.watch(activeExerciseTypeProvider);
      ref.listen(repCountProvider, (_, count) {
        upsertSquadAlarmProgress(
          squadId: squadId,
          userId: user.id,
          repCount: count,
          requiredReps: requiredReps,
          exerciseType: exerciseType.name,
        );
      });
    }

    return Positioned(
      top: 0,
      bottom: 0,
      right: 12,
      child: Center(
        child: SquadTaxRail(mates: mates),
      ),
    );
  }
}

class _AccessibilityModeBanner extends StatelessWidget {
  const _AccessibilityModeBanner({
    required this.capped,
    required this.maxTapReps,
    required this.onOpenSettings,
  });

  final bool capped;
  final int maxTapReps;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              capped ? 'CAMERA REQUIRED' : 'ACCESSIBILITY MODE',
              style: TextStyle(
                color: capped ? AppColors.destructive : AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              capped
                  ? 'That\'s all $maxTapReps assist taps used — turn on the camera to finish with verified squats.'
                  : 'Camera is off. You have $maxTapReps assist taps to keep moving — or enable the camera for verified reps.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onOpenSettings,
              child: const Text('OPEN CAMERA SETTINGS'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionBar extends StatelessWidget {
  const _InstructionBar({
    required this.feedback,
    required this.hasPose,
    required this.isSquatting,
    required this.isCalibrated,
    required this.outOfFrame,
    required this.depthRatio,
    required this.exerciseCue,
    required this.exerciseType,
    required this.penaltyMultiplier,
    required this.cameraPermissionDenied,
    required this.accessibilityCapped,
    required this.cameraLoading,
    required this.onOpenSettings,
  });

  final RepFeedback feedback;
  final bool hasPose;
  final bool isSquatting;
  final bool isCalibrated;
  final bool outOfFrame;
  final double depthRatio;
  final String? exerciseCue;
  final AlarmExerciseType exerciseType;
  final int penaltyMultiplier;
  final bool cameraPermissionDenied;
  final bool accessibilityCapped;
  final bool cameraLoading;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final hud = Theme.of(context).extension<HudTheme>() ?? HudTheme.cyan;
    final (label, color) = _labelAndColor(hud.primary);

    return AnimatedContainer(
      duration: AppConstants.shortAnim,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (penaltyMultiplier > 1) ...[
            Text(
              'BAILOUT PENALTY · $penaltyMultiplier×',
              style: const TextStyle(
                color: AppColors.destructive,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            exerciseType.taxStampLabel,
            style: TextStyle(
              color: hud.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.5,
            ),
          ),
          if (cameraPermissionDenied) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onOpenSettings,
              child: Text(
                accessibilityCapped
                    ? 'OPEN SETTINGS TO CONTINUE'
                    : 'ENABLE CAMERA FOR VERIFIED REPS',
                style: TextStyle(
                  color: hud.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (String, Color) _labelAndColor(Color accent) {
    if (feedback == RepFeedback.success) {
      return ('PERFECT REP ✓', AppColors.success);
    }
    if (feedback == RepFeedback.failure) {
      return (
        exerciseCue ?? 'GO LOWER / KEEP SHOULDERS LEVEL',
        AppColors.destructive,
      );
    }
    if (cameraPermissionDenied) {
      if (accessibilityCapped) {
        return ('ENABLE CAMERA TO CONTINUE', AppColors.destructive);
      }
      return ('ACCESSIBILITY MODE — TAP TO COUNT', AppColors.accent);
    }
    if (cameraLoading) return ('CAMERA STARTING...', AppColors.mutedForeground);
    if (outOfFrame) {
      return ('BODY OUT OF FRAME — STEP BACK', AppColors.mutedForeground);
    }
    if (!hasPose) return ('FULL BODY IN FRAME', AppColors.mutedForeground);
    if (exerciseCue != null && exerciseCue!.isNotEmpty) {
      return (exerciseCue!, accent);
    }
    if (!isCalibrated) return ('STAND UPRIGHT TO CALIBRATE', accent);
    if (isSquatting) {
      if (depthRatio > 0 && depthRatio < AppConstants.squatDepthThreshold) {
        return ('GO DEEPER', AppColors.accent);
      }
      return ('HOLD... STAND BACK UP', AppColors.success);
    }
    return ('DO A SQUAT', accent);
  }
}

class _WakeUpTaxLabel extends StatelessWidget {
  const _WakeUpTaxLabel({
    required this.repCount,
    required this.required,
    required this.exerciseType,
  });

  final int repCount;
  final int required;
  final AlarmExerciseType exerciseType;

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
          colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
        ),
      ),
      child: Text(
        isDone
            ? 'WAKE UP TAX PAID'
            : 'WAKE UP TAX — $remaining ${exerciseType.taxStampLabel} LEFT',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _TelemetryLabel extends StatelessWidget {
  const _TelemetryLabel({
    required this.label,
    required this.angle,
    required this.isSquatting,
  });

  final String label;
  final double? angle;
  final bool isSquatting;

  @override
  Widget build(BuildContext context) {
    final text = angle == null ? '--°' : '${angle!.round()}°';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.mutedForeground.withValues(alpha: 0.8),
            fontSize: 9,
            letterSpacing: 1.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          text,
          style: TextStyle(
            color: isSquatting ? AppColors.success : AppColors.foreground,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
