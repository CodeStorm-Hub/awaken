import 'package:flutter/material.dart';

/// All color tokens for Awaken, mapped from the OKLCH design system.
/// Never use raw hex values outside this file — always reference these constants.
abstract final class AppColors {
  // ── Surfaces ──────────────────────────────────────────────────────
  /// oklch(0 0 0) — absolute black app canvas
  static const Color background = Color(0xFF000000);

  /// oklch(0.16 0 0) — deep-grey raised cards/surfaces
  static const Color card = Color(0xFF282828);

  /// oklch(0.22 0 0) — chips, inactive tab backgrounds
  static const Color secondary = Color(0xFF383838);

  /// oklch(0.20 0 0) — subtle fills, muted containers
  static const Color muted = Color(0xFF333333);

  // ── Text ──────────────────────────────────────────────────────────
  /// oklch(0.985 0 0) — primary text, near-white
  static const Color foreground = Color(0xFFFAFAFA);

  /// oklch(0.62 0 0) — secondary labels, eyebrows
  static const Color mutedForeground = Color(0xFF9E9E9E);

  // ── Brand accents ─────────────────────────────────────────────────
  /// oklch(0.68 0.18 247) — electric blue, core structural accent
  static const Color primary = Color(0xFF4A9EFF);

  /// oklch(0.62 0.22 295) — electric purple, gamified HUD markers
  static const Color accent = Color(0xFFA259FF);

  // ── Functional feedback ───────────────────────────────────────────
  /// oklch(0.72 0.20 150) — perfect-rep / streak-up green
  static const Color success = Color(0xFF34D399);

  /// oklch(0.62 0.24 25) — bad-form / failure red
  static const Color destructive = Color(0xFFF87171);

  // ── Structural ────────────────────────────────────────────────────
  /// oklch(1 0 0 / 10%) — hairline separators
  static const Color border = Color(0x1AFFFFFF);

  // ── Rank medals (leaderboard podium) ──────────────────────────────
  static const Color medalGold = Color(0xFFE8C547);
  static const Color medalSilver = Color(0xFFB8C0CC);
  static const Color medalBronze = Color(0xFFC47A3A);

  // ── Glow variants (for CustomPainter BlurMaskFilter) ─────────────
  static const Color primaryGlow = Color(0x664A9EFF);
  static const Color accentGlow = Color(0x66A259FF);
  static const Color successGlow = Color(0x6634D399);
  static const Color destructiveGlow = Color(0x66F87171);
}
