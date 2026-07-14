import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';

/// Snapshot of the latest pose frame for overlay painting.
@immutable
class PoseFrame {
  const PoseFrame({
    required this.pose,
    required this.imageSize,
    required this.rotation,
    required this.isFrontCamera,
  });

  final Pose? pose;
  final Size? imageSize;
  final InputImageRotation? rotation;
  final bool isFrontCamera;
}

/// Owns camera lifecycle, ML Kit pose detection, and throttled frame delivery.
///
/// Keeps pose updates on [poseFrame] so the HUD can rebuild via
/// [ValueListenableBuilder] without rebuilding the full alarm screen.
class AlarmPosePipeline {
  AlarmPosePipeline({PoseDetector? poseDetector, this.onPoseResult})
    : _poseDetector =
          poseDetector ??
          PoseDetector(
            options: PoseDetectorOptions(
              mode: PoseDetectionMode.stream,
              // `base` (the plugin default) trades landmark stability for
              // speed, matching this pipeline's ~15 FPS throttle budget —
              // pinned explicitly rather than left to the plugin default,
              // which could change silently on a version bump. `accurate`
              // is tuned for single static images and too slow for a live
              // stream at this frame rate; revisit only if squat-depth
              // precision becomes an issue in practice.
              model: PoseDetectionModel.base,
            ),
          );

  final PoseDetector _poseDetector;

  /// Called after each processed frame with the raw pose (or null) and the
  /// frame's capture timestamp (not processing-completion time).
  final void Function(Pose? pose, DateTime timestamp)? onPoseResult;

  final ValueNotifier<PoseFrame> poseFrame = ValueNotifier(
    const PoseFrame(
      pose: null,
      imageSize: null,
      rotation: null,
      isFrontCamera: true,
    ),
  );

  final ValueNotifier<bool> permissionDenied = ValueNotifier(false);

  /// Camera hardware/driver failure with permission GRANTED — e.g. camera
  /// held by another app or a HAL error. Distinct from [permissionDenied]
  /// so the HUD can show "retry" instead of sending the user to settings
  /// for a permission they already granted.
  final ValueNotifier<bool> cameraFailed = ValueNotifier(false);
  final ValueNotifier<bool> isReady = ValueNotifier(false);

  CameraController? _cameraController;
  CameraDescription? _camera;
  bool _isFrontCamera = true;
  int _sensorOrientation = 0;
  bool _isDetecting = false;
  bool _disposed = false;
  bool _pausedByLifecycle = false;
  DateTime _lastDetectionTime = DateTime.fromMillisecondsSinceEpoch(0);
  InputImageRotation? _imageRotation;

  CameraController? get cameraController => _cameraController;
  bool get isFrontCamera => _isFrontCamera;

  static const Map<DeviceOrientation, int> _orientationMap = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  Future<void> start() async {
    // Check status before requesting: if permission was revoked after the
    // alarm was armed, firing a fresh system permission dialog on top of the
    // full-screen alarm intent is unreliable (can't be answered over the
    // lock screen) and blocks the tap-to-dismiss fallback below from ever
    // being reached. Only request when there's a real chance of granting.
    var status = await Permission.camera.status;
    if (status.isPermanentlyDenied || status.isRestricted) {
      permissionDenied.value = true;
      return;
    }
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (_disposed) return;
    if (!status.isGranted) {
      permissionDenied.value = true;
      return;
    }

    final cameras = await availableCameras();
    if (_disposed) return;
    if (cameras.isEmpty) {
      cameraFailed.value = true;
      return;
    }

    _camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _isFrontCamera = _camera!.lensDirection == CameraLensDirection.front;
    _sensorOrientation = _camera!.sensorOrientation;

    await _openCamera();
  }

  Future<void> _openCamera() async {
    final camera = _camera;
    if (camera == null || _disposed) return;

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _cameraController = controller;

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      debugPrint('[Camera] Init failed: ${e.code} ${e.description}');
      cameraFailed.value = true;
      return;
    } catch (e) {
      debugPrint('[Camera] Init failed: $e');
      cameraFailed.value = true;
      return;
    }

    cameraFailed.value = false;

    if (_disposed || _pausedByLifecycle) {
      await controller.dispose();
      if (identical(_cameraController, controller)) _cameraController = null;
      return;
    }

