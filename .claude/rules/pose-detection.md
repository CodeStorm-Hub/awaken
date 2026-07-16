---
globs:
  - "lib/features/alarm/**/*.dart"
---

# Pose Detection Pipeline Guidelines
- Camera verified Alarm flow is currently ONLY targetting Android (iOS will be launched later).
- Front camera lifecycle must follow `_initCamera()` -> NV21 image stream -> pose detection.
- Stream throttled to ~15 FPS using a `66ms` skip window and `_isDetecting` guard.
- ML Kit `InputImage` mapping: NV21 on Android (concatenated planes), BGRA on iOS.
- Coordinate transformation (`PoseOverlayPainter._toScreen`) must handle mirror scaling to avoid misalignment.
- State machine in `SquatCounterService` uses knee joint angles: squat triggers <= 100°, returns >= 150° for success rep.
- Always implement accessibility fallback (tapping to simulate reps) so users are never trapped.
- On `dispose()`, release resource sequence: stop image stream -> dispose controller -> close detector -> stop audio -> disable wakelock.
