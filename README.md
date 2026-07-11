# Awaken

A camera-verified fitness alarm and territory capture app. The alarm will not stop until you complete real movement — squats, push-ups, jumping jacks, or high-knees — verified on-device with your camera. Territory mode turns outdoor runs into map claims you can defend, steal, and rank for.

**Brand:** disciplined · neon · motivating  
**Platforms:** Android (primary), iOS (secondary)

---

## Features at a glance

| Feature | What it does |
|---------|----------------|
| **Wake Up Tax** | Alarm dismisses only after camera-verified reps |
| **Tax Roulette** | Random exercise each morning (or fixed type you choose) |
| **Bailout penalty** | Skip the tax → next alarm can double the reps |
| **Dashboard** | Clock, next alarm, streak, weekly/monthly stats |
| **HUD themes** | Neon camera overlays unlocked by streak (and Pro) |
| **Squad Taxes** | Shared accountability; live rep bars with squadmates |
| **Territory runs** | GPS loops claim map polygons |
| **Fog of war** | Optional veil over unexplored map areas |
| **Bounty zones** | Temporary high-value areas with multipliers |
| **Turf defense** | Push alerts when someone steals your land |
| **Nemesis** | Tracks your top territorial rival |
| **Leaderboard (Ranks)** | Compare claimed area with others |
| **Cloud sync** | Optional sign-in for backup across devices |

---

# User manual

This section is for everyday use of the app — not for developers.

## 1. First launch & permissions

1. Install and open **Awaken**.
2. Allow the permissions the OS asks for when you use each feature:
   - **Notifications** — so alarms and turf-hit alerts can fire
   - **Alarms & reminders** (Android) — for exact wake-up times
   - **Camera** — to verify your Wake Up Tax
   - **Location** — for territory runs
3. You can use the app **offline** without an account. Sign in later if you want cloud backup, squads, leaderboards, and rival features.

### Sign in (optional)

- Open **Auth** from the app when prompted, or use the account entry on the home flow.
- Sign in with **Google** (or email, if enabled).
- Signed-in benefits: alarms/sessions/territory sync, squads, nemesis, push turf defense, fog sync across devices.

---

## 2. Home (Dashboard)

The **HOME** tab is your morning command center.

| Element | Meaning |
|---------|---------|
| **Large clock** | Current time |
| **Date** | Today’s date |
| **Tap to set your alarm** | Create or edit your Wake Up Tax alarm |
| **Run a loop, claim territory** | Shortcut to Territory (with Details for overview) |
| **Streak ring** | How many consecutive days you’ve paid the tax |
| **This week / This month** | Reps and calorie-style summary from completed sessions |
| **HUD THEME** | Camera overlay look for the active alarm |
| **Squad Taxes** | Create or join a squad for shared accountability |
| **Test Active Alarm** (debug builds) | Jump straight into the tax screen for testing |

### Setting an alarm

1. Tap **Tap to set your alarm**.
2. Choose **time** and **repeat days**.
3. Set **required reps** (how many movements to dismiss the alarm).
4. Choose exercise mode:
   - **Fixed** — always the same exercise (squats, push-ups, jumping jacks, or high-knees)
   - **Roulette** — the app picks an exercise for that morning (keeps you from gaming one easy move)
5. Save. The next alarm appears on the home card when armed.

**Tip (Android):** If alarms are late or silent, enable **Alarms & reminders** / exact alarms in system settings when Awaken prompts you.

---

## 3. Paying the Wake Up Tax (active alarm)

When the alarm fires (or you open the active alarm screen):

1. The screen shows a **tax reveal** — which exercise and how many reps.
2. Stand so your **full body** is in the front camera frame.
3. Perform the exercise with clear form. The HUD counts reps when the pose detector recognizes a complete movement.
4. Finish the required reps → alarm stops → success / celebration screen.
5. The session is logged toward your streak and weekly stats.

### Exercises

| Exercise | What the camera looks for (simplified) |
|----------|----------------------------------------|
| **Squats** | Knees bend deep, then stand tall |
| **Push-ups** | Body lowers and rises |
| **Jumping jacks** | Arms/legs open, then close |
| **High-knees** | Alternating knees lift high |

### Coaching cues

- Stay in frame — if you see an out-of-frame warning, step back or center yourself.
- Complete full reps; partial depth may not count.
- If **camera permission is denied**, you can still tap to simulate capped reps so you are never trapped (accessibility fallback).

### Bailout penalty

If you force-close the app, ignore the alarm, or otherwise fail to finish the tax in time:

- Awaken records a **bailout**.
- Your **next** Wake Up Tax can apply a **penalty multiplier** (e.g. 2× reps).
- Home / alarm cards may show a penalty chip so you know what’s coming.

**Don’t bail.** Pay the tax.

---

## 4. HUD themes

On Home, under **HUD THEME**, pick the neon look used on the active alarm camera overlay (scan line, skeleton, accents).

| Theme | How to unlock |
|-------|----------------|
| **Cyan** | Default — always available |
| **Magenta** | Streak ≥ **7** days |
| **Acid** | Streak ≥ **30** days **and** Awaken Pro |
| **Mono** | Streak ≥ **90** days **and** Awaken Pro |

