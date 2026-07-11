import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/territory/domain/entities/decay_warning_entity.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Personal ownership dashboard: total owned area, polygon count, and a
/// decay-risk list — the destination for the "view details" affordance on
/// the dashboard's territory card and the run screen's overview button.
///
/// Reached as an overlay route (`/territory/overview`), not a bottom-nav
/// tab: it's a secondary, occasional-use surface, and the shell only has
/// room for the three primary destinations (Home / Territory / Ranks).
class TerritoryOverviewScreen extends ConsumerWidget {
  const TerritoryOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hud = Theme.of(context).extension<AwakenTypography>()!;
    final territoriesAsync = ref.watch(territoryListProvider);
    final decayWarningsAsync = ref.watch(decayWarningsProvider);
    final fogEnabled = ref.watch(fogOfWarEnabledProvider);
    ref.watch(exploredCellsVersionProvider);
    final store = ref.watch(exploredCellsStoreProvider);
    final exploredEmpty = store.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('MY TERRITORY', style: hud.eyebrow),
        centerTitle: true,
        actions: [
          // Fog-of-war toggle
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton(
              onPressed: () {
                ref.read(fogOfWarEnabledProvider.notifier).state = !fogEnabled;
              },
              style: TextButton.styleFrom(
                foregroundColor:
                    fogEnabled ? AppColors.primary : AppColors.mutedForeground,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                fogEnabled ? 'FOG ON' : 'FOG OFF',
                style: hud.eyebrow.copyWith(
                  fontSize: 10,
                  color: fogEnabled
                      ? AppColors.primary
                      : AppColors.mutedForeground,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.mutedForeground, size: 20),
            onPressed: () {
              ref.invalidate(territoryListProvider);
              ref.invalidate(decayWarningsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        onRefresh: () async {
          ref.invalidate(territoryListProvider);
          ref.invalidate(decayWarningsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPaddingH,
            vertical: 16,
          ),
          children: [
            territoriesAsync.when(
              data: (territories) => _OwnershipStats(territories: territories),
              loading: () => const _CardSkeleton(height: 110),
              error: (_, _) => const _LoadErrorCard(
                message: 'Could not load your territory.',
              ),
            ),
            const SizedBox(height: 24),
            // ── Fog empty-state hint ───────────────────────────────────
            if (fogEnabled && exploredEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Run to chart the grid.',
                          style: hud.statLabel.copyWith(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Text('DECAY RISK', style: hud.eyebrow),
            const SizedBox(height: 4),
            const Text(
              'Territory left undefended for 7 days starts shrinking. Run '
              'through it again to reset the clock.',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            decayWarningsAsync.when(
              data: (warnings) => _DecayRiskList(warnings: warnings),
              loading: () => const _CardSkeleton(height: 72),
              error: (_, _) => const _LoadErrorCard(
                message: 'Could not load decay warnings.',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Ownership stats ──────────────────────────────────────────────────────────

class _OwnershipStats extends StatelessWidget {
  const _OwnershipStats({required this.territories});

  final List<TerritoryEntity> territories;

  @override
  Widget build(BuildContext context) {
    final hud = Theme.of(context).extension<AwakenTypography>()!;
    final owned = territories.where((t) => t.isOwnedByCurrentUser).toList();
    final totalAreaSqMeters =
        owned.fold<double>(0, (sum, t) => sum + t.areaSqMeters);
    final polygonCount = owned.fold<int>(0, (sum, t) => sum + t.polygons.length);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              label: 'Total owned',
              value: '${(totalAreaSqMeters / 1_000_000).toStringAsFixed(3)} km²',
              hud: hud,
              valueColor: AppColors.primary,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: _StatColumn(
              label: 'Territories',
              value: '$polygonCount',
              hud: hud,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.hud,
    this.valueColor,
  });

  final String label;
  final String value;
  final AwakenTypography hud;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            label.toUpperCase(),
            style: hud.statLabel.copyWith(
              color: AppColors.mutedForeground,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            value,
            style: hud.statValue.copyWith(fontSize: 22, color: valueColor),
          ),
        ),
      ],
    );
  }
}

// ── Decay risk list ───────────────────────────────────────────────────────────

class _DecayRiskList extends StatelessWidget {
  const _DecayRiskList({required this.warnings});

  final List<DecayWarningEntity> warnings;

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.shield_rounded, color: AppColors.success, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'All your territory is defended. Nothing at risk.',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final sorted = [...warnings]
      ..sort((a, b) => a.daysUntilDecay.compareTo(b.daysUntilDecay));

    return Column(
      children: sorted
          .map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DecayRiskTile(warning: w),
            ),
          )
          .toList(),
    );
  }
}

class _DecayRiskTile extends StatelessWidget {
  const _DecayRiskTile({required this.warning});

  final DecayWarningEntity warning;

  @override
  Widget build(BuildContext context) {
    final hud = Theme.of(context).extension<AwakenTypography>()!;
    final urgent = warning.daysUntilDecay <= 2;
    final color = urgent ? AppColors.destructive : AppColors.accent;
    final days = warning.daysUntilDecay.ceil().clamp(0, 999);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            urgent ? Icons.warning_amber_rounded : Icons.hourglass_bottom_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(warning.areaSqMeters / 1_000_000).toStringAsFixed(3)} km² territory',
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  days <= 0
                      ? 'Decaying now'
                      : days == 1
                          ? 'Decays in 1 day'
                          : 'Decays in $days days',
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            'Run through',
            style: hud.statLabel.copyWith(
              color: AppColors.mutedForeground,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared loading/error states ──────────────────────────────────────────────

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2,
      ),
    );
  }
}

class _LoadErrorCard extends StatelessWidget {
  const _LoadErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
      ),
    );
  }
}
