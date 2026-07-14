# Awaken: Material 3 Expressive Redesign Plan

This document outlines the comprehensive plan for redesigning the "Awaken" app using the **Material 3 Expressive** design system.

The "Awaken" app is a camera-verified fitness alarm and territory capture app. The redesign focuses on making the UI more dynamic, vibrant, and engaging, shifting away from standard Material or flat dark mode into a highly expressive, gamified, and modern aesthetic.

## 1. Design Tokens Specification

Material 3 Expressive emphasizes high-chroma colors, playful and oversized typography, dynamic layouts, and expressive shape language.

### 1.1 Color Palette (Vibrant & Gamified)
The new palette moves away from muted tones, favoring high-energy "neon" accents suitable for a fitness/gamified context against a deep, rich dark background.

*   **Seed Color (Brand):** Electric Cyan / "Hyper Blue" (`#00E5FF`). This represents energy, awakening, and the core brand identity.
*   **Background (Canvas):** "Deep Space" (`#09090B`). Not absolute zero black (`#000000`), but a very dark, rich cool gray to allow surface layers to pop.
*   **Surface / Cards:** "Obsidian" (`#18181B`). For elevated cards and containers.
*   **Primary Accent:** Hyper Blue (`#00E5FF`). Used for primary actions, active states, and core HUD elements.
*   **Secondary Accent (Gamified/HUD):** "Plasma Purple" (`#B026FF`). Used for territory paths, secondary highlights, and gamified progress indicators.
*   **Success (Perfect Rep/Streak):** "Neon Mint" (`#34D399`). High-saturation green.
*   **Destructive (Bad Form/Penalty):** "Laser Red" (`#FF3B30`). Vibrant, aggressive red for missed alarms or bad form.
*   **Territory Owned (Map):** "Aurora Teal" (`#2EE6C5`).
*   **Territory Rival Alert (Map):** "Solar Flare" (`#FFB020`).

**Material 3 Tonal Mapping Strategy:**
We will use the Material 3 `ColorScheme.fromSeed` (or dynamic color) using the Hyper Blue seed, but heavily override the dark mode defaults to ensure the high-chroma accents remain vibrant and are not muted by the standard M3 dark mode algorithm.

### 1.2 Typography (Playful & Oversized)
The existing Space Grotesk (sans) and Space Mono (monospace) families are excellent fits for a modern, gamified app. M3 Expressive pushes for larger, tighter typography for headers and numbers.

*   **Display/HUD Numerics (Space Mono):**
    *   *Display Large (Clock/Main Counter):* `100px`, `Weight: 800`, tighter tracking (`-3`).
    *   *Display Medium:* `72px`, `Weight: 700`, tracking (`-2`).
*   **Headlines (Space Grotesk):**
    *   *Headline Large (Screen Titles):* `40px`, `Weight: 800`, tight line height (`1.1`).
    *   *Headline Medium (Card Titles):* `28px`, `Weight: 700`.
*   **Body & Labels (Space Grotesk):**
    *   *Body Large:* `18px`, `Weight: 400`, relaxed line height (`1.6`).
    *   *Label Large (Buttons/Eyebrows):* `14px`, `Weight: 700`, uppercase, wide tracking (`1.5`).

### 1.3 Shapes & Elevation
M3 Expressive uses more extreme corner radii and soft, glowing elevations to denote hierarchy rather than harsh borders.

*   **Cards/Containers:** Large rounded corners (`BorderRadius.circular(32)`).
*   **Buttons:** Fully rounded "pill" shapes (`StadiumBorder`) for primary actions, or playful "squircle" continuous curves.
*   **Elevation:** Replace harsh borders (`1px solid border`) with subtle, colored drop shadows (e.g., a faint Hyper Blue glow behind the primary action button).

---

## 2. UI Screen Redesign Specifications

### 2.1 Dashboard Screen
**Current State:** Standard stat cards and a digital clock.
**M3 Expressive Redesign:**
*   **Layout:** Masonry or staggered grid layout for stat cards, breaking the rigid vertical list.
*   **Digital Clock:** Make it massive, bleeding to the edges of the container. Use a slight gradient or neon glow effect on the text.
*   **Stat Cards (`StatCard`, `WeekTrendCard`):** Increase corner radii to `32px`. Remove borders. Add a subtle, large blurred gradient background behind the stat numbers to make them "pop" (e.g., a faint purple blur behind the streak count).
*   **Armed Alarm Card:** Needs to feel "active." Use a pulsing animation or a vibrant border gradient when an alarm is armed.

