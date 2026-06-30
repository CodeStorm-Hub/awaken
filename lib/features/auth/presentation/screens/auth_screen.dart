import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.onSkip});

  /// If non-null, shows a "Continue without account" link that calls this.
  final VoidCallback? onSkip;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
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
      // Router will react to authStateProvider change and navigate automatically
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPaddingH,
            vertical: AppConstants.screenPaddingV,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Logo + tagline ────────────────────────────────────────
              Text(
                'AWAKEN',
                style: tt.hudClock.copyWith(
                  fontSize: 56,
                  color: AppColors.primary,
                  letterSpacing: -1,
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 12),

              Text(
                'The alarm you can\'t skip.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

              const Spacer(flex: 3),

              // ── Error message ─────────────────────────────────────────
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppConstants.chipRadius),
                    border: Border.all(
                      color: AppColors.destructive.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.destructive,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Google Sign-In button ─────────────────────────────────
              _GoogleSignInButton(
                loading: _loading,
                onPressed: _signInWithGoogle,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              // ── Skip link ─────────────────────────────────────────────
              if (widget.onSkip != null) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: widget.onSkip,
                  child: Text(
                    'Continue without account',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedForeground,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.mutedForeground,
                        ),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.chipRadius),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" icon — inline SVG-style with coloured segments
                  const _GoogleIcon(),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  const _GoogleIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);

    // Draw the four coloured arcs of the Google "G" logo
    final segments = [
      (const Color(0xFF4285F4), -30.0, 120.0), // Blue
      (const Color(0xFF34A853), 90.0, 90.0), // Green
      (const Color(0xFFFBBC05), 180.0, 90.0), // Yellow
      (const Color(0xFFEA4335), 270.0, 90.0), // Red
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: r * 0.72);
    for (final (color, startDeg, sweepDeg) in segments) {
      paint.color = color;
      canvas.drawArc(
        rect,
        startDeg * (3.14159 / 180),
        sweepDeg * (3.14159 / 180),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GoogleIconPainter old) => false;
}
