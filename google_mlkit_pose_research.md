# Awaken App: Wake Up Tax & Google ML Kit Pose Detection Analysis

This document provides a comprehensive review of the current implementation of the Wake Up Tax and Google ML Kit Pose Detection in the Awaken Flutter App, along with extensive online research on best practices, documentations, and existing implementations for exercise detection using Google ML Kit.

## 1. Current Implementation Review (Awaken App)

### 1.1 How the Wake Up Tax (Alarm) Works
The Wake Up Tax is a gamified alarm system designed to force the user to exercise to dismiss the alarm. 

- **Scheduling**: The app uses `flutter_local_notifications` for exact scheduling (`exactAllowWhileIdle`) and full-screen intents.
- **Alarm Lifecycle**: When the alarm fires, it launches a non-dismissable full-screen view. The user is forced to perform a preset or Roulette-selected exercise (Squats, Push-ups, Jumping Jacks, or High Knees). 
- **Penalty System**: Failing to complete the alarm within 2 hours applies a "bailout" penalty, doubling the rep count for the next day. This penalty is also shared with "squad" members via Supabase Realtime RPCs.
- **Out-of-Frame Penalty**: If the user is out of frame, the alarm volume ramps up.
- **Completion**: Completing the reps logs the session (local-first, then syncs to Supabase), increases streaks, and dismisses the alarm.

### 1.2 Google ML Kit Pose Detection Implementation
The app implements pose detection using the `google_mlkit_pose_detection` package.

- **Camera Setup**: The app uses the `camera` package, defaulting to `ResolutionPreset.medium` for the front camera. For Android, it requests `ImageFormatGroup.nv21`, falling back to `YUV_420_888` which is manually interleaved to `NV21` inside the `AlarmPosePipeline` so ML Kit can process it.
- **Detector Configuration**: The `PoseDetector` is initialized in `stream` mode, which is highly optimized for video feeds as it tracks subjects across frames.
- **Throttling**: Frame processing is throttled to ~15 FPS (every 66ms) inside `_onCameraImage` to save battery and reduce CPU load.
- **State Machines for Exercises**: Each exercise has a counter service (e.g., `SquatCounterService`). 
  - It filters joint angles using a Double Exponential Moving Average (EMA) filter (`alpha: 0.35`) to smooth out the jitter in the ML Kit landmarks.
  - It calculates angles using vector dot/cross products (`atan2`) on 3 landmarks (e.g., hip, knee, ankle).
  - Reps are counted using a finite state machine (Standing $\rightarrow$ Squatting $\rightarrow$ Standing).
  - It uses calibration (holding a standing pose for 8 frames) to calculate a normalized hip-to-knee depth ratio based on torso length, ensuring accurate depth tracking regardless of distance to the camera.
  - Bad form (like excessive shoulder tilt) is actively monitored and flagged.

---

## 2. Comprehensive Online Research: Google ML Kit Pose Detection

### 2.1 Official Documentation & API References
Google ML Kit Pose Detection is a lightweight, on-device ML vision API that provides a **33-point skeletal match** of a subject's body in real time. 
- **Android Documentation**: The official documentation resides on [Google Developers ML Kit Portal](https://developers.google.com/ml-kit/vision/pose-detection). It details setting up the `PoseDetector`, preparing `InputImage` objects from camera feeds, and handling the resulting `Pose` objects.
- **Flutter Package**: The official Flutter community package is [`google_mlkit_pose_detection`](https://pub.dev/packages/google_mlkit_pose_detection). It acts as a bridge to the native iOS and Android ML Kit APIs. 

### 2.2 Best Practices for Flutter & Android
Based on community consensus and Google's guidelines, here are the best practices for using this API in production Flutter apps:

1. **Use `STREAM_MODE` for Video**: As implemented in Awaken, always use `PoseDetectionMode.stream` for real-time video. It tracks the person between frames, drastically reducing latency compared to `single_image` mode.
2. **Throttle Processing Rate**: Never process every single frame from a 60FPS camera stream. Throttling to 15-30 FPS (like Awaken's 66ms delay) provides a perfect balance of responsiveness and thermal/battery management.
3. **Hardware Acceleration**: Ensure the app uses modern configurations (Android API 23+) so ML Kit can utilize NNAPI (Neural Networks API) or GPU delegation automatically.
4. **Smooth the Landmarks**: Pose landmarks inherently jitter. A smoothing algorithm is mandatory for exercise counters. Awaken uses an EMA (Exponential Moving Average) filter, which is an industry-standard approach for real-time sensor data.
5. **Coordinate Translation**: When overlaying skeleton lines (like Awaken's neon UI), always translate the coordinates from the `InputImage` size to the Flutter widget's display size, considering the camera rotation and mirroring (front camera).
6. **Warm-up Latency**: The first frame processing can take up to several hundred milliseconds because the ML model is loaded into memory. 

### 2.3 Existing Implementations & Logic for Exercise Detection (Squats/Push-ups)
Detecting exercises is generally done by mapping human biomechanics to trigonometry using the 33 landmarks.

- **Squats Logic**:
  - **Landmarks**: Hip, Knee, Ankle, Shoulder.
  - **Mechanics**: Calculate the angle at the knee (Hip $\rightarrow$ Knee $\rightarrow$ Ankle).
  - **State Transitions**: 
    - Standing: Angle $> 150^{\circ}$
    - Squatting: Angle $< 100^{\circ}$ (or dynamic depth ratio, as Awaken cleverly implements to avoid false positives at different distances).
- **Push-ups Logic**:
  - **Landmarks**: Shoulder, Elbow, Wrist.
  - **Mechanics**: Calculate the angle at the elbow (Shoulder $\rightarrow$ Elbow $\rightarrow$ Wrist).
  - **State Transitions**:
    - Up position: Angle $> 150^{\circ}$ (arms extended).
    - Down position: Angle $< 90^{\circ}$ (arms bent).
  
### 2.4 Notable GitHub Repositories for Reference
If you wish to expand the exercise library, these open-source Flutter projects demonstrate ML Kit exercise detection:

1. **[PushUpCounter](https://github.com/Princeish07/PushUpCounter.git)**: A dedicated Flutter package specifically built to count push-ups using ML Kit pose detection. It shows a basic state machine implementation.
2. **[SW21_OSAM_HACKATHON_FINAL (MyPT)](https://github.com/jonginj0130/SW21_OSAM_HACKATHON_FINAL)**: An award-winning project that tracks Squats, Push-ups, and Pull-ups. It includes excellent logic for analyzing joint angles and providing voice feedback based on movement correctness.
3. **[pose-detection-flutter](https://github.com/nainarathore/pose-detection-flutter)**: A great foundational repository showing how to correctly map the 33 landmarks to a Flutter `CustomPainter` for real-time skeletal overlays.

> [!TIP]
> **Awaken's implementation is extremely robust.** Features like the EMA angle filtering, dynamic depth ratio calculation (to account for the user's distance from the phone), and YUV to NV21 manual byte conversion represent advanced, production-grade usage of the ML Kit API that surpasses most open-source examples.
