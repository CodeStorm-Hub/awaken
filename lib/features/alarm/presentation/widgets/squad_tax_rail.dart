import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/alarm/domain/entities/squad_mate_progress.dart';
import 'package:flutter/material.dart';

/// Right-side rail shown during an active alarm when the current user is in a
/// squad. Displays up to 3 squad mate avatars with progress bars.
///
/// The rail is translucent so it doesn't obscure the camera preview.
class SquadTaxRail extends StatelessWidget {
  const SquadTaxRail({super.key, required this.mates});

  /// At most 3 squad mates — the provider caps the list.
  final List<SquadMateProgress> mates;

  @override
  Widget build(BuildContext context) {
    if (mates.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final mate in mates) ...[
          _MateProgress(mate: mate),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MateProgress extends StatelessWidget {
  const _MateProgress({required this.mate});

  final SquadMateProgress mate;

  static const _magenta = Color(0xFFE040FB);
  static const _magentaGlow = Color(0x44E040FB);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    final initials = mate.displayName.isNotEmpty
        ? mate.displayName.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _magenta.withValues(alpha: 0.4),
        ),
        boxShadow: const [
          BoxShadow(
            color: _magentaGlow,
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Avatar ───────────────────────────────────────────────
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _magenta.withValues(alpha: 0.2),
              border: Border.all(
                color: mate.isComplete ? AppColors.success : _magenta,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: mate.isComplete
                ? const Icon(Icons.check, color: AppColors.success, size: 14)
                : Text(
                    initials,
                    style: tt.statLabel.copyWith(
                      fontSize: 11,
                      color: _magenta,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          // ── Progress bar (vertical) ──────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              width: 6,
              height: 40,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    color: AppColors.muted.withValues(alpha: 0.5),
                  ),
                  FractionallySizedBox(
                    heightFactor: mate.progress,
                    child: Container(color: _magenta),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // ── Rep count ────────────────────────────────────────────
          Text(
            '${mate.repCount}',
            style: tt.statLabel.copyWith(
              fontSize: 9,
              color: mate.isComplete ? AppColors.success : AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