- Locked chips show a **STR…** or **PRO** tag.
- Tap **UNLOCK PRO** (or a Pro-locked theme) to start a purchase when store products are configured.
- Themes change the *look* of the tax screen; they do not change how hard the exercise is.

---

## 5. Squad Taxes

Squads add shared accountability.

1. On Home, open **Squad Taxes**.
2. **Create** a squad (you get an invite code) or **Join** with a friend’s code.
3. During an active Wake Up Tax, you can see **live rep progress** for up to a few squadmates.
4. If someone **bails**, the squad can share the pain — bailout penalties can hit the whole group (as configured when you join).

Share your invite code carefully; anyone with the code can join.

---

## 6. Territory runs

Open the **TERRITORY** tab.

### Goal

Run outdoors, draw a **closed loop** with GPS, and **claim** the area inside as your territory on the map.

### How to run

1. Allow **location** when asked.
2. Center the map on yourself (locate button).
3. Tap **Start run**.
4. Run (or walk) a path that returns near where you started to close a loop.
5. Tap **Stop** when done. Valid loops are submitted for capture.
6. Watch the **cinematic flyover** of your new claim, then review area / steal / bounty results.

### While running

- Your trail draws on the map in neon.
- **Auto / manual pause (traffic grace):** if you stop at lights or stand still, the run can pause so idle time and speed checks are fairer. The HUD may show a paused / grace state.
- Switching tabs mid-run asks you to confirm discarding the active run.

### Claiming & stealing

- A valid closed loop claims that polygon.
- If your loop overlaps someone else’s land, you may **steal** part of their territory.
- Victims can get a **turf hit** notification: reclaim within the window (e.g. 24 hours) by running again.

### Bounty zones

- Temporary highlighted zones may appear on the map.
- Enclose a bounty zone in your loop before it expires for a **multiplier** and a **bounty badge** on the result / leaderboard context.

### Fog of war

- Optional dark veil over areas you have not explored.
- Running reveals cells along your path (synced to the cloud when signed in).
- Fog is **off by default**. Turn it on from **Territory overview** (**FOG ON / FOG OFF**).

### Territory overview

From the territory shortcut **Details** (or overview route):

- See your claimed polygons, decay risk, and fog toggle.
- Territory that isn’t reinforced can **decay** — keep running to hold your turf.

### Nemesis

When signed in and you’ve disputed land with the same rival often enough, Home / territory surfaces may show your **Nemesis** — who currently holds more of the contested area. Beat them by reclaiming and expanding.

---

## 7. Ranks (Leaderboard)

Open the **RANKS** tab.

- See how your claimed area stacks up against others.
- Bounty hits and large steals can affect how competitive you look on the board.
- Sign in for full cloud rankings; offline / local mode may show limited data.

---

## 8. Notifications you’ll see

| Notification | Meaning | What to do |
|--------------|---------|------------|
| **Alarm** | Wake Up Tax is due | Open the app and complete your reps |
| **Turf hit** | Someone stole or cut your territory | Open Territory and run to reclaim |
| **Decay warning** | Your land is at risk of fading | Reinforce with a new run |

Tapping a turf-hit notification should take you to the Territory tab.

---

## 9. Tips for a good experience

- **Camera tax:** good lighting, full body in frame, phone propped stable (not in your hand if possible).
- **Territory:** outdoor GPS works best; tall buildings can drift — pause at lights rather than jogging in place.
- **Streaks:** complete at least one tax per day; bailouts hurt tomorrow’s count.
- **Battery:** keep the screen on during the tax; Awaken uses a wake lock on the active alarm screen.
- **Privacy:** pose detection runs **on-device**; sign-in is optional for local-only use.

---

## 10. Troubleshooting

| Problem | Try this |
|---------|----------|
| Alarm didn’t fire | Check notification + exact-alarm permissions; keep the app installed; don’t force-stop Awaken |
| Reps don’t count | Step back, full body in frame, complete full range of motion |
| Camera blocked | Grant camera permission, or use the tap fallback if denied |
| GPS jump / invalid loop | Wait for a good fix, run a clearer loop, avoid tunnels |
| Squad / ranks empty | Sign in; check network; create or join a squad with a valid code |
| Themes won’t unlock | Build streak days; unlock Pro for Acid/Mono |
| Map looks fully clear | Fog is off by default — enable **FOG ON** in territory overview |

---

# For developers

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio / Xcode for device builds
- For cloud sync: Supabase credentials in `lib/core/constants/supabase_config.dart`, plus `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` (Firebase / FCM)
- Optional: `SUPABASE_ACCESS_TOKEN` for CLI secrets (see `scripts/set-firebase-fcm-secret.ps1`)

## Getting started

```bash
flutter pub get
flutter run -d android
flutter run -d ios
flutter analyze lib/
flutter test
dart run build_runner build --delete-conflicting-outputs
```

See [CLAUDE.md](CLAUDE.md) for architecture, commands, and coding conventions.

## Documentation

- [docs/awake_full_detail.md](docs/awake_full_detail.md) — deeper product / schema history  
- [docs/codebase_review.md](docs/codebase_review.md) — codebase review notes  
- [docs/territory_backend_verification_checklist.md](docs/territory_backend_verification_checklist.md) — territory backend checks  
- [PRODUCT.md](PRODUCT.md) — product purpose and brand  
- [new-feature.md](new-feature.md) — feature concepts that shaped recent waves  
