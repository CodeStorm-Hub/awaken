import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/constants/iap_config.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/core/theme/hud_theme.dart';
import 'package:awaken/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:awaken/features/dashboard/presentation/providers/hud_theme_providers.dart';
import 'package:awaken/features/dashboard/presentation/providers/iap_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

// Safe StateProvider for custom crop shape inside customization page
final activeAvatarShapeProvider = StateProvider<String>((ref) => 'decagon');

class CustomizationScreen extends ConsumerWidget {
  const CustomizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(unlockedHudThemesProvider);
    final selected = ref.watch(selectedHudThemeIdProvider);
    final isPro = ref.watch(isProEntitledProvider);
    final streak = ref.watch(dashboardStatsProvider).value?.currentStreak ?? 0;
    final activeShape = ref.watch(activeAvatarShapeProvider);
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
        title: Text('HUD SHOP', style: tt.eyebrow),
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
              // Theme Preview Card
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      HudTheme.forId(selected).primary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: HudTheme.forId(selected).primary.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: HudTheme.forId(selected).glow.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _AvatarFramePreview(shape: activeShape, activeColor: HudTheme.forId(selected).primary),
                      const SizedBox(width: 18),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTIVE HUD: ${selected.label.toUpperCase()}',
                            style: TextStyle(
                              color: HudTheme.forId(selected).primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ACCENT CUSTOMIZATION PREVIEW',
                            style: tt.eyebrow.copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 32),

              // Theme Swatches Group
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ACCENT UNLOCKS', style: tt.eyebrow),
                  if (!isPro)
                    TextButton(
                      onPressed: () => _unlockPro(context, ref),
                      child: const Text('UNLOCK PRO ACCESS'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final id in HudThemeId.values)
                      _ThemeSelectionCard(
                        id: id,
                        selected: selected == id,
                        unlocked: unlocked.contains(id),
                        onTap: () => _onThemeTap(
                          context,
                          ref,
                          id: id,
                          unlocked: unlocked.contains(id),
                          isPro: isPro,
                          streak: streak,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Shape Cutters Selection
              Text('AVATAR FRAME CROPS', style: tt.eyebrow),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ShapeCropItem(
                      shape: 'decagon',
                      isSelected: activeShape == 'decagon',
                      onTap: () => ref.read(activeAvatarShapeProvider.notifier).state = 'decagon',
                    ),
                    _ShapeCropItem(
                      shape: 'squircle',
                      isSelected: activeShape == 'squircle',
                      onTap: () => ref.read(activeAvatarShapeProvider.notifier).state = 'squircle',
                    ),
                    _ShapeCropItem(
                      shape: 'bevel',
                      isSelected: activeShape == 'bevel',
                      onTap: () => ref.read(activeAvatarShapeProvider.notifier).state = 'bevel',
                    ),
                    _ShapeCropItem(
                      shape: 'gear',
                      isSelected: activeShape == 'gear',
                      onTap: () => ref.read(activeAvatarShapeProvider.notifier).state = 'gear',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onThemeTap(
    BuildContext context,
    WidgetRef ref, {
    required HudThemeId id,
    required bool unlocked,
    required bool isPro,
    required int streak,
  }) async {
    if (unlocked) {
      await ref.read(selectedHudThemeIdProvider.notifier).select(id);
      return;
    }

    if (kDebugMode) {
      await ref.read(selectedHudThemeIdProvider.notifier).selectPreview(id);
      return;
    }

    final needsPro = IapConfig.proHudThemes.contains(id.name);
    if (needsPro && !isPro) {
      await _unlockPro(context, ref);
      return;
    }

    final parts = <String>[
      if (streak < id.requiredStreak)
        'Streak of ${id.requiredStreak} required',
      if (needsPro && !isPro) 'Requires Pro',
    ];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          parts.isEmpty
              ? '${id.label} is locked'
              : '${id.label}: ${parts.join(' · ')}',
        ),
      ),
    );
  }

  Future<void> _unlockPro(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(isProEntitledProvider.notifier).purchasePro();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Purchase started' : 'Purchase unavailable'),
      ),
    );
  }
}

class _ThemeSelectionCard extends StatelessWidget {
  const _ThemeSelectionCard({
    required this.id,
    required this.selected,
    required this.unlocked,
    required this.onTap,
  });

  final HudThemeId id;
  final bool selected;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = HudTheme.forId(id);
    final needsPro = IapConfig.proHudThemes.contains(id.name);
    return Opacity(
      opacity: unlocked ? 1.0 : 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: selected ? 0.15 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? theme.primary : AppColors.border,
              width: selected ? 1.5 : 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: theme.glow, blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                id.label.toUpperCase(),
                style: TextStyle(
                  color: selected ? theme.primary : AppColors.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (!unlocked)
                Text(
                  needsPro ? 'PRO ACCESS' : 'STREAK ${id.requiredStreak}',
                  style: TextStyle(
                    color: theme.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarFramePreview extends StatelessWidget {
  const _AvatarFramePreview({
    required this.shape,
    required this.activeColor,
  });

  final String shape;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.1),
        shape: shape == 'squircle' ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: shape == 'squircle' ? BorderRadius.circular(16) : null,
        border: Border.all(color: activeColor, width: 1.5),
      ),
      child: Center(
        child: Icon(Icons.person_rounded, color: activeColor, size: 24),
      ),
    );
  }
}

class _ShapeCropItem extends StatelessWidget {
  const _ShapeCropItem({
    required this.shape,
    required this.isSelected,
    required this.onTap,
  });

  final String shape;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.secondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Center(
          child: Text(
            shape.substring(0, 3).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.primary : AppColors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}