### 2.2 Alarm Flow (Active Alarm, Camera HUD)
**Current State:** Wireframe overlay, rep counter, squad sheet.
**M3 Expressive Redesign:**
*   **Camera HUD Overlay:** Instead of a thin wireframe, use thick, glowing M3 Expressive lines for the skeleton tracker (`PoseOverlayPainter`).
*   **Rep Counter Display:** Make this the central, most dominant UI element. When a rep is completed, trigger an expressive M3 burst animation (using `flutter_animate` for scale/bounce/color flash).
*   **Squad Sheet:** Use a bottom sheet with a highly rounded top edge (`40px`). Display squad mates using vibrant avatar rings that glow when they complete reps.
*   **Tax Reveal Stamp:** Use dramatic typography. When the tax is paid (success), stamp it with an angled, oversized "PAID" badge using the Neon Mint color, complete with haptic feedback and a particle burst.

### 2.3 Territory Screen (Map, Leaderboard)
**Current State:** Vector map with polygons, simple leaderboard.
**M3 Expressive Redesign:**
*   **Map HUD (`RunControls`):** Float controls heavily above the map. Use large, expressive floating action buttons (FABs) with glowing shadows.
*   **Leaderboard (`LeaderboardPodium`):** The podium should be a visual centerpiece. Instead of just rows, the top 3 should have custom, large "cards" that overlap, using the Gold/Silver/Bronze colors as rich, vibrant gradients rather than flat colors.
*   **Run Stats Sheet:** Similar to the Alarm squad sheet, heavily rounded corners. The `DistanceFormat` text should be massive and playful.
*   **Territory Polygons:** Enhance the `territoryOwnedGlow`. Make the polygons pulse gently.

### 2.4 Success Screen
**Current State:** Stat reveal, streak badge.
**M3 Expressive Redesign:**
*   **Overall Vibe:** Pure celebration. The background should not be flat dark; it should have a subtle, animated radial gradient.
*   **Streak Badge:** Make this an expressive 3D-like or heavily styled 2D asset. Use M3 Expressive's emphasis on oversized iconography. The number inside should bounce into place.
*   **Stat Reveal Items:** Stagger the entrance animations (slide up + fade + scale) with highly exaggerated easing curves (e.g., `Curves.elasticOut`).

### 2.5 Auth & Onboarding
**Current State:** Standard forms.
**M3 Expressive Redesign:**
*   **Onboarding:** Edge-to-edge imagery or abstract 3D shapes. Massive, bold typography for the value propositions ("WAKE UP.", "PAY THE TAX."). Primary CTA should be a large, glowing pill button anchored to the bottom.
*   **Auth Screen:** Simplify inputs. Use "filled" text fields (M3 standard) with a highly rounded shape (`BorderRadius.circular(24)`). Active text fields should have a vibrant `Hyper Blue` outline and a subtle glow.

---

## 3. Implementation Plan (Next Steps for Codebase)

1.  **Update `app_colors.dart`:** Replace existing static consts with the new vibrant palette. Define glow variants explicitly.
2.  **Update `app_typography.dart`:** Adjust font sizes, weights, and tracking to match the M3 Expressive oversized/playful guidelines.
3.  **Update `app_theme.dart`:**
    *   Implement `ColorScheme.fromSeed` using the new Hyper Blue, customized for dark mode.
    *   Update `CardThemeData` for `32px` border radii and no borders.
    *   Update `ElevatedButtonThemeData` to use `StadiumBorder` or `32px` radii.
    *   Update `BottomSheetThemeData` (add if missing) for extreme top rounding.
4.  **Refactor Components (`features/**/presentation/widgets`):**
    *   Go through the widgets listed above and remove manual layout rigidity.
    *   Inject `flutter_animate` more aggressively for state changes (e.g., rep counts, map captures).
    *   Ensure all text uses the newly defined expressive typography tokens.
