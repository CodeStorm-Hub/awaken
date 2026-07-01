import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Start/Stop run control, pinned in the thumb zone.
/// Shows a pulsing glow ring while tracking, and a loading spinner
/// while the run is being processed (status == finishing).
class RunControls extends StatefulWidget {
  const RunControls({
    super.key,
    required this.isTracking,
    required this.onStart,
    required this.onStop,
    this.isFinishing = false,
  });

  final bool isTracking;
  final bool isFinishing;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  State<RunControls> createState() => _RunControlsState();
}

class _RunControlsState extends State<RunControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(RunControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTracking != widget.isTracking) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.isTracking) {
      _glowCtrl.repeat(reverse: true);
    } else {
      _glowCtrl.stop();
      _glowCtrl.reset();
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFinishing) {
      return _buildButton(
        label: 'SAVING…',
        color: AppColors.secondary,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: AppColors.foreground,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (widget.isTracking) {
      return AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.destructive
                    .withValues(alpha: _glowAnim.value * 0.5),
                blurRadius: 24 * _glowAnim.value,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
        child: _buildButton(
          label: 'STOP',
          color: AppColors.destructive,
          onPressed: widget.onStop,
        ),
      );
    }

    return _buildButton(
      label: 'START RUN',
      color: AppColors.primary,
      onPressed: widget.onStart,
    );
  }

  Widget _buildButton({
    required String label,
    required Color color,
    VoidCallback? onPressed,
    Widget? child,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          ),
          elevation: 0,
        ),
        child: child ??
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
      ),
    );
  }
}
