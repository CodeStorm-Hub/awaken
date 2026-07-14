import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/territory/domain/entities/capture_result_entity.dart';
import 'package:awaken/features/territory/presentation/widgets/distance_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

class RunDetailsScreen extends StatelessWidget {
  const RunDetailsScreen({
    super.key,
    this.runId,
    this.result,
    this.distanceMeters = 1820,
    this.duration = const Duration(minutes: 12, seconds: 45),
  });

  final String? runId;
  final SessionCaptureResultEntity? result;
  final double distanceMeters;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    final double areaSqM = result?.totalClaimedAreaSqMeters ?? 75000;
    final int rivals = result?.totalRivalsAffected ?? 2;
    final int loops = result?.loopsCaptured ?? 1;

    final paceMinutes = duration.inSeconds > 0 && distanceMeters > 0
        ? (duration.inSeconds / 60) / (distanceMeters / 1000)
        : 0.0;
    final paceMinStr = paceMinutes.floor();
    final paceSecStr = ((paceMinutes - paceMinStr) * 60).round().toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('RUN RECAP', style: tt.eyebrow),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPaddingH,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Static Map View Mockup
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                clipBehavior: Clip.antiAlias,
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(23.8103, 90.4125), // Dhaka center default
                    initialZoom: 15,
                    interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                    ),
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: const [
                            LatLng(23.8123, 90.4105),
                            LatLng(23.8123, 90.4145),
                            LatLng(23.8083, 90.4145),
                            LatLng(23.8083, 90.4105),
                          ],
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // Run Stats grid
              Text('SESSION METRICS', style: tt.eyebrow),
              const SizedBox(height: 12),
              GridPaper(
                color: Colors.transparent,
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _RecapStatTile(
                      label: 'CLAIMED AREA',
                      value: '${(areaSqM / 1000000).toStringAsFixed(3)} km²',
                      valueColor: AppColors.primary,
                    ),
                    _RecapStatTile(
                      label: 'TOTAL DISTANCE',
                      value: formatDistanceKm(distanceMeters),
                    ),
                    _RecapStatTile(
                      label: 'DURATION',
                      value: '${duration.inMinutes}m ${duration.inSeconds % 60}s',
                    ),
                    _RecapStatTile(
                      label: 'AVERAGE PACE',
                      value: '$paceMinStr\'$paceSecStr" /km',
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

              const SizedBox(height: 20),

              // Loops and Rivals panel
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.change_circle_rounded, color: AppColors.accent, size: 24),
                          const SizedBox(height: 8),
                          Text('LOOPS CLOSED', style: tt.statLabel),
                          const SizedBox(height: 4),
                          Text('$loops', style: tt.statValue.copyWith(color: AppColors.accent)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 48, color: AppColors.border),
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.flash_on_rounded, color: AppColors.success, size: 24),
                          const SizedBox(height: 8),
                          Text('RIVALS AFFECTED', style: tt.statLabel),
                          const SizedBox(height: 4),
                          Text('$rivals', style: tt.statValue.copyWith(color: AppColors.success)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 250.ms, duration: 300.ms),

              const SizedBox(height: 32),

              // Action buttons
              ElevatedButton.icon(
                onPressed: () {
                  // ignore: deprecated_member_use
                  Share.share(
                    'I claimed ${(areaSqM / 1000000).toStringAsFixed(3)} km² of territory today in Awaken!',
                    subject: 'Awaken Territory Capture',
                  );
                },
                icon: const Icon(Icons.share_rounded),
                label: const Text('SHARE RUN RECAP'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('BACK TO MAP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecapStatTile extends StatelessWidget {
  const _RecapStatTile({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: tt.statLabel.copyWith(fontSize: 9, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Text(
            value,
            style: tt.statValue.copyWith(
              fontSize: 18,
              color: valueColor ?? AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
