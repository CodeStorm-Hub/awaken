import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/services/google_auth_service.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on GoogleSignInCanceledException {
      // User dismissed the account picker — stay on profile, no error banner.
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final router = GoRouter.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        title: const Text(
          'SIGN OUT',
          style: TextStyle(
            color: AppColors.destructive,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out? Your local data will be safe, but you won\'t be able to sync alarms to the cloud.',
          style: TextStyle(color: AppColors.foreground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: AppColors.foreground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.chipRadius),
              ),
            ),
            child: const Text(
              'SIGN OUT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      HapticFeedback.mediumImpact();
      setState(() => _loading = true);
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) {
        setState(() => _loading = false);
        router.go(AppRoutes.dashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = ref.watch(isSignedInProvider);
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final stats = statsAsync.value;

    final tt = Theme.of(context).extension<AwakenTypography>()!;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 120,
          leading: GestureDetector(
            onTap: () => context.go(AppRoutes.dashboard),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.mutedForeground,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'BACK',
                    style: tt.eyebrow.copyWith(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenPaddingH,
              vertical: AppConstants.screenPaddingV,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Profile Identity Card ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(
                      AppConstants.cardRadius,
                    ),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      // Avatar Image/Silhouette
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.3),
                            border: Border.all(
                              color: isSignedIn
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 2.0,
                            ),
                            boxShadow: isSignedIn
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: ClipOval(
                            child:
                                (isSignedIn &&
                                    user?.avatarUrl != null &&
                                    user!.avatarUrl!.isNotEmpty)
                                ? Image.network(
                                    user.avatarUrl!,
                                    fit: BoxFit.cover,
                                    // Renders at ~96px — decode small instead
                                    // of at full source resolution.
                                    cacheWidth: 288,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.person_rounded,
                                              size: 48,
                                              color: AppColors.mutedForeground,
                                            ),
                                  )
                                : Icon(
                                    isSignedIn
                                        ? Icons.person_rounded
                                        : Icons.person_outline_rounded,
                                    size: 48,
                                    color: isSignedIn
                                        ? AppColors.primary
                                        : AppColors.mutedForeground,
                                  ),
                          ),
                        ),
                      ).animate().scale(
                        duration: 300.ms,
                        curve: Curves.easeOutBack,
                      ),
                      const SizedBox(height: 16),

                      // Display Name
                      Text(
                        isSignedIn
                            ? (user?.displayName ?? 'No Display Name')
                            : 'Guest User',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),

                      // Email / Connection Details
                      Text(
                        isSignedIn
                            ? (user?.email ?? '')
                            : 'Local offline profile',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedForeground,
                          fontFamily: isSignedIn ? 'SpaceMono' : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Status Pill Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isSignedIn ? AppColors.success : AppColors.muted)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                (isSignedIn
                                        ? AppColors.success
                                        : AppColors.border)
                                    .withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSignedIn
                                    ? AppColors.success
                                    : AppColors.mutedForeground,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isSignedIn
                                  ? 'CLOUD SYNCHRONIZED'
                                  : 'LOCAL STORAGE ONLY',
                              style: tt.eyebrow.copyWith(
                                color: isSignedIn
                                    ? AppColors.success
                                    : AppColors.mutedForeground,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Error Message Banner ───────────────────────────────────────
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.destructive.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        border: Border.all(
                          color: AppColors.destructive.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: AppColors.destructive.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // ── Google Sign-in Call-To-Action (Guest Mode Only) ────────────
                if (!isSignedIn) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(
                        AppConstants.cardRadius,
                      ),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'SECURE YOUR PROGRESS',
                          style: tt.eyebrow.copyWith(color: AppColors.primary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Connect a Google account to synchronize your alarms, preserve streaks, and join the global territory map leaderboard.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.mutedForeground,
                                height: 1.4,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        _loading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _signInWithGoogle,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.foreground,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.borderRadius,
                                    ),
                                  ),
                                  elevation: 4,
                                  shadowColor: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(
                                        Icons.g_mobiledata_rounded,
                                        color: Colors.black,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'CONNECT GOOGLE ACCOUNT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Performance Statistics Recap ──────────────────────────────
                Text('PERFORMANCE SUMMARY', style: tt.eyebrow),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 400;
                    return GridView.count(
                      crossAxisCount: isWide ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _StatItem(
                          title: 'STREAK',
                          value: stats != null ? '${stats.currentStreak}' : '0',
                          unit: 'days',
                          icon: Icons.local_fire_department_rounded,
                          iconColor: AppColors.accent,
                          tt: tt,
                        ),
                        _StatItem(
                          title: 'BEST STREAK',
                          value: stats != null ? '${stats.bestStreak}' : '0',
                          unit: 'days',
                          icon: Icons.emoji_events_rounded,
                          iconColor: Colors.amber,
                          tt: tt,
                        ),
                        _StatItem(
                          title: 'SQUATS',
                          value: stats != null ? '${stats.weeklyReps}' : '0',
                          unit: 'reps',
                          icon: Icons.fitness_center_rounded,
                          iconColor: AppColors.primary,
                          tt: tt,
                        ),
                        _StatItem(
                          title: 'ENERGY',
                          value: stats != null
                              ? '${stats.monthlyCalories}'
                              : '0',
                          unit: 'cal',
                          icon: Icons.bolt_rounded,
                          iconColor: AppColors.success,
                          tt: tt,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // ── Account Action Buttons (Sign Out / Close) ──────────────────
                if (isSignedIn) ...[
                  _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.destructive,
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () => _confirmSignOut(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.destructive,
                            side: const BorderSide(
                              color: AppColors.destructive,
                              width: 1.0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius,
                              ),
                            ),
                          ),
                          child: const Text(
                            'SIGN OUT OF ACCOUNT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.tt,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final AwakenTypography tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: tt.eyebrow.copyWith(
                    color: AppColors.mutedForeground,
                    fontSize: 8.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: iconColor, size: 14),
            ],
          ),
          const SizedBox(height: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: tt.statValue.copyWith(fontSize: 22, height: 1.1),
              ),
              Text(
                unit,
                style: tt.statLabel.copyWith(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
