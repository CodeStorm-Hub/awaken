import 'dart:async';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart' show AppRoutes, appRouterProvider;
import 'package:awaken/core/services/alarm_audio_service.dart';
import 'package:awaken/core/services/wake_lock_service.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/domain/services/squat_counter_service.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_providers.dart';
import 'package:awaken/features/alarm/presentation/services/alarm_pose_pipeline.dart';
import 'package:awaken/features/alarm/presentation/widgets/camera_hud_overlay.dart';
import 'package:awaken/features/alarm/presentation/widgets/rep_counter_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class ActiveAlarmScreen extends ConsumerStatefulWidget {
  const ActiveAlarmScreen({super.key, this.alarm});

  /// The alarm that triggered this screen. Null when cold-launched from a
  /// notification (fall back to [requiredRepsProvider]'s stored value).
  final AlarmEntity? alarm;

  @override
  ConsumerState<ActiveAlarmScreen> createState() => _ActiveAlarmScreenState();
}

class _ActiveAlarmScreenState extends ConsumerState<ActiveAlarmScreen> {
  late final AlarmPosePipeline _pipeline;
  final _squatCounter = SquatCounterService();
  Timer? _outOfFramePenaltyTimer;
  late final GoRouter _router;
  bool _cameraPermissionDenied = false;
  bool _cameraReady = false;

  // Local squat phase flags — updated without full-tree setState when possible.
  bool _isSquatting = false;
  bool _isCalibrated = false;

  @override
  void initState() {
    super.initState();
    _router = ref.read(appRouterProvider);
    _squatCounter.reset();

    _pipeline = AlarmPosePipeline(onPoseResult: _onPoseResult);
    _pipeline.permissionDenied.addListener(_onPermissionChanged);
    _pipeline.isReady.addListener(_onReadyChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetAlarmSession(ref);
      if (widget.alarm != null) {
        ref
            .read(requiredRepsProvider.notifier)
            .setRequired(widget.alarm!.requiredReps);
      }
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

  @override
  void dispose() {
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
      if (_isSquatting || _isCalibrated) {
        setState(() {
          _isSquatting = _squatCounter.isInSquat;
          _isCalibrated = _squatCounter.isCalibrated;
        });
      }
      return;
    }

    _setOutOfFrame(false);
    final wasCalibratedBefore = _squatCounter.isCalibrated;
    final result = _squatCounter.processPose(pose);

    final phaseChanged = _isSquatting != _squatCounter.isInSquat ||
        _isCalibrated != _squatCounter.isCalibrated;
    if (phaseChanged) {
      setState(() {
        _isSquatting = _squatCounter.isInSquat;
        _isCalibrated = _squatCounter.isCalibrated;
      });
    }

    if (!wasCalibratedBefore && _squatCounter.isCalibrated) {
      HapticFeedback.mediumImpact();
    }

    if (result.repCompleted) {
      _onRepCompleted();
    } else if (result.badForm) {
      _onBadForm();
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
                        isSquatting: _isSquatting,
                      );
                    },
                  ),

                  ValueListenableBuilder<PoseFrame>(
                    valueListenable: _pipeline.poseFrame,
                    builder: (context, frame, _) {
                      final pose = frame.pose;
                      if (pose == null) return const SizedBox.shrink();
                      return Stack(
                        children: [
                          Positioned(
                            left: 24,
                            top: MediaQuery.sizeOf(context).height * 0.45,
                            child: _TelemetryLabel(
                              label: 'L_KNEE',
                              angle: _squatCounter.getLeftKneeAngle(pose),
                              isSquatting: _isSquatting,
                            ),
                          ),
                          Positioned(
                            right: 24,
                            top: MediaQuery.sizeOf(context).height * 0.45,
                            child: _TelemetryLabel(
                              label: 'R_KNEE',
                              angle: _squatCounter.getRightKneeAngle(pose),
                              isSquatting: _isSquatting,
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
                          isSquatting: _isSquatting,
                          isCalibrated: _isCalibrated,
                          cameraPermissionDenied: _cameraPermissionDenied,
                          cameraLoading: !_cameraReady && !_cameraPermissionDenied,
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessibilityModeBanner extends StatelessWidget {
  const _AccessibilityModeBanner({required this.onOpenSettings});

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
            const Text(
              'ACCESSIBILITY MODE',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Camera is off. Tap anywhere to count a rep, or enable the camera for verified squats.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
    required this.cameraPermissionDenied,
    required this.cameraLoading,
    required this.onOpenSettings,
  });

  final RepFeedback feedback;
  final bool hasPose;
  final bool isSquatting;
  final bool isCalibrated;
  final bool cameraPermissionDenied;
  final bool cameraLoading;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _labelAndColor();

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
              child: const Text(
                'ENABLE CAMERA FOR VERIFIED REPS',
                style: TextStyle(
                  color: AppColors.primary,
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

  (String, Color) _labelAndColor() {
    if (feedback == RepFeedback.success) {
      return ('PERFECT REP ✓', AppColors.success);
    }
    if (feedback == RepFeedback.failure) {
      return ('GO LOWER / KEEP SHOULDERS LEVEL', AppColors.destructive);
    }
    if (cameraPermissionDenied) {
      return ('ACCESSIBILITY MODE — TAP TO COUNT', AppColors.accent);
    }
    if (cameraLoading) return ('CAMERA STARTING...', AppColors.mutedForeground);
    if (!hasPose) return ('FULL BODY IN FRAME', AppColors.mutedForeground);
    if (!isCalibrated) return ('STAND UPRIGHT TO CALIBRATE', AppColors.primary);
    if (isSquatting) return ('HOLD... STAND BACK UP', AppColors.success);
    return ('DO A SQUAT', AppColors.primary);
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
          colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
        ),
      ),
      child: Text(
        isDone
            ? 'WAKE UP TAX PAID'
            : 'WAKE UP TAX — $remaining REP${remaining == 1 ? '' : 'S'} LEFT',
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
