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
    if (!ref.watch(territoryMapReadyProvider)) {
      return const SizedBox.shrink();
    }

    final styleAsync = ref.watch(territoryMapStyleProvider);
    final territoriesAsync = ref.watch(territoryListProvider);

    final styleError = styleAsync.hasError ? styleAsync.error : null;
    final territoriesError = territoriesAsync.hasError ? territoriesAsync.error : null;
    final error = styleError ?? territoriesError;

    if (error == null) {
      final styleLoading = styleAsync.isLoading && !styleAsync.hasValue;
      if (!styleLoading) {
        return const SizedBox.shrink();
      }

      return const Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: 120),
          child: _MapLoadingChip(),
        ),
      );
    }

    final isTerritoryLoadFailure = styleError == null && territoriesError != null;

    return Center(
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
            Icon(
              isTerritoryLoadFailure
                  ? Icons.cloud_off_outlined
                  : Icons.map_outlined,
              color: AppColors.mutedForeground,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              isTerritoryLoadFailure
                  ? 'Territories couldn\'t load'
                  : 'Map couldn\'t load',
              style: const TextStyle(
                color: AppColors.foreground,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isTerritoryLoadFailure
                  ? 'Sign in or check your connection, then try again.'
                  : 'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {
                if (styleError != null) {
                  ref.invalidate(territoryMapStyleProvider);
                }
                if (territoriesError != null) {
                  ref.invalidate(territoryListProvider);
                }
              },
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
    );
  }
}

class _MapLoadingChip extends StatelessWidget {
  const _MapLoadingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppConstants.chipRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Loading map…',
            style: TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
