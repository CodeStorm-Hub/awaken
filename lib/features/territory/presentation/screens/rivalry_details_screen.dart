import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RivalryDetailsScreen extends ConsumerWidget {
  const RivalryDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nemesisAsync = ref.watch(nemesisProvider);
    final tt = Theme.of(context).extension<AwakenTypography>()!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('BATTLE LOGS', style: tt.eyebrow),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPaddingH,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nemesis details section
              nemesisAsync.when(
                data: (nemesis) {
                  if (nemesis == null) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                          topRight: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.flag_rounded, color: AppColors.mutedForeground, size: 36),
                          const SizedBox(height: 12),
                          Text(
                            'NO NEMESIS IDENTIFIED',
                            style: tt.eyebrow.copyWith(color: AppColors.mutedForeground),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Claim territory that overlaps with other runners to trigger rivalries and conflict.',
                            style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final total = nemesis.totalDisputedSqMeters;
                  final double myPct = total == 0 ? 0.5 : nemesis.myDisputedSqMeters / total;
                  final double rivalPct = total == 0 ? 0.5 : nemesis.rivalDisputedSqMeters / total;

                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      border: Border.all(color: AppColors.border, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.destructiveGlow.withValues(alpha: 0.15),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ACTIVE RIVALRY', style: tt.eyebrow.copyWith(color: AppColors.destructive)),
                            const Icon(Icons.local_fire_department_rounded, color: AppColors.destructive, size: 20),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          nemesis.rivalDisplayName.toUpperCase(),
                          style: tt.statValue.copyWith(color: AppColors.destructive, fontSize: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${nemesis.mutualStealCount} MUTUAL STEALS RECORDED',
                          style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('DISPUTED TURF METRIC', style: tt.statLabel.copyWith(fontSize: 9)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: (myPct * 100).round(),
                              child: Container(
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: (rivalPct * 100).round(),
                              child: Container(
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.destructive,
                                  borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('YOU: ${(nemesis.myDisputedSqMeters / 1000).toStringAsFixed(1)}k m²', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontFamily: 'SpaceMono')),
                            Text('THEM: ${(nemesis.rivalDisputedSqMeters / 1000).toStringAsFixed(1)}k m²', style: const TextStyle(fontSize: 10, color: AppColors.destructive, fontFamily: 'SpaceMono')),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 250.ms);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading nemesis details: $e')),
              ),

              const SizedBox(height: 32),

              // Conflict logs List
              Text('CONFLICT FEEDS', style: tt.eyebrow),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final String player = index == 0 ? 'You' : 'Rival';
                  final String action = index == 0 ? 'stole zone #452' : 'reclaimed zone #124';
                  final Color actionColor = index == 0 ? AppColors.primary : AppColors.destructive;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          index == 0 ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                          color: actionColor,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$player $action',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '2 hours ago',
                                style: TextStyle(color: AppColors.mutedForeground, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
