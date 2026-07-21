import 'dart:async';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart'
    show AppRoutes, appRouterProvider;
import 'package:awaken/core/services/alarm_audio_service.dart';
import 'package:awaken/core/services/alarm_vibration_service.dart';
import 'package:awaken/core/services/wake_lock_service.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/hud_theme.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_exercise_type.dart';
import 'package:awaken/features/alarm/domain/services/alarm_bailout_service.dart';
import 'package:awaken/features/alarm/domain/services/exercise_counter_router.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_providers.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_schedule_providers.dart';
import 'package:awaken/features/alarm/presentation/providers/squad_providers.dart';
import 'package:awaken/features/alarm/presentation/services/alarm_pose_pipeline.dart';
import 'package:awaken/features/alarm/presentation/widgets/camera_hud_overlay.dart';
import 'package:awaken/features/alarm/presentation/widgets/rep_counter_display.dart';
import 'package:awaken/features/alarm/presentation/widgets/squad_tax_rail.dart';
import 'package:awaken/features/alarm/presentation/widgets/tax_reveal_stamp.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/success/presentation/screens/success_screen.dart';
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
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  /// Consecutive out-of-frame frames required before treating tracking loss
  /// as real (~330ms at the pipeline's throttled ~15 FPS) — a single frame
  /// of tracking loss (hand crossing the face, brief motion blur) must not
  /// start the audio-ramp/UI warning mid-rep.
  static const int _outOfFrameDebounceFrames = 5;

  late final AlarmPosePipeline _pipeline;
  late final ExerciseCounterRouter _exerciseRouter;
  Timer? _outOfFramePenaltyTimer;
  int _outOfFrameStreak = 0;
  late final GoRouter _router;
  bool _cameraPermissionDenied = false;
  bool _cameraFailed = false;
  bool _cameraReady = false;
  bool _showTaxReveal = true;
  bool _isActivePhase = false;
  bool _isCalibrated = false;
  String? _liveCue;
  bool _sessionCompleted = false;

  /// Emergency-stop escape hatch (A5): a deliberately low-discoverability
  /// hold target so a user with no working camera and no accessibility taps
  /// left is never trapped with a ringing, un-poppable alarm. Completing the
  /// hold applies the same 2× bailout penalty an unattended alarm already
  /// applies — this makes the existing consequence a chosen exit instead of
  /// leaving no exit at all.
  static const _emergencyHoldDuration = Duration(seconds: 10);
  late final AnimationController _emergencyHoldController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = ref.read(appRouterProvider);

    _emergencyHoldController =
        AnimationController(vsync: this, duration: _emergencyHoldDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _onEmergencyStop();
          });

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
    _pipeline.cameraFailed.addListener(_onCameraFailedChanged);
    _pipeline.isReady.addListener(_onReadyChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetAlarmSession(ref);
      ref.read(activeExerciseTypeProvider.notifier).setType(exercise);
      final multiplier = alarm?.penaltyMultiplier ?? 1;
      ref
          .read(activePenaltyMultiplierProvider.notifier)
          .setMultiplier(multiplier);
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
    AlarmVibrationService.start();
    _pipeline.start();
  }

  void _onPermissionChanged() {
    if (!mounted) return;
    setState(() => _cameraPermissionDenied = _pipeline.permissionDenied.value);
  }

  void _onCameraFailedChanged() {
    if (!mounted) return;
    setState(() => _cameraFailed = _pipeline.cameraFailed.value);
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

  /// Stops audio and releases the wake lock. Called explicitly the moment
  /// the required reps are hit (so a future change that keeps this route
  /// mounted — a dialog, nested navigation — can't leave the alarm ringing)
  /// with [dispose] kept as a safety net for every other exit path.
  void _completeAlarmSession() {
    if (_sessionCompleted) return;
    _sessionCompleted = true;
    WakeLockService.disable();
    AlarmAudioService.stop();
    AlarmVibrationService.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _outOfFramePenaltyTimer?.cancel();
    _pipeline.permissionDenied.removeListener(_onPermissionChanged);
    _pipeline.cameraFailed.removeListener(_onCameraFailedChanged);
    _pipeline.isReady.removeListener(_onReadyChanged);
    unawaited(_pipeline.dispose());
    _emergencyHoldController.dispose();
    _completeAlarmSession();
    super.dispose();
  }

  /// Captures the completed session's stats at the moment reps hit target,
  /// so [SuccessScreen] never depends on the timing of autoDispose providers
  /// that may already be reset by the time it builds.
  SuccessScreenArgs _buildSuccessArgs(int repsCompleted) {
    final startTime = ref.read(sessionStartTimeProvider);
    final duration = startTime != null
        ? DateTime.now().difference(startTime).inSeconds
        : 0;
    return SuccessScreenArgs(
      alarm: widget.alarm,
      repsCompleted: repsCompleted,
      durationSeconds: duration,
      usedAccessibilityMode: ref.read(accessibilitySessionProvider),
    );
  }

  Future<void> _onEmergencyStop() async {
    if (_sessionCompleted) return;
    HapticFeedback.heavyImpact();
    final alarm = widget.alarm;
    if (alarm != null) {
      await const AlarmBailoutService().forceBailout(
        alarm: alarm,
        repository: ref.read(alarmRepositoryProvider),
      );
    }
    _completeAlarmSession();
    if (!mounted) return;
    _router.go(AppRoutes.dashboard);
  }

  void _onPoseResult(Pose? pose, DateTime timestamp) {
    if (!mounted) return;

    if (pose == null) {
      _outOfFrameStreak++;
      if (_outOfFrameStreak >= _outOfFrameDebounceFrames) {
        _setOutOfFrame(true);
      }
      if (_isActivePhase || _isCalibrated) {
        setState(() {
          _isActivePhase = _exerciseRouter.counter.isInActivePhase;
          _isCalibrated = _exerciseRouter.counter.isCalibrated;
        });
      }
      return;
    }

    // A single good frame immediately cancels a pending debounce — no
    // reason to delay relief once tracking is back.
    _outOfFrameStreak = 0;
    _setOutOfFrame(false);
    final wasCalibratedBefore = _exerciseRouter.counter.isCalibrated;
    final result = _exerciseRouter.counter.processPose(pose, timestamp);

    final phaseChanged =
        _isActivePhase != _exerciseRouter.counter.isInActivePhase ||
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
      _completeAlarmSession();
      final successArgs = _buildSuccessArgs(next);
      Future.delayed(AppConstants.mediumAnim, () {
        if (!mounted) return;
        _router.go(AppRoutes.success, extra: successArgs);
      });
    }
  }

  /// Tap-to-count fallback — active when the camera can't be used, whether
  /// permission was denied or the hardware failed. Labeled in the HUD.
  void _onTap() {
    if (!_cameraPermissionDenied && !_cameraFailed) return;
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
      _completeAlarmSession();
      final successArgs = _buildSuccessArgs(next);
      Future.delayed(AppConstants.mediumAnim, () {
        if (!mounted) return;
        _router.go(AppRoutes.success, extra: successArgs);
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
    final fallbackActive = _cameraPermissionDenied || _cameraFailed;
    final accessibilityCapped =
        fallbackActive && repCount >= AppConstants.accessibilityMaxTapReps;

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
        // The HUD's fixed-size overlays (rep counter, telemetry, instruction
        // bar) can't reflow around large system font scaling without
        // clipping or overlapping the camera preview — clamp rather than
        // ignore the setting entirely.
        body: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: SafeArea(
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
                    BoxShadow(
                      color: glowColor,
                      blurRadius: 24,
                      spreadRadius: 6,
                    ),
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
                      // liveRegion: TalkBack/VoiceOver announces each rep —
                      // haptics aside, the HUD is otherwise the only feedback.
                      child: Semantics(
                        liveRegion: true,
                        label: '$repCount of $requiredReps reps',
                        child: RepCounterDisplay(
                          current: repCount,
                          required: requiredReps,
                        ),
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
                            cameraFailed: _cameraFailed,
                            accessibilityCapped: accessibilityCapped,
                            cameraLoading: !_cameraReady && !fallbackActive,
                            onOpenSettings: () => openAppSettings(),
                          );
                        },
                      ),
                    ),

                    if (fallbackActive)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 88,
                        child: _AccessibilityModeBanner(
                          capped: accessibilityCapped,
                          cameraFailed: _cameraFailed,
                          maxTapReps: AppConstants.accessibilityMaxTapReps,
                          onOpenSettings: () => openAppSettings(),
                          onRetryCamera: () =>
                              unawaited(_pipeline.retryCamera()),
                        ),
                      ),

                    // Emergency stop — only surfaced once the accessibility
                    // tap allowance is exhausted with no working camera, so
                    // this can never be used to skip a normal camera-verified
                    // session. Applies the same 2× bailout penalty an
                    // unattended alarm already would.
                    if (accessibilityCapped)
                      Positioned(
                        right: 16,
                        top: 16,
                        child: _EmergencyStopControl(
                          controller: _emergencyHoldController,
                          holdDuration: _emergencyHoldDuration,
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
    final squadId = squadIdAsync.value;
    if (squadId == null) return const SizedBox.shrink();

    final matesAsync = ref.watch(squadMateProgressProvider);
    final mates = matesAsync.value ?? const [];
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
      child: Center(child: SquadTaxRail(mates: mates)),
    );
  }
}

