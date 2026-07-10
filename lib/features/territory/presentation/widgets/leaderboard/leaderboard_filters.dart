import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:flutter/material.dart';

class LeaderboardScopeToggle extends StatelessWidget {
  const LeaderboardScopeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final LeaderboardMode mode;
  final ValueChanged<LeaderboardMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final m in LeaderboardMode.values)
            Expanded(
              child: _SegChip(
                label: m == LeaderboardMode.nearby ? 'Nearby' : 'Global',
                selected: m == mode,
                selectedColor: AppColors.primary,
                selectedForeground: Colors.black,
                onTap: () => onChanged(m),
              ),
            ),
        ],
      ),
    );
  }
}

class LeaderboardWindowChips extends StatelessWidget {
  const LeaderboardWindowChips({
    super.key,
    required this.window,
    required this.onChanged,
  });

  final LeaderboardWindow window;
  final ValueChanged<LeaderboardWindow> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final w in LeaderboardWindow.values) ...[
          if (w != LeaderboardWindow.values.first) const SizedBox(width: 8),
          Expanded(
            child: _SegChip(
              label: switch (w) {
                LeaderboardWindow.day => '24H',
                LeaderboardWindow.week => '7D',
                LeaderboardWindow.allTime => 'ALL',
              },
              selected: w == window,
              selectedColor: AppColors.accent,
              selectedForeground: AppColors.foreground,
              dense: true,
              onTap: () => onChanged(w),
            ),
          ),
        ],
      ],
    );
  }
}

class LeaderboardMetricBadge extends StatelessWidget {
  const LeaderboardMetricBadge({
    super.key,
    required this.window,
    required this.mode,
  });

  final LeaderboardWindow window;
  final LeaderboardMode mode;

  @override
  Widget build(BuildContext context) {
    final isOwned = window == LeaderboardWindow.allTime;
    final label = isOwned ? 'LAND OWNED' : 'UNIQUE AREA CLAIMED';
    final detail = switch (window) {
      LeaderboardWindow.allTime => mode == LeaderboardMode.nearby
          ? 'Current territory near you'
          : 'Current territory worldwide',
      LeaderboardWindow.day => 'Distinct land claimed in the last 24 hours',
      LeaderboardWindow.week => 'Distinct land claimed in the last 7 days',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isOwned ? AppColors.primary : AppColors.accent)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOwned ? Icons.public_rounded : Icons.bolt_rounded,
            size: 16,
            color: isOwned ? AppColors.primary : AppColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isOwned ? AppColors.primary : AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegChip extends StatelessWidget {
  const _SegChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.selectedForeground,
    required this.onTap,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final Color selectedForeground;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.shortAnim,
        padding: EdgeInsets.symmetric(vertical: dense ? 9 : 11),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: dense ? 0.22 : 1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: dense && selected
              ? Border.all(color: selectedColor.withValues(alpha: 0.55))
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? (dense ? selectedColor : selectedForeground)
                : AppColors.mutedForeground,
            fontWeight: FontWeight.w700,
            fontSize: dense ? 12 : 13,
            letterSpacing: dense ? 0.6 : 0.2,
          ),
        ),
      ),
    );
  }
}
