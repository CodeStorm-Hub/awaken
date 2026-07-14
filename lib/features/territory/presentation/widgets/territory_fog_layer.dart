import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/features/territory/data/datasources/explored_cells_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Soft Motera-style fog: near-black veil with circular revealed holes and a
/// faint grid — no hard cell borders.
class TerritoryFogLayer extends StatelessWidget {
  const TerritoryFogLayer({
    super.key,
    required this.store,
    this.enabled = true,
  });

  final ExploredCellsStore store;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();

    final camera = MapCamera.of(context);
    return IgnorePointer(
      child: CustomPaint(
        size: Size(camera.nonRotatedSize.x, camera.nonRotatedSize.y),
        painter: _FogPainter(
          camera: camera,
          cells: store.cells,
          fullyFogged: store.isEmpty,
        ),
      ),
    );
  }
}

class _FogPainter extends CustomPainter {
  _FogPainter({
    required this.camera,
    required this.cells,
    required this.fullyFogged,
  });

  final MapCamera camera;
  final Set<String> cells;
  final bool fullyFogged;

  static const _fogFill = Color(0xD908080C);
  static const _gridColor = Color(0x14FFFFFF);

  Offset _toScreen(LatLng latLng) {
    final p = camera.latLngToScreenPoint(latLng);
    return Offset(p.x, p.y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(bounds, Paint()..color = _fogFill);
    _paintFaintGrid(canvas, size);

    if (!fullyFogged && cells.isNotEmpty) {
      final holePaint = Paint()..blendMode = BlendMode.dstOut;
      const step = AppConstants.fogCellDegrees;
      // Soft radius ≈ cell size in screen space.
      final cellCorner = _toScreen(
        LatLng(camera.center.latitude, camera.center.longitude + step),
      );
      final cellPx = (cellCorner.dx - size.width / 2).abs().clamp(18.0, 120.0);
      final radius = cellPx * 1.35;

      for (final key in cells) {
        final (lat, lng) = ExploredCellsStore.cellCenter(key);
        final screen = _toScreen(LatLng(lat, lng));
        if (screen.dx < -radius * 2 ||
            screen.dy < -radius * 2 ||
            screen.dx > size.width + radius * 2 ||
            screen.dy > size.height + radius * 2) {
          continue;
        }
        holePaint.shader = ui.Gradient.radial(
          screen,
          radius,
          const [Color(0xFFFFFFFF), Color(0xCCFFFFFF), Color(0x00FFFFFF)],
          const [0.0, 0.55, 1.0],
        );
        canvas.drawCircle(screen, radius, holePaint);
      }
    }

    canvas.restore();
  }

  void _paintFaintGrid(Canvas canvas, Size size) {
    const step = AppConstants.fogCellDegrees;
    final bounds = camera.visibleBounds;
    final paint = Paint()
      ..color = _gridColor
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    final i0 = (bounds.south / step).floor() - 1;
    final i1 = (bounds.north / step).ceil() + 1;
    final j0 = (bounds.west / step).floor() - 1;
    final j1 = (bounds.east / step).ceil() + 1;

    final rows = i1 - i0;
    final cols = j1 - j0;
    final stride = math.max(1, ((rows * cols) / 400).ceil());

    for (var i = i0; i <= i1; i += stride) {
      final a = _toScreen(LatLng(i * step, bounds.west));
      final b = _toScreen(LatLng(i * step, bounds.east));
      canvas.drawLine(a, b, paint);
    }
    for (var j = j0; j <= j1; j += stride) {
      final a = _toScreen(LatLng(bounds.south, j * step));
      final b = _toScreen(LatLng(bounds.north, j * step));
      canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FogPainter oldDelegate) {
    return oldDelegate.camera.zoom != camera.zoom ||
        oldDelegate.camera.center != camera.center ||
        oldDelegate.cells != cells ||
        oldDelegate.fullyFogged != fullyFogged;
  }
}
