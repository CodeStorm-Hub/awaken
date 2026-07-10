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
  AlarmPosePipeline({
    PoseDetector? poseDetector,
    this.onPoseResult,
  }) : _poseDetector = poseDetector ??
            PoseDetector(
              options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
            );

  final PoseDetector _poseDetector;

  /// Called after each processed frame with the raw pose (or null).
  final void Function(Pose? pose)? onPoseResult;

  final ValueNotifier<PoseFrame> poseFrame = ValueNotifier(
    const PoseFrame(
      pose: null,
      imageSize: null,
      rotation: null,
      isFrontCamera: true,
    ),
  );

  final ValueNotifier<bool> permissionDenied = ValueNotifier(false);
  final ValueNotifier<bool> isReady = ValueNotifier(false);

  CameraController? _cameraController;
  bool _isFrontCamera = true;
  int _sensorOrientation = 0;
  bool _isDetecting = false;
  bool _disposed = false;
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
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      permissionDenied.value = true;
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      permissionDenied.value = true;
      return;
    }

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _isFrontCamera = camera.lensDirection == CameraLensDirection.front;
    _sensorOrientation = camera.sensorOrientation;

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup:
          Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
    } catch (e) {
      debugPrint('[Camera] Init failed: $e');
      permissionDenied.value = true;
      return;
    }

    if (_disposed) {
      await _cameraController!.dispose();
      _cameraController = null;
      return;
    }

    isReady.value = true;
    await _cameraController!.startImageStream(_onCameraImage);
  }

  void _onCameraImage(CameraImage image) {
    if (_isDetecting || _disposed) return;

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
    if (_disposed) return;

    final pose = poses.isNotEmpty ? poses.first : null;
    poseFrame.value = PoseFrame(
      pose: pose,
      imageSize: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: _imageRotation,
      isFrontCamera: _isFrontCamera,
    );
    onPoseResult?.call(pose);
  }

  InputImage? _buildInputImage(CameraImage image) {
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(_sensorOrientation);
    } else {
      final deviceOrientation = _cameraController?.value.deviceOrientation ??
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

  Future<void> dispose() async {
    _disposed = true;
    try {
      await _cameraController?.stopImageStream();
    } catch (_) {}
    await _cameraController?.dispose();
    _cameraController = null;
    await _poseDetector.close();
    poseFrame.dispose();
    permissionDenied.dispose();
    isReady.dispose();
  }
}
