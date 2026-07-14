import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/core/theme/hud_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Single source of truth for Awaken's ThemeData.
/// Dark mode only — no light theme exists, no toggle, no system override.
abstract final class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,

      // ── Color scheme ───────────────────────────────────────────────
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.background,
        primaryContainer: AppColors.card,
        onPrimaryContainer: AppColors.foreground,
        secondary: AppColors.accent,
        onSecondary: AppColors.background,
        secondaryContainer: AppColors.secondary,
        onSecondaryContainer: AppColors.foreground,
        tertiary: AppColors.success,
        onTertiary: AppColors.background,
        surface: AppColors.card,
        onSurface: AppColors.foreground,
        surfaceContainerHighest: AppColors.secondary,
        onSurfaceVariant: AppColors.mutedForeground,
        error: AppColors.destructive,
        onError: AppColors.foreground,
        outline: AppColors.border,
        outlineVariant: AppColors.muted,
      ),

      // ── Typography ─────────────────────────────────────────────────
      textTheme: AppTypography.textTheme,

      // ── Card ───────────────────────────────────────────────────────
      cardTheme: const CardThemeData(
        color: AppColors.card,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── AppBar ─────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      // ── Elevated button ────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.secondary,
          disabledForegroundColor: AppColors.mutedForeground,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(56),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ── Text button ────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),

      // ── Outlined button ────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size.fromHeight(56),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),

      // ── Icon ───────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: AppColors.foreground, size: 20),

      // ── Divider ────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),

      // ── SnackBar ───────────────────────────────────────────────────
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ── Chip ───────────────────────────────────────────────────────
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.secondary,
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Dialog ─────────────────────────────────────────────────────
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: AppColors.border),
        ),
      ),

      // ── Page transitions — GPU-composited, platform-native feel ────
      // PredictiveBackPageTransitionsBuilder: Android 14+ gesture swipe-back
      // CupertinoPageTransitionsBuilder: iOS-native slide transition
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      extensions: <ThemeExtension<dynamic>>[
        AppTypography.extension,
        // Default HUD theme (cyan). AwakenApp overrides this at runtime when the
        // user has selected a different unlocked theme.
        HudTheme.cyan,
      ],
    );
  }
}
