import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Start/Stop control, anchored in the bottom third of the screen for
/// thumb-zone reachability per the plan's touch-first ergonomics section.
class RunControls extends StatelessWidget {
  const RunControls({
    super.key,
    required this.isTracking,
    required this.onStart,
    required this.onStop,
  });

  final bool isTracking;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: isTracking ? onStop : onStart,
        style: ElevatedButton.styleFrom(
          backgroundColor: isTracking ? AppColors.destructive : AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          ),
          elevation: 0,
        ),
        child: Text(
          isTracking ? 'STOP' : 'START RUN',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1.5),
        ),
      ),
    );
  }
}
