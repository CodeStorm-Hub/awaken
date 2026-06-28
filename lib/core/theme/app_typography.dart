import 'package:awaken/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom ThemeExtension that exposes HUD-specific text styles.
/// Access via: Theme.of(context).extension&lt;AwakenTypography&gt;()!
///
/// Fonts: Space Grotesk (body) + Space Mono (HUD numerics).
/// Swap to GoogleFonts.geist / GoogleFonts.geistMono when Geist lands on
/// Google Fonts, or bundle them locally via pubspec flutter.fonts.
@immutable
class AwakenTypography extends ThemeExtension<AwakenTypography> {
  const AwakenTypography({
    required this.hudClock,
    required this.hudRepCounter,
    required this.hudRepFraction,
    required this.eyebrow,
    required this.statValue,
    required this.statLabel,
  });

  /// Digital clock — 80px SpaceMono bold, tabular, tight tracking
  final TextStyle hudClock;

  /// Rep counter — 72px SpaceMono bold, tabular (e.g. "0 / 10")
  final TextStyle hudRepCounter;

  /// Smaller fraction inside the rep counter (the "/ 10" part)
  final TextStyle hudRepFraction;

  /// ALL-CAPS label eyebrow — 11px SpaceGrotesk semibold, wide tracking
  final TextStyle eyebrow;

  /// Large stat number on dashboard/success cards
  final TextStyle statValue;

  /// Small label under a stat number
  final TextStyle statLabel;

  @override
  AwakenTypography copyWith({
    TextStyle? hudClock,
    TextStyle? hudRepCounter,
    TextStyle? hudRepFraction,
    TextStyle? eyebrow,
    TextStyle? statValue,
    TextStyle? statLabel,
  }) {
    return AwakenTypography(
      hudClock: hudClock ?? this.hudClock,
      hudRepCounter: hudRepCounter ?? this.hudRepCounter,
      hudRepFraction: hudRepFraction ?? this.hudRepFraction,
      eyebrow: eyebrow ?? this.eyebrow,
      statValue: statValue ?? this.statValue,
      statLabel: statLabel ?? this.statLabel,
    );
  }

  @override
  AwakenTypography lerp(AwakenTypography? other, double t) {
    if (other is! AwakenTypography) return this;
    return AwakenTypography(
      hudClock: TextStyle.lerp(hudClock, other.hudClock, t)!,
      hudRepCounter: TextStyle.lerp(hudRepCounter, other.hudRepCounter, t)!,
      hudRepFraction: TextStyle.lerp(hudRepFraction, other.hudRepFraction, t)!,
      eyebrow: TextStyle.lerp(eyebrow, other.eyebrow, t)!,
      statValue: TextStyle.lerp(statValue, other.statValue, t)!,
      statLabel: TextStyle.lerp(statLabel, other.statLabel, t)!,
    );
  }
}

abstract final class AppTypography {
  // ── Helpers ──────────────────────────────────────────────────────
  static TextStyle _mono({
    required double size,
    required FontWeight weight,
    required Color color,
    double letterSpacing = 0,
    double? height,
  }) =>
      GoogleFonts.spaceMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle _sans({
    required double size,
    required FontWeight weight,
    required Color color,
    double letterSpacing = 0,
    double? height,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: FontWeight.values.firstWhere(
          (w) => w == weight,
          orElse: () => FontWeight.w400,
        ),
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  // ── Material TextTheme ────────────────────────────────────────────
  static TextTheme get textTheme => TextTheme(
        // Display — GeistMono-equivalent HUD numerics
        displayLarge: _mono(
          size: 80,
          weight: FontWeight.w700,
          color: AppColors.foreground,
          letterSpacing: -2,
        ),
        displayMedium: _mono(
          size: 56,
          weight: FontWeight.w700,
          color: AppColors.foreground,
          letterSpacing: -1.5,
        ),
        displaySmall: _mono(
          size: 36,
          weight: FontWeight.w700,
          color: AppColors.foreground,
          letterSpacing: -0.5,
        ),

        // Headlines — Geist-equivalent sans
        headlineLarge: _sans(
          size: 32,
          weight: FontWeight.w700,
          color: AppColors.foreground,
          height: 1.2,
        ),
        headlineMedium: _sans(
          size: 24,
          weight: FontWeight.w700,
          color: AppColors.foreground,
          height: 1.25,
        ),
        headlineSmall: _sans(
          size: 20,
          weight: FontWeight.w600,
          color: AppColors.foreground,
          height: 1.3,
        ),

        // Titles
        titleLarge: _sans(
          size: 18,
          weight: FontWeight.w600,
          color: AppColors.foreground,
          height: 1.35,
        ),
        titleMedium: _sans(
          size: 16,
          weight: FontWeight.w500,
          color: AppColors.foreground,
          height: 1.4,
        ),
        titleSmall: _sans(
          size: 14,
          weight: FontWeight.w500,
          color: AppColors.mutedForeground,
          height: 1.4,
        ),

        // Body
        bodyLarge: _sans(
          size: 16,
          weight: FontWeight.w400,
          color: AppColors.foreground,
          height: 1.6,
        ),
        bodyMedium: _sans(
          size: 14,
          weight: FontWeight.w400,
          color: AppColors.foreground,
          height: 1.6,
        ),
        bodySmall: _sans(
          size: 12,
          weight: FontWeight.w400,
          color: AppColors.mutedForeground,
          height: 1.5,
        ),

        // Labels / eyebrow chips
        labelLarge: _sans(
          size: 12,
          weight: FontWeight.w600,
          color: AppColors.mutedForeground,
          letterSpacing: 2.5,
          height: 1,
        ),
        labelMedium: _sans(
          size: 11,
          weight: FontWeight.w600,
          color: AppColors.mutedForeground,
          letterSpacing: 2,
          height: 1,
        ),
        labelSmall: _sans(
          size: 10,
          weight: FontWeight.w600,
          color: AppColors.mutedForeground,
          letterSpacing: 1.5,
          height: 1,
        ),
      );

  /// AwakenTypography ThemeExtension — injected in app.dart into ThemeData.
  static AwakenTypography get extension => AwakenTypography(
        hudClock: _mono(
          size: 80,
          weight: FontWeight.w700,
          color: AppColors.foreground,
          letterSpacing: -2,
        ),
        hudRepCounter: _mono(
          size: 72,
          weight: FontWeight.w700,
          color: AppColors.foreground,
          letterSpacing: -1,
        ),
        hudRepFraction: _mono(
          size: 36,
          weight: FontWeight.w400,
          color: AppColors.mutedForeground,
          letterSpacing: -0.5,
        ),
        eyebrow: _sans(
          size: 11,
          weight: FontWeight.w600,
          color: AppColors.mutedForeground,
          letterSpacing: 3,
          height: 1,
        ),
        statValue: _mono(
          size: 28,
          weight: FontWeight.w700,
          color: AppColors.foreground,
          letterSpacing: -0.5,
        ),
        statLabel: _sans(
          size: 11,
          weight: FontWeight.w500,
          color: AppColors.mutedForeground,
          letterSpacing: 1.5,
          height: 1,
        ),
      );
}
