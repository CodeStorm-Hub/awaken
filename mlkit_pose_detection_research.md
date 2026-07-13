# Awaken App & Google ML Kit Pose Detection Research Report

This document compiles the complete review of the Awaken App's existing implementation, along with comprehensive online research into Google ML Kit Pose Detection, its API structure, best practices, and the algorithms used to detect various exercises.

---

## 1. Review of the Current Implementation (Awaken App)

Based on the analysis of the `PROJECT_ANALYSIS_REPORT.md` and the `lib` directory (specifically `alarm_pose_pipeline.dart` and `squat_counter_service.dart`), the Awaken app implements a highly robust, production-grade pose detection pipeline.

### How the Wake Up Tax (Alarm) Works
* **Strict Accountability**: Uses exact scheduling (`flutter_local_notifications` with `exactAllowWhileIdle`) and full-screen intents. There is no snooze or dismiss button; swiping away or closing the app is blocked via `PopScope(canPop: false)`.
* **The "Tax"**: To silence the alarm, the user must perform a chosen exercise (Squats, Push-Ups, Jumping Jacks, or High Knees) for a set number of repetitions. 
* **Gamification & Penalties**: Abandoning the alarm applies a 2-hour "bailout penalty", doubling the reps for the next alarm. If in a "Squad," this penalty affects friends via Supabase Realtime RPCs. An out-of-frame audio ramp penalty prevents users from hiding from the camera.

### How Google ML Kit Pose Detection is Implemented
* **Camera Pipeline & Android Quirks**: The app manages the camera via `AlarmPosePipeline`. Crucially, it handles Android's tendency to output a 3-plane `YUV_420_888` buffer by manually interleaving it into the `NV21` format required by ML Kit.
* **Stream Processing & Throttling**: The `PoseDetector` runs in `stream` mode. The app intentionally throttles frame processing to ~15 FPS (every 66ms) to prevent thermal throttling and battery drain.
* **Exercise State Machines**: 
  * Uses a **Calibration Phase** (holding a pose for 8 frames) to establish a baseline for body proportions, ensuring accurate depth tracking regardless of the user's distance from the camera.
  * Uses a **Double Exponential Moving Average (EMA)** filter (alpha: 0.35) to smooth out noisy, jittery landmarks before making counting decisions.
  * Calculates joint angles using the `atan2` dot/cross product method and counts reps using a finite state machine.

---

## 2. Google ML Kit Pose Detection API Reference

> [!IMPORTANT]
> **It is NOT a REST API.** Google ML Kit Pose Detection is an **on-device SDK**. There are no HTTP REST API endpoints to send images to. This ensures zero latency, offline capability, and total privacy.

Instead of network endpoints, you interact with native SDK methods. In Flutter, using the `google_mlkit_pose_detection` package, you call Dart methods that bridge to native Java/Swift code:

1. **Initialization**: 
    ```dart
    final poseDetector = PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.stream));
    ```
2. **Processing a Frame (The main "endpoint")**:
    ```dart
    // Takes an InputImage and returns a List of Poses (33 landmarks)
    final List<Pose> poses = await poseDetector.processImage(inputImage); 
    ```
3. **Resource Management**:
    ```dart
    await poseDetector.close(); // MUST be called to prevent memory leaks
    ```

---

## 3. Best Practices for Flutter & Android Integration

1. **Stream Mode vs. Single Image**: Always configure `PoseDetectorOptions` to use `PoseDetectionMode.stream` for real-time video. It tracks the subject across frames, drastically reducing latency.
2. **Frame Throttling**: Never process every single frame from a 60FPS stream. Throttling to 15-20 FPS prevents the platform channel from backing up and freezing the UI.
3. **Hardware Acceleration**: ML Kit on Android delegates to the CPU by default but can use GPU acceleration on supported devices. The Flutter plugin handles this natively.
4. **Jitter Reduction (Critical)**: Raw ML Kit landmarks will jitter. A smoothing algorithm like an Exponential Moving Average (EMA) filter is mandatory before calculating angles to prevent false positive rep counts.

---

## 4. Exercise Detection Heuristics (Math & Algorithms)

To count exercises, you must build a **Finite State Machine (FSM)** and use **Angle Heuristics** (trigonometry) based on the 33 landmarks. An angle is calculated using `atan2` on 3 landmarks (Point A, Vertex B, Point C).

### 🏋️ Lower Body Exercises

**1. Squats**
* **Active Landmarks**: Hip, Knee, Ankle. (Vertex: Knee)
* **State Machine**:
  * **State 0 (Standing)**: Knee angle $> 160^\circ$.
  * **State 1 (Squatting)**: Knee angle $< 100^\circ$ (and depth ratio is sufficient).
  * **Count Rep**: Transition from State 1 back to State 0.

**2. Lunges**
* **Active Landmarks**: Hip, Knee, Ankle (Focusing on the leading leg).
* **State Machine**:
  * **State 0 (Standing)**: Knee angle $> 160^\circ$.
  * **State 1 (Lunge Position)**: Leading Knee angle drops to $\approx 90^\circ$ AND the trailing knee's Y-coordinate approaches the Ankle's Y-coordinate (touching the floor).
  * **Count Rep**: Transition back to State 0.

