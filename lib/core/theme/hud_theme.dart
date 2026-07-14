import 'package:flutter/material.dart';

/// Identifies which HUD colour theme is active.
enum HudThemeId {
  /// Default — electric cyan/blue. Available at streak 0.
  cyan,

  /// Magenta. Unlocked at streak ≥ 7.
  magenta,

  /// Acid green. Unlocked at streak ≥ 30.
  acid,

  /// Monochrome white. Unlocked at streak ≥ 90.
  mono,
}

extension HudThemeIdLabel on HudThemeId {
  String get label => switch (this) {
    HudThemeId.cyan => 'Cyan',
    HudThemeId.magenta => 'Magenta',
    HudThemeId.acid => 'Acid',
    HudThemeId.mono => 'Mono',
  };

  int get requiredStreak => switch (this) {
    HudThemeId.cyan => 0,
    HudThemeId.magenta => 7,
    HudThemeId.acid => 30,
    HudThemeId.mono => 90,
  };
}

/// Per-theme colour tokens applied to the active alarm HUD and territory map
/// accents. Injected as a [ThemeExtension] via [MaterialApp.darkTheme].
class HudTheme extends ThemeExtension<HudTheme> {
  const HudTheme({
    required this.id,
    required this.primary,
    required this.glow,
    required this.scanline,
  });

  final HudThemeId id;

  /// Primary accent colour (border rings, progress indicators).
  final Color primary;

  /// Glow colour (semi-transparent, used for BlurMaskFilter / shadows).
  final Color glow;

  /// Scanline colour on the active alarm overlay.
  final Color scanline;

  // ── Preset definitions ───────────────────────────────────────────────────

  static const cyan = HudTheme(
    id: HudThemeId.cyan,
    primary: Color(0xFF4A9EFF),
    glow: Color(0x664A9EFF),
    scanline: Color(0x1A4A9EFF),
  );

  static const magenta = HudTheme(
    id: HudThemeId.magenta,
    primary: Color(0xFFE040FB),
    glow: Color(0x66E040FB),
    scanline: Color(0x1AE040FB),
  );

  static const acid = HudTheme(
    id: HudThemeId.acid,
    primary: Color(0xFF76FF03),
    glow: Color(0x6676FF03),
    scanline: Color(0x1A76FF03),
  );

  static const mono = HudTheme(
    id: HudThemeId.mono,
    primary: Color(0xFFFAFAFA),
    glow: Color(0x66FAFAFA),
    scanline: Color(0x1AFAFAFA),
  );

  static HudTheme forId(HudThemeId id) => switch (id) {
    HudThemeId.cyan => cyan,
    HudThemeId.magenta => magenta,
    HudThemeId.acid => acid,
    HudThemeId.mono => mono,
  };

  // ── ThemeExtension boilerplate ───────────────────────────────────────────

  @override
  HudTheme copyWith({
    HudThemeId? id,
    Color? primary,
    Color? glow,
    Color? scanline,
  }) {
    return HudTheme(
      id: id ?? this.id,
      primary: primary ?? this.primary,
      glow: glow ?? this.glow,
      scanline: scanline ?? this.scanline,
    );
  }

  @override
  HudTheme lerp(HudTheme? other, double t) {
    if (other == null) return this;
    return HudTheme(
      id: t < 0.5 ? id : other.id,
      primary: Color.lerp(primary, other.primary, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      scanline: Color.lerp(scanline, other.scanline, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HudTheme &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          primary == other.primary &&
          glow == other.glow &&
          scanline == other.scanline;

  @override
  int get hashCode => Object.hash(id, primary, glow, scanline);
}
