import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';
import 'package:flutter/material.dart';

/// Visual recipe for one territory on the dark run map.
///
/// Each profile owns a unique [TerritoryEntity.mapColorHex] assigned in
/// Supabase on signup (`profiles.territory_color`). Fill/stroke always come
/// from that color — owned land is only emphasized with stronger alpha /
/// stroke, never by forcing a shared teal that would collide with rivals.
class TerritoryPaintStyle {
  const TerritoryPaintStyle({
    required this.fill,
    required this.stroke,
    required this.glow,
    required this.fillAlpha,
    required this.strokeWidth,
    required this.glowWidth,
  });

  final Color fill;
  final Color stroke;
  final Color glow;
  final double fillAlpha;
  final double strokeWidth;
  final double glowWidth;

  static TerritoryPaintStyle forTerritory(TerritoryEntity territory) {
    final ink = colorFromHex(territory.mapColorHex);
    if (territory.isOwnedByCurrentUser) {
      return TerritoryPaintStyle(
        fill: ink,
        stroke: ink,
        glow: ink.withValues(alpha: 0.42),
        fillAlpha: 0.32,
        strokeWidth: 2.8,
        glowWidth: 14,
      );
    }
    return TerritoryPaintStyle(
      fill: ink,
      stroke: ink,
      glow: ink.withValues(alpha: 0.36),
      fillAlpha: 0.22,
      strokeWidth: 2.2,
      glowWidth: 11,
    );
  }

  /// Parses `#rgb` / `#rrggbb` (case-insensitive). Falls back to slate if bad.
  static Color colorFromHex(String raw) {
    var hex = raw.trim().toLowerCase();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 3) {
      hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
    }
    if (hex.length != 6) return AppColors.mutedForeground;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return AppColors.mutedForeground;
    return Color(0xFF000000 | value);
  }
}