### 💪 Upper Body Exercises

**3. Push-Ups**
* **Active Landmarks**: Shoulder, Elbow, Wrist. (Vertex: Elbow)
* **Form Check**: Shoulder $\rightarrow$ Hip $\rightarrow$ Ankle angle must remain $> 160^\circ$ (straight back).
* **State Machine**:
  * **State 0 (Up/Plank)**: Elbow angle $> 150^\circ$.
  * **State 1 (Down)**: Elbow angle $< 90^\circ$ (chest near the floor).
  * **Count Rep**: Transition back to State 0.

**4. Pull-Ups**
* **Active Landmarks**: Shoulder, Elbow, Wrist. (Vertex: Elbow)
* **State Machine**:
  * **State 0 (Dead Hang)**: Elbow angle $> 160^\circ$.
  * **State 1 (Pulled Up)**: Elbow angle $< 60^\circ$ (chin over the bar).
  * **Count Rep**: Transition back to State 0.

**5. Bicep Curls**
* **Active Landmarks**: Shoulder, Elbow, Wrist. (Vertex: Elbow)
* **Form Check**: The Elbow's spatial coordinates $(x, y)$ should remain relatively static to prevent swinging.
* **State Machine**:
  * **State 0 (Extension)**: Elbow angle $> 160^\circ$.
  * **State 1 (Flexion)**: Elbow angle $< 45^\circ$.
  * **Count Rep**: Transition back to State 0.

### 🏃‍♂️ Cardio & Core Exercises

**6. Jumping Jacks**
* **Active Landmarks**: Left/Right Wrists, Left/Right Ankles, Nose.
* **Heuristic**: Distance-based.
* **State Machine**:
  * **State 0 (Closed)**: Wrists Y-coordinate is *below* the Nose. X-distance between Ankles is minimal.
  * **State 1 (Open)**: Wrists Y-coordinate is *above* the Nose. X-distance between Ankles is $> 1.3\times$ shoulder width.
  * **Count Rep**: Transition from State 1 back to State 0.

**7. High Knees**
* **Active Landmarks**: Left/Right Hip, Left/Right Knee.
* **Heuristic**: Y-Axis intersection.
* **State Machine**:
  * **State 0 (Neutral)**: Both Knees are vertically below the Hips.
  * **State 1 (Left Lift)**: Left Knee Y-coordinate rises to meet/exceed Left Hip Y-coordinate.
  * **State 2 (Right Lift)**: Right Knee Y-coordinate rises to meet/exceed Right Hip Y-coordinate.
  * **Count Rep**: Requires alternating sequence (State 1 $\rightarrow$ State 0 $\rightarrow$ State 2 $\rightarrow$ State 0).

**8. Sit-Ups / Crunches**
* **Active Landmarks**: Shoulder, Hip, Knee. (Vertex: Hip)
* **State Machine**:
  * **State 0 (Lying Down)**: Hip angle $> 150^\circ$.
  * **State 1 (Crunch)**: Hip angle $< 70^\circ$ (torso approaching the knees).
  * **Count Rep**: Transition back to State 0.

---

### Alternative Approach: ML Classification (k-NN)
For exercises that are too complex to map purely with angle math (e.g., Kettlebell Swings, Burpees), the standard alternative is to use **k-Nearest Neighbors (k-NN)** classification. This involves taking hundreds of frame snapshots in the "Up" and "Down" states, extracting the 33 landmark coordinates, and training a lightweight TensorFlow Lite model to classify the pose in real-time based on its similarity to the training data.

---

## 5. References & Useful Links

### Official Documentation
* **ML Kit Pose Detection API (Android)**: [Google Developers Guide](https://developers.google.com/ml-kit/vision/pose-detection/android)
* **Flutter Plugin (`google_mlkit_pose_detection`)**: [Pub.dev Package](https://pub.dev/packages/google_mlkit_pose_detection)
* **Flutter ML Kit GitHub Repository**: [flutter-ml/google_ml_kit_flutter](https://github.com/flutter-ml/google_ml_kit_flutter)

### Open-Source Exercise Detection References
* **PushUpCounter**: [GitHub - Princeish07/PushUpCounter](https://github.com/Princeish07/PushUpCounter.git) (A dedicated Flutter package specifically built to count push-ups using ML Kit pose detection state machines).
* **SW21_OSAM_HACKATHON_FINAL (MyPT)**: [GitHub - jonginj0130/SW21_OSAM_HACKATHON_FINAL](https://github.com/jonginj0130/SW21_OSAM_HACKATHON_FINAL) (Award-winning project tracking Squats, Push-ups, and Pull-ups with excellent logic for analyzing joint angles).
* **pose-detection-flutter**: [GitHub - nainarathore/pose-detection-flutter](https://github.com/nainarathore/pose-detection-flutter) (Foundational repository showing how to map 33 landmarks to a Flutter `CustomPainter` for real-time skeletal overlays).