class _AccessibilityModeBanner extends StatelessWidget {
  const _AccessibilityModeBanner({
    required this.capped,
    required this.cameraFailed,
    required this.maxTapReps,
    required this.onOpenSettings,
    required this.onRetryCamera,
  });

  final bool capped;

  /// True when the camera hardware failed with permission granted — settings
  /// won't help; retrying the camera might.
  final bool cameraFailed;
  final int maxTapReps;
  final VoidCallback onOpenSettings;
  final VoidCallback onRetryCamera;

  @override
  Widget build(BuildContext context) {
    final String body;
    if (capped) {
      body = cameraFailed
          ? 'That\'s all $maxTapReps assist taps used — retry the camera to finish with verified reps.'
          : 'That\'s all $maxTapReps assist taps used — turn on the camera to finish with verified squats.';
    } else {
      body = cameraFailed
          ? 'Camera unavailable — it may be in use by another app. You have $maxTapReps assist taps to keep moving, or retry the camera.'
          : 'Camera is off. You have $maxTapReps assist taps to keep moving — or enable the camera for verified reps.';
    }

    return Material(
      color: AppColors.card.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              capped
                  ? 'CAMERA REQUIRED'
                  : (cameraFailed
                        ? 'CAMERA UNAVAILABLE'
                        : 'ACCESSIBILITY MODE'),
              style: TextStyle(
                color: capped ? AppColors.destructive : AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: cameraFailed ? onRetryCamera : onOpenSettings,
              child: Text(
                cameraFailed ? 'RETRY CAMERA' : 'OPEN CAMERA SETTINGS',
              ),
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
    required this.cameraFailed,
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
  final bool cameraFailed;
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
          if (cameraPermissionDenied && !cameraFailed) ...[
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
    if (cameraFailed) {
      if (accessibilityCapped) {
        return ('RETRY CAMERA TO CONTINUE', AppColors.destructive);
      }
      return ('CAMERA UNAVAILABLE — TAP TO COUNT', AppColors.accent);
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

/// Hold-to-confirm emergency stop (A5). Deliberately small and low-opacity
/// at rest — a genuine last resort, not a shortcut — but grows an obvious
/// fill ring and label once held, so it's discoverable to anyone who
/// actually needs it (including via long-press exploration for screen
/// reader users, who get the state announced through [Semantics]).
class _EmergencyStopControl extends StatefulWidget {
  const _EmergencyStopControl({
    required this.controller,
    required this.holdDuration,
  });

  final AnimationController controller;
  final Duration holdDuration;

  @override
  State<_EmergencyStopControl> createState() => _EmergencyStopControlState();
}

class _EmergencyStopControlState extends State<_EmergencyStopControl> {
  bool _holding = false;

  void _onHoldStart() {
    setState(() => _holding = true);
    widget.controller.forward();
  }

  void _onHoldEnd() {
    if (widget.controller.isCompleted) return;
    setState(() => _holding = false);
    widget.controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Emergency stop — hold for '
          '${widget.holdDuration.inSeconds} seconds to end this alarm '
          'and apply a bailout penalty',
      child: GestureDetector(
        onLongPressStart: (_) => _onHoldStart(),
        onLongPressEnd: (_) => _onHoldEnd(),
        onLongPressCancel: _onHoldEnd,
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            return Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: _holding ? 0.6 : 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.destructive.withValues(
                    alpha: _holding ? 0.9 : 0.25,
                  ),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_holding)
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        value: widget.controller.value,
                        strokeWidth: 2.5,
                        color: AppColors.destructive,
                        backgroundColor: AppColors.destructive.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                  Icon(
                    Icons.sos_rounded,
                    size: 16,
                    color: AppColors.destructive.withValues(
                      alpha: _holding ? 1.0 : 0.4,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
