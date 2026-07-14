import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:awaken/features/territory/presentation/widgets/territory_map_tile_provider.dart';
import 'package:flutter/material.dart' hide Theme;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

/// Stable key for the territory basemap [FlutterMap] — prevents recreation on
/// sibling overlay rebuilds.
const territoryFlutterMapKey = ValueKey<String>('territory-flutter-map');

/// Stable key for the capture-result minimap — must differ from the run screen.
const territoryCaptureMinimapKey = ValueKey<String>(
  'territory-capture-minimap',
);

/// Stable key for the vector tile layer subtree.
const territoryVectorTileLayerKey = ValueKey<String>(
  'territory-vector-tile-layer',
);

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
///
/// Phase 5 offline note: regional [vector_map_tiles_pmtiles] (MIT) can be
/// layered here as a fallback when network tiles fail — incompatible with
/// Protomaps-only themes; keep OpenMapTiles schema for `awaken_dark.json`.
class TerritoryVectorTileLayer extends ConsumerStatefulWidget {
  const TerritoryVectorTileLayer({super.key, this.forceRender = false});

  /// When true, renders even if the territory shell tab is inactive (e.g.
  /// capture-result minimap inside a bottom sheet).
  final bool forceRender;

  @override
  ConsumerState<TerritoryVectorTileLayer> createState() =>
      _TerritoryVectorTileLayerState();
}

class _TerritoryVectorTileLayerState
    extends ConsumerState<TerritoryVectorTileLayer>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool get _shouldRender {
    if (!ref.watch(territoryMapReadyProvider)) return false;
    if (widget.forceRender) return true;

    final tabIndex = ref.watch(territoryShellTabIndexProvider);
    if (tabIndex == 1) return true;

    return ref.watch(territoryRunGpsKeepAliveProvider);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_shouldRender) {
      return const SizedBox.shrink();
    }

    final engine = ref.watch(mapEngineProvider);
    if (engine == MapEngine.raster) {
      return const _RasterFallbackTileLayer();
    }

    final styleAsync = ref.watch(territoryMapStyleProvider);

    return styleAsync.when(
      data: (style) => RepaintBoundary(
        child: VectorTileLayer(
          key: territoryVectorTileLayerKey,
          theme: style.theme,
          tileProviders: style.providers,
          sprites: style.sprites,
          concurrency: 4,
          fileCacheTtl: const Duration(days: 30),
          fileCacheMaximumSizeInBytes: 50 * 1024 * 1024,
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

  static const _key = ValueKey<String>('territory-raster-tile-layer');

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      key: _key,
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: territoryMapTileUserAgent,
      maxNativeZoom: 19,
      maxZoom: AppConstants.territoryMapMaxZoom,
      tileProvider: territoryCancellableTileProvider(),
    );
  }
}
