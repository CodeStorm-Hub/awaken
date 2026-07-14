# Wake Up Tax — Pose Detection Thresholds

These numbers are **tuned, tested design decisions**, not placeholders or TODOs. Google publishes no official rep-counting reference algorithm for ML Kit Pose Detection — every threshold below was hand-derived for Awaken and validated against the test suites in `test/alarm/`. Do not "correct" these toward a generic online value without re-testing against the existing coverage.

See [`docs/user_story/mlkit_pose_detection_hardening_plan.md`](user_story/mlkit_pose_detection_hardening_plan.md) for the audit history behind these values, and `PROJECT_ANALYSIS_REPORT.md` for the wider codebase context.

## Squats (`squat_counter_service.dart`)

| Constant | Value | Meaning |
|---|---|---|
| `squatThresholdDeg` / down trigger | ≤100° | Knee angle at which a squat is registered as started |
| `standThresholdDeg` | ≥150° | Knee angle at which a rep completes (returning to standing) |
| Calibration entry | ≥160° | Stricter than the stand threshold — requires a clearly upright starting pose before calibration locks in |
| `requiredCalibrationFrames` | 8 | Consecutive standing frames needed to calibrate — highest of the four counters, since squat depth is the most safety/injury-sensitive measurement |
| `AppConstants.squatDepthThreshold` | 0.6 | Hip-to-knee depth ratio below which a squat is rejected as partial |
| `AppConstants.maxShoulderTiltRatio` | 0.18 | Max normalized left/right shoulder height delta before flagged as bad form |

## Push-ups (`push_up_counter_service.dart`)

| Constant | Value | Meaning |
|---|---|---|
| `downElbowDeg` | ≤90° | Elbow angle at which the down phase registers |
| `upElbowDeg` | ≥150° | Elbow angle at which a rep completes |
| `descentStartDeg` | <130° | Elbow angle at which a descent is considered "started" for shallow-rep detection — a dip that crosses this but never reaches 90° before returning to 150°+ is flagged once as "TOO SHALLOW — CHEST TO FLOOR" |
| `requiredCalibrationFrames` | 6 | Lower than squats — elbow-extension calibration is a less safety-sensitive starting pose |

Shallow-rep detection is a state-transition machine keyed off these three angle bands, **not** frame-count-gated — there is no wall-clock/frame-count window to document here (see Phase 1.2 correction in the hardening plan: this was originally assumed to need the same fix as jumping jacks, but investigation found it doesn't apply).

## Jumping jacks (`jumping_jack_counter_service.dart`)

| Constant | Value | Meaning |
|---|---|---|
| `feetOutRatio` | 1.35× | Ankle gap must reach 1.35× the calibrated **standing ankle gap** (not shoulder width) to count as "feet out" |
| `requiredCalibrationFrames` | 6 | |
| `AppConstants.badFormAsymmetryWindow` | 700ms | Wall-clock duration an arms/feet mismatch must persist before it's flagged as bad form — converted from a raw frame count (10 frames) in Phase 1.2 so the real-world debounce duration stays constant regardless of actual sustained device frame rate |
| Arms-up definition | `wrist.y <= nose.y` (both sides) | Image Y grows downward, so this is "wrists at or above nose height" |

## High knees (`high_knees_counter_service.dart`)

| Constant | Value | Meaning |
|---|---|---|
| `liftFraction` | 0.15 | Knee counts as lifted once it rises to within 15% of standing thigh length below hip level |
| `plantFraction` | 0.6 | Knee counts as planted again once it drops below 60% of standing thigh length under the hip — the gap between 0.15 and 0.6 is deliberate hysteresis so jitter near the lift threshold can't double-count a rep |
| `requiredCalibrationFrames` | 6 | |

Both thresholds are normalized against the calibrated standing hip-to-knee distance, not raw pixel distance — this keeps detection independent of camera resolution and how far the user stands from the phone.

## Shared

- **Smoothing:** all four counters run their raw angle/gap measurement through an `EmaFilter` (`exercise_counter.dart`), α = 0.35 — a single-pass exponential moving average. (Named `EmaFilter`, not `DoubleEMAFilter`, as of the Phase 2.4 rename — it was never a true double EMA.)
- **Angle geometry:** squats and push-ups share `JointAngle.between` (`joint_angle.dart`), `atan2(cross, dot)` form, as of the Phase 2.2 unification.
- **Landmark confidence gate:** each counter requires `likelihood >= minConfidence` (0.45–0.5 depending on exercise) on every joint it reads before trusting a frame; below that, the frame is treated as "no pose" rather than fed through the state machine.
- **Frame rate assumption:** the camera pipeline throttles to ~15 FPS (66ms/frame) via `AlarmPosePipeline._onCameraImage`. Any new time-based threshold should be expressed as a `Duration` (see `badFormAsymmetryWindow`) and compared against the frame's actual capture timestamp — never a raw frame count — so behavior doesn't silently change on slower devices.
