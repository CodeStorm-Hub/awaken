import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/constants/iap_config.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/hud_theme.dart';
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
                onPressed: () async {
                  final ok =
                      await ref.read(isProEntitledProvider.notifier).purchasePro();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? (kDebugMode
                                ? 'Pro unlocked (debug / store)'
                                : 'Opening store…')
                            : 'Store unavailable — configure ${IapConfig.productMonthly}',
                      ),
                    ),
                  );
                },
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
                onTap: unlocked.contains(id)
                    ? () => ref
                        .read(selectedHudThemeIdProvider.notifier)
                        .select(id)
                    : IapConfig.proHudThemes.contains(id.name) && !isPro
                        ? () async {
                            await ref
                                .read(isProEntitledProvider.notifier)
                                .purchasePro();
                          }
                        : null,
              ),
          ],
        ),
      ],
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = HudTheme.forId(id);
    return Opacity(
      opacity: unlocked ? 1 : 0.35,
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
                  unlocked
                      ? id.label.toUpperCase()
                      : IapConfig.proHudThemes.contains(id.name)
                          ? 'PRO'
                          : 'STR ${id.requiredStreak}',
                  style: TextStyle(
                    color: selected ? theme.primary : AppColors.foreground,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
