Here are some feature improvements and new feature concepts designed specifically to amplify Awaken's core brand personality: **disciplined, neon, motivating.** These suggestions build directly on your existing Flutter, Supabase (PostGIS), and ML Kit architecture.

### 1. Expanding the "Wake Up Tax" (Alarm Engine)

The current squat-verified alarm is a strong hook. To prevent users from getting too comfortable, you can introduce unpredictability.

* **Tax Roulette (Dynamic Exercises):** Instead of just squats, expand the `alarm_pose_pipeline.dart` to detect other exercises. The user wakes up and the HUD demands 15 Jumping Jacks, 10 Push-ups, or 20 High-Knees.
* *Implementation:* ML Kit's pose detection provides the full skeletal node map. You can build separate state machines (similar to your `SquatCounterService`) that measure wrist-to-hip distance for jumping jacks or shoulder-to-floor distance for push-ups.


* **Escalating Penalties (Anti-Cheat):** Right now, if a user force-closes the app or uninstalls it to avoid the alarm, they technically escape the tax.
* *Implementation:* Log the alarm trigger locally. If the `sessions` repository doesn't record a completed session within a specific timeframe, apply a "Bailout Penalty." The next morning's alarm automatically doubles the required reps, turning a 10-rep tax into a 20-rep punishment.


* **Unlockable HUDs & Scanner Themes:** Lean into the "neon/cyber" aesthetic. Reward long streaks (e.g., 7, 30, 90 days) by unlocking new visual themes for the `CameraHudOverlay` and `ScanLineAnimation`.

### 2. Amplifying the Turf War (Territory Mode)

The PostGIS and vector map architecture is already set up for advanced geospatial mechanics. Make the map feel alive and highly competitive.

* **Live Turf Defense (Push Notifications):** If a rival user runs a closed loop that overlaps and captures a portion of a user's territory (calling your `capture_territory` RPC), instantly trigger a push notification to the defending user: *"Your territory is under attack. Run within 24 hours to reclaim it."*
* **Fog of War / Uncharted Zones:** Instead of letting users see the entire global map, shroud areas where they haven't run in a dark, grid-like overlay. As they run, their GPS trail "clears" the fog, permanently revealing the map underneath.
* *Implementation:* You can achieve this by adding a masking polygon layer in `territory_map_style.dart` that is carved out by the user's historical `geom` data.


* **High-Value "Bounty" Zones:** Introduce system-generated, temporary zones on the map. If a user runs a loop that encompasses this zone before it expires, they get a massive streak multiplier or a special badge on the leaderboard.

### 3. Social & Brutal Accountability

Fitness apps usually use positive reinforcement. Awaken can stand out by using "shared suffering" and intense accountability.

* **Squad Taxes (Multiplayer Alarms):** Allow users to link their alarms via Supabase. If one person fails to complete their Wake Up Tax, the *entire squad* loses their streak or gets hit with an escalating penalty the next day.
* *Implementation:* Use Supabase Realtime on a new `squad_alarms` table. When the alarm triggers, users can see a live HUD of their squadmates' rep counts updating in real-time.


* **The "Nemesis" System:** Analyze the `territory_captures` history in Supabase to find two users who frequently overwrite each other's turf. Automatically flag them as "Nemeses" on the dashboard, tracking who currently holds more of the disputed area.

### 4. Technical Polish & UX

* **"Grace Period" GPS Pause:** Running in urban environments often means hitting red lights. Add a smart auto-pause feature to the `LocationFixService` so users don't have their anti-cheat speed cap flagged or their time penalized while waiting to cross a street.
* **Post-Run Flyover:** After capturing a territory and hitting the `SuccessScreen`, use `flutter_map`'s camera controller to do a smooth, cinematic 3D flyover of the newly captured polygon before routing the user back to the dashboard. This provides a massive hit of dopamine after a grueling run.