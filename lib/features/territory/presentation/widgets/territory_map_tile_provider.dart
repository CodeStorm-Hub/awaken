import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

/// User-Agent string sent with territory map tile HTTP requests.
const territoryMapTileUserAgent = 'com.awaken.app';

/// Shared cancellable network tile provider — aborts in-flight tile fetches
/// when tiles scroll off-screen during pan/zoom.
TileProvider territoryCancellableTileProvider() {
  return CancellableNetworkTileProvider();
}