    isReady.value = true;
    await controller.startImageStream(_onCameraImage);
  }

  /// Retries opening the camera after a hardware failure ([cameraFailed]) —
  /// the other app may have released it, or the HAL recovered.
  Future<void> retryCamera() async {
    if (_disposed || _pausedByLifecycle) return;
    cameraFailed.value = false;
    await _teardownCamera();
    if (_camera == null) {
      await start();
    } else {
      await _openCamera();
    }
  }

  /// Releases the camera when the app leaves the foreground (camera plugin
  /// lifecycle guidance) — call from `AppLifecycleState.inactive`/`paused`.
  Future<void> pauseForLifecycle() async {
    if (_disposed || _pausedByLifecycle) return;
    _pausedByLifecycle = true;
    isReady.value = false;
    await _teardownCamera();
  }

  /// Re-opens the camera after [pauseForLifecycle] — call from
  /// `AppLifecycleState.resumed`.
  Future<void> resumeAfterLifecycle() async {
    if (_disposed || !_pausedByLifecycle) return;
    _pausedByLifecycle = false;
    if (permissionDenied.value) return;
    await _openCamera();
  }

  Future<void> _teardownCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller == null) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}
    await controller.dispose();
  }

  void _onCameraImage(CameraImage image) {
    if (_isDetecting || _disposed || _pausedByLifecycle) return;

    final now = DateTime.now();
    if (now.difference(_lastDetectionTime).inMilliseconds < 66) return;
    _lastDetectionTime = now;

    _isDetecting = true;
    _processImage(image, now).whenComplete(() => _isDetecting = false);
  }

  Future<void> _processImage(CameraImage image, DateTime captureTime) async {
    final inputImage = _buildInputImage(image);
    if (inputImage == null) return;

    final List<Pose> poses;
    try {
      poses = await _poseDetector.processImage(inputImage);
    } catch (e) {
      // A frame can fail (detector closing mid-frame, malformed buffer) —
      // skip it rather than crash the alarm flow.
      debugPrint('[PoseDetector] Frame failed: $e');
      return;
    }
    if (_disposed || _pausedByLifecycle) return;

    final pose = poses.isNotEmpty ? poses.first : null;
    poseFrame.value = PoseFrame(
      pose: pose,
      imageSize: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: _imageRotation,
      isFrontCamera: _isFrontCamera,
    );
    onPoseResult?.call(pose, captureTime);
  }

  InputImage? _buildInputImage(CameraImage image) {
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(_sensorOrientation);
    } else {
      final deviceOrientation =
          _cameraController?.value.deviceOrientation ??
          DeviceOrientation.portraitUp;
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
    _imageRotation = rotation;

    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (format == null) return null;

    // Android delivers a single NV21 plane when ImageFormatGroup.nv21 is
    // honored; some devices/implementations fall back to 3-plane YUV_420_888,
    // which must be interleaved into NV21 (respecting row/pixel strides)
    // before ML Kit can read it.
    if (image.planes.length == 3) {
      final bytes = _yuv420ToNv21(image);
      if (bytes == null) return null;
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      );
    }

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

  /// Converts 3-plane YUV_420_888 to NV21 (Y plane followed by interleaved
  /// V/U), honoring each plane's row and pixel strides.
  Uint8List? _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final chromaWidth = width ~/ 2;
    final chromaHeight = height ~/ 2;
    final out = Uint8List(width * height + 2 * chromaWidth * chromaHeight);

    var offset = 0;
    for (var row = 0; row < height; row++) {
      final src = row * yPlane.bytesPerRow;
      if (src + width > yPlane.bytes.length) return null;
      out.setRange(offset, offset + width, yPlane.bytes, src);
      offset += width;
    }

    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;
    for (var row = 0; row < chromaHeight; row++) {
      for (var col = 0; col < chromaWidth; col++) {
        final uvIndex = row * uvRowStride + col * uvPixelStride;
        if (uvIndex >= uPlane.bytes.length || uvIndex >= vPlane.bytes.length) {
          return null;
        }
        out[offset++] = vPlane.bytes[uvIndex];
        out[offset++] = uPlane.bytes[uvIndex];
      }
    }
    return out;
  }

  Future<void> dispose() async {
    _disposed = true;
    await _teardownCamera();
    await _poseDetector.close();
    poseFrame.dispose();
    permissionDenied.dispose();
    cameraFailed.dispose();
    isReady.dispose();
  }
}
