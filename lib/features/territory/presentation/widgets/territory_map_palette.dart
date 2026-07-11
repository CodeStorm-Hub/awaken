import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';
import 'package:flutter/material.dart';

/// Visual recipe for one territory on the dark run map.
///
/// Cartography notes (Mapbox Dark / Stamen dark-map guidance + territory
/// games like TerraRun): keep the basemap quiet, give overlays saturated
/// strokes with translucent fills, and use glow borders so shapes read at
/// night without burying street labels.
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

  /// Resolves owned vs rival styling. Rivals get a stable hue from
  /// [AppColors.territoryRivalPalette] so neighboring players stay
  /// distinguishable without a legend of identical red blobs.
  static TerritoryPaintStyle forTerritory(TerritoryEntity territory) {
    if (territory.isOwnedByCurrentUser) {
      return const TerritoryPaintStyle(
        fill: AppColors.territoryOwned,
        stroke: AppColors.territoryOwned,
        glow: AppColors.territoryOwnedGlow,
        fillAlpha: 0.30,
        strokeWidth: 2.8,
        glowWidth: 14,
      );
    }

    final ink = rivalColorForUserId(territory.userId);
    return TerritoryPaintStyle(
      fill: ink,
      stroke: ink,
      glow: ink.withValues(alpha: 0.38),
      fillAlpha: 0.22,
      strokeWidth: 2.2,
      glowWidth: 11,
    );
  }

  static Color rivalColorForUserId(String userId) {
    const palette = AppColors.territoryRivalPalette;
    var hash = 0;
    for (final unit in userId.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }
}
