import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.onSkip});

  /// If non-null, shows a "Continue without account" link that calls this.
  final VoidCallback? onSkip;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _loading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (mounted) {
        setState(() => _loading = false);
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        await ref.read(authRepositoryProvider).signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          displayName: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
        );
        if (mounted) {
          final currentUser = ref.read(authRepositoryProvider).currentUser;
          if (currentUser == null) {
            // Email confirmation is likely enabled
            setState(() {
              _error = 'Sign up successful! Please check your email to confirm registration.';
              _loading = false;
            });
          }
        }
      } else {
        await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          setState(() => _loading = false);
          context.go(AppRoutes.dashboard);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString()
              .replaceFirst('Exception: ', '')
              .replaceFirst('AuthException: ', '');
          _loading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: AppColors.mutedForeground),
      prefixIcon: Icon(prefixIcon, color: AppColors.mutedForeground, size: 18),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.chipRadius),
        borderSide: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.chipRadius),
        borderSide: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.chipRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.chipRadius),
        borderSide: const BorderSide(color: AppColors.destructive, width: 0.8),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.chipRadius),
        borderSide: const BorderSide(color: AppColors.destructive, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenPaddingH,
              vertical: AppConstants.screenPaddingV,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // ── Logo + tagline ────────────────────────────────────────
                  Center(
                    child: Text(
                      'AWAKEN',
                      style: tt.hudClock.copyWith(
                        fontSize: 56,
                        color: AppColors.primary,
                        letterSpacing: -1,
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      'The alarm you can\'t skip.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.mutedForeground,
                          ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  ),

                  const SizedBox(height: 32),

                  // ── Error message ─────────────────────────────────────────
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _error!.contains('successful')
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.destructive.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppConstants.chipRadius),
                        border: Border.all(
                          color: _error!.contains('successful')
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.destructive.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _error!.contains('successful')
                                  ? AppColors.success
                                  : AppColors.destructive,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Name Field (Sign-up only) ─────────────────────────────
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: AppColors.foreground),
                      decoration: _inputDecoration(
                        labelText: 'Display Name',
                        prefixIcon: Icons.person_outline,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Please enter your name' : null,
                    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0, duration: 200.ms),
                    const SizedBox(height: 16),
                  ],

                  // ── Email Field ───────────────────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: AppColors.foreground),
                    decoration: _inputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── Password Field ────────────────────────────────────────
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: AppColors.foreground),
                    decoration: _inputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.mutedForeground,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),

                  const SizedBox(height: 24),

                  // ── Submit Button ─────────────────────────────────────────
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.chipRadius),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              _isSignUp ? 'Create Account' : 'Sign In',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Toggle Link ───────────────────────────────────────────
                  Center(
                    child: TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _error = null;
                              });
                            },
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.mutedForeground,
                              ),
                          children: [
                            TextSpan(
                              text: _isSignUp
                                  ? 'Already have an account? '
                                  : 'Don\'t have an account? ',
                            ),
                            TextSpan(
                              text: _isSignUp ? 'Sign In' : 'Sign Up',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Divider ───────────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.mutedForeground,
                              ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Google Sign-In button ─────────────────────────────────
                  _GoogleSignInButton(
                    loading: _loading,
                    onPressed: _signInWithGoogle,
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  // ── Skip link ─────────────────────────────────────────────
                  if (widget.onSkip != null) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: widget.onSkip,
                        child: Text(
                          'Continue without account',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.mutedForeground,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.mutedForeground,
                              ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
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
        onPressed: loading
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed();
              },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border, width: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.chipRadius),
          ),
          backgroundColor: Colors.black.withValues(alpha: 0.2),
          foregroundColor: AppColors.foreground,
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
