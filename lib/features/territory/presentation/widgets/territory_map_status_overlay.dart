import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Surfaces map-style/tile-source load failures over the map, with a retry
/// action. Renders nothing while loading or once the style has resolved —
/// the vector basemap itself has no equivalent per-tile failure UI since a
/// handful of missing tiles degrade gracefully (blank/background-colored
/// squares), but a total style/tile-source resolution failure (e.g. no
/// network on first launch, OpenFreeMap outage) would otherwise leave the
/// map silently blank forever.
class TerritoryMapStatusOverlay extends ConsumerWidget {
  const TerritoryMapStatusOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styleAsync = ref.watch(territoryMapStyleProvider);

    return styleAsync.when(
      data: (_) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.map_outlined,
                color: AppColors.mutedForeground,
                size: 32,
              ),
              const SizedBox(height: 12),
              const Text(
                'Map couldn\'t load',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => ref.invalidate(territoryMapStyleProvider),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.chipRadius),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
