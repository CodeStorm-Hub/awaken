import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:flutter/material.dart' hide Theme;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

/// Renders Awaken's basemap — branded OpenFreeMap vector tiles by default,
/// or a plain OSM raster fallback when [mapEngineProvider] is flipped to
/// [MapEngine.raster] (an emergency low-end-device degrade path; not
/// user-facing, see that provider's doc comment).
///
/// The vector path uses [VectorTileLayerMode.raster] (the package default):
/// tiles are still parsed and themed client-side (crisp, on-brand colors at
/// every zoom), but painted to a raster buffer per tile rather than
/// re-rendered as live vectors every frame. This gives the best frame rate —
/// full [VectorTileLayerMode.vector] rendering can jank on low-end Android
/// and is deliberately not used here.
///
/// Renders nothing while the vector style/tile-source is loading or failed
/// to resolve — see [TerritoryMapStatusOverlay], which is the sibling widget
/// responsible for surfacing that loading/error state to the user.
class TerritoryVectorTileLayer extends ConsumerWidget {
  const TerritoryVectorTileLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(mapEngineProvider);
    if (engine == MapEngine.raster) return const _RasterFallbackTileLayer();

    final styleAsync = ref.watch(territoryMapStyleProvider);

    return styleAsync.when(
      data: (style) => RepaintBoundary(
        child: VectorTileLayer(
          theme: style.theme,
          tileProviders: style.providers,
          sprites: style.sprites,
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Plain OSM raster XYZ tiles — unthemed, but free, keyless, and
/// commercial-use-safe like the vector path (same OpenStreetMap data,
/// same attribution requirement). Only reached when [mapEngineProvider]
/// is explicitly flipped to [MapEngine.raster].
class _RasterFallbackTileLayer extends StatelessWidget {
  const _RasterFallbackTileLayer();

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.awaken.app',
      tileProvider: NetworkTileProvider(),
    );
  }
}
