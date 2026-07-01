import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:awaken/features/territory/presentation/screens/territory_leaderboard_screen.dart';
import 'package:awaken/features/territory/presentation/screens/territory_run_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides [currentShellTabProvider] to allow sub-screens or the router to
/// read/change the active shell tab programmatically.
final currentShellTabProvider = StateProvider<int>((ref) => 0);

/// Top-level shell: keeps all three main screens alive via IndexedStack
/// so state (map tiles, scroll positions) is preserved on tab switch.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const List<Widget> _screens = [
    DashboardScreen(),
    TerritoryRunScreen(),
    TerritoryLeaderboardScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentShellTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _AwakenBottomNav(
        currentIndex: currentIndex,
        onTap: (i) => ref.read(currentShellTabProvider.notifier).state = i,
      ),
    );
  }
}

class _AwakenBottomNav extends StatelessWidget {
  const _AwakenBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'HOME',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.map_rounded,
                label: 'TERRITORY',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
                accentColor: AppColors.accent,
              ),
              _NavItem(
                icon: Icons.leaderboard_rounded,
                label: 'RANKS',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? (accentColor ?? AppColors.primary)
        : AppColors.mutedForeground;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? (accentColor ?? AppColors.primary).withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
