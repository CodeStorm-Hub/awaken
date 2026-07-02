import 'dart:async';
import 'dart:io';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart' show AppRoutes, appRouterProvider;
import 'package:awaken/core/services/alarm_audio_service.dart';
import 'package:awaken/core/services/wake_lock_service.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/domain/services/squat_counter_service.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_providers.dart';
import 'package:awaken/features/alarm/presentation/widgets/camera_hud_overlay.dart';
import 'package:awaken/features/alarm/presentation/widgets/rep_counter_display.dart';
import 'package:camera/camera.dart';
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
  // ── Camera ──────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _isFrontCamera = true;
  int _sensorOrientation = 0;
  bool _cameraPermissionDenied = false;

  // ── ML Kit ──────────────────────────────────────────────────────────────
  late final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );
  bool _isDetecting = false;
  DateTime _lastDetectionTime = DateTime.fromMillisecondsSinceEpoch(0);

  // ── Pose state (drives overlay) ─────────────────────────────────────────
  Pose? _currentPose;
  Size? _imageSize;
  InputImageRotation? _imageRotation;

  // ── Squat logic ─────────────────────────────────────────────────────────
  final _squatCounter = SquatCounterService();

  // ── Out-of-frame penalty ────────────────────────────────────────────────
  Timer? _outOfFramePenaltyTimer;

  // ── Router (captured in initState to avoid BuildContext across async gaps) ─
  late final GoRouter _router;

  // ── Orientation lookup for Android rotation compensation ────────────────
  static const Map<DeviceOrientation, int> _orientationMap = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _router = ref.read(appRouterProvider);

    _squatCounter.reset();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetAlarmSession(ref);
      if (widget.alarm != null) {
        ref.read(requiredRepsProvider.notifier).setRequired(widget.alarm!.requiredReps);
      }
    });

    WakeLockService.enable();
    AlarmAudioService.start();
    AlarmAudioService.resetVolume();
    _initCamera();
  }

  @override
  void dispose() {
    _outOfFramePenaltyTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseDetector.close();
    WakeLockService.disable();
    AlarmAudioService.stop();
    super.dispose();
  }

  // ── Camera init ─────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _cameraPermissionDenied = true);
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) setState(() => _cameraPermissionDenied = true);
      return;
    }

    // Prefer front camera for squats (user faces device)
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _isFrontCamera = camera.lensDirection == CameraLensDirection.front;
    _sensorOrientation = camera.sensorOrientation;

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium, // Balance quality vs. processing overhead
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
    } catch (e) {
      debugPrint('[Camera] Init failed: $e');
      if (mounted) setState(() => _cameraPermissionDenied = true);
      return;
    }

    if (!mounted) {
      await _cameraController!.dispose();
      _cameraController = null;
      return;
    }

    setState(() {}); // Show the camera preview

    await _cameraController!.startImageStream(_onCameraImage);
  }

  // ── Image stream → ML Kit ───────────────────────────────────────────────

  void _onCameraImage(CameraImage image) {
    if (_isDetecting || !mounted) return;

    // Throttle to ~15 FPS (skip frames when processing is slow)
    final now = DateTime.now();
    if (now.difference(_lastDetectionTime).inMilliseconds < 66) return;
    _lastDetectionTime = now;

    _isDetecting = true;
    _processImage(image).whenComplete(() => _isDetecting = false);
  }

  Future<void> _processImage(CameraImage image) async {
    final inputImage = _buildInputImage(image);
    if (inputImage == null) return;

    final poses = await _poseDetector.processImage(inputImage);
    if (!mounted) return;

    final pose = poses.isNotEmpty ? poses.first : null;

    setState(() {
      _currentPose = pose;
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
    });

    if (pose != null) {
      _setOutOfFrame(false);
      final result = _squatCounter.processPose(pose);
      if (result.repCompleted) {
        _onRepCompleted();
      } else if (result.badForm) {
        _onBadForm();
      }
    } else {
      _setOutOfFrame(true);
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

  InputImage? _buildInputImage(CameraImage image) {
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      // iOS handles rotation in the image stream automatically
      rotation = InputImageRotationValue.fromRawValue(_sensorOrientation);
    } else {
      // Android: combine sensor orientation + current device orientation
      final deviceOrientation =
          _cameraController?.value.deviceOrientation ?? DeviceOrientation.portraitUp;
      final deviceCompensation = _orientationMap[deviceOrientation] ?? 0;

      final int raw;
      if (_isFrontCamera) {
        raw = (_sensorOrientation + deviceCompensation) % 360;
      } else {
        raw = (_sensorOrientation - deviceCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(raw);
    }

    if (rotation == null) return null;
    _imageRotation = rotation; // Cache for overlay painter

    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (format == null) return null;

    // NV21 (Android) is multi-plane — concatenate all planes
    if (image.planes.length > 1) {
      final buffer = WriteBuffer();
      for (final plane in image.planes) {
        buffer.putUint8List(plane.bytes);
      }
      final bytes = buffer.done().buffer.asUint8List();
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }

    // BGRA8888 (iOS) is single-plane
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // ── Rep counting ─────────────────────────────────────────────────────────

  void _onRepCompleted() {
    final current = ref.read(repCountProvider);
    final required = ref.read(requiredRepsProvider);
    if (current >= required) return;

    final next = current + 1;
    ref.read(repCountProvider.notifier).setCount(next);
    ref.read(repFeedbackProvider.notifier).setFeedback(RepFeedback.success);

    Future.delayed(AppConstants.shortAnim, () {
      if (mounted) ref.read(repFeedbackProvider.notifier).setFeedback(RepFeedback.neutral);
    });

    if (next >= required) {
      Future.delayed(AppConstants.mediumAnim, () {
        if (!mounted) return;
        // Let the SuccessScreen read the state before resetting it.
        _router.go(AppRoutes.success, extra: widget.alarm);
      });
    }
  }

  /// Tap fallback — active when camera is loading, denied, or during debugging.
  void _onTap() {
    if (!_tapEnabled) return;
    final current = ref.read(repCountProvider);
    final required = ref.read(requiredRepsProvider);
    _onRepCountedManually(current, required);
  }

  void _onRepCountedManually(int current, int required) {
    if (current >= required) return;
    final next = current + 1;
    ref.read(repCountProvider.notifier).setCount(next);
    ref.read(repFeedbackProvider.notifier).setFeedback(RepFeedback.success);
    Future.delayed(AppConstants.shortAnim, () {
      if (mounted) ref.read(repFeedbackProvider.notifier).setFeedback(RepFeedback.neutral);
    });
    if (next >= required) {
      Future.delayed(AppConstants.mediumAnim, () {
        if (!mounted) return;
        // Let the SuccessScreen read the state before resetting it.
        _router.go(AppRoutes.success, extra: widget.alarm);
      });
    }
  }

  bool get _tapEnabled => _cameraPermissionDenied;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final feedback = ref.watch(repFeedbackProvider);
    final repCount = ref.watch(repCountProvider);
    final requiredReps = ref.watch(requiredRepsProvider);
    final isSquatting = _squatCounter.isInSquat;

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
                // Layer 1: Camera + skeleton + scan line
                CameraHudOverlay(
                  cameraController: _cameraController,
                  pose: _currentPose,
                  imageSize: _imageSize,
                  rotation: _imageRotation,
                  isFrontCamera: _isFrontCamera,
                  isSquatting: isSquatting,
                ),

                // Layer 2: Rep counter
                Center(
                  child: RepCounterDisplay(
                    current: repCount,
                    required: requiredReps,
                  ),
                ),

                // Layer 3: Top instruction bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _InstructionBar(
                    feedback: feedback,
                    hasPose: _currentPose != null,
                    isSquatting: isSquatting,
                    cameraPermissionDenied: _cameraPermissionDenied,
                    cameraLoading: _cameraController == null ||
                        !(_cameraController!.value.isInitialized),
                  ),
                ),

                // Layer 4: Bottom label
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
    ));
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _InstructionBar extends StatelessWidget {
  const _InstructionBar({
    required this.feedback,
    required this.hasPose,
    required this.isSquatting,
    required this.cameraPermissionDenied,
    required this.cameraLoading,
  });

  final RepFeedback feedback;
  final bool hasPose;
  final bool isSquatting;
  final bool cameraPermissionDenied;
  final bool cameraLoading;

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
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  (String, Color) _labelAndColor() {
    if (feedback == RepFeedback.success) return ('PERFECT REP ✓', AppColors.success);
    if (feedback == RepFeedback.failure) return ('BAD FORM — TRY AGAIN', AppColors.destructive);
    if (cameraPermissionDenied) return ('CAMERA DENIED — TAP TO SIMULATE', AppColors.destructive);
    if (cameraLoading) return ('CAMERA STARTING...', AppColors.mutedForeground);
    if (!hasPose) return ('GET IN FRAME', AppColors.mutedForeground);
    if (isSquatting) return ('HOLD... COME BACK UP', AppColors.success);
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
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Text(
        isDone ? 'COMPLETE — WAKING UP...' : '$remaining SQUATS REMAINING',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDone ? AppColors.success : AppColors.mutedForeground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
