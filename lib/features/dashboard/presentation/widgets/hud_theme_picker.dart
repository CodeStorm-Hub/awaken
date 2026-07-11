import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/constants/iap_config.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/hud_theme.dart';
import 'package:awaken/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:awaken/features/dashboard/presentation/providers/hud_theme_providers.dart';
import 'package:awaken/features/dashboard/presentation/providers/iap_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compact streak-unlock HUD theme chips for the dashboard.
class HudThemePicker extends ConsumerWidget {
  const HudThemePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(unlockedHudThemesProvider);
    final selected = ref.watch(selectedHudThemeIdProvider);
    final isPro = ref.watch(isProEntitledProvider);
    final streak =
        ref.watch(dashboardStatsProvider).valueOrNull?.currentStreak ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'HUD THEME',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            if (!isPro)
              TextButton(
                onPressed: () => _unlockPro(context, ref),
                child: const Text(
                  'UNLOCK PRO',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final id in HudThemeId.values)
              _ThemeChip(
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
      ],
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

    // Debug: preview any theme so HUD cosmetics can be dogfooded at streak 0.
    if (kDebugMode) {
      await ref.read(selectedHudThemeIdProvider.notifier).selectPreview(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${id.label} preview (debug) — unlocks at streak ${id.requiredStreak}'
            '${IapConfig.proHudThemes.contains(id.name) ? ' + Pro' : ''}',
          ),
        ),
      );
      return;
    }

    final needsPro = IapConfig.proHudThemes.contains(id.name);
    if (needsPro && !isPro) {
      await _unlockPro(context, ref);
      return;
    }

    if (!context.mounted) return;
    final parts = <String>[
      if (streak < id.requiredStreak)
        'Need a ${id.requiredStreak}-day streak (you have $streak)',
      if (needsPro && !isPro) 'Requires Awaken Pro',
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
        content: Text(
          ok
              ? (kDebugMode
                  ? 'Pro unlocked — Acid/Mono still need streak 30/90'
                  : 'Opening store…')
              : 'Store unavailable — configure ${IapConfig.productMonthly}',
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
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
      opacity: unlocked ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.chipRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: selected ? 0.22 : 0.08),
              borderRadius: BorderRadius.circular(AppConstants.chipRadius),
              border: Border.all(
                color: selected ? theme.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: theme.glow, blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  id.label.toUpperCase(),
                  style: TextStyle(
                    color: selected ? theme.primary : AppColors.foreground,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                if (!unlocked) ...[
                  const SizedBox(width: 4),
                  Text(
                    needsPro ? 'PRO' : 'STR${id.requiredStreak}',
                    style: TextStyle(
                      color: theme.primary.withValues(alpha: 0.85),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
