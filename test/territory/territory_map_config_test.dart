import 'package:awaken/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('territory map zoom constants', () {
    test('client max zoom is capped at 18 for overzoom safety', () {
      expect(AppConstants.territoryMapMaxZoom, 18.0);
      expect(AppConstants.territoryMapMaxZoom, greaterThan(AppConstants.territoryVectorTileMaxZoom));
    });

    test('vector tile native max matches OpenMapTiles source', () {
      expect(AppConstants.territoryVectorTileMaxZoom, 14);
    });

    test('polygon glow is skipped below z12', () {
      expect(AppConstants.territoryPolygonGlowMinZoom, 12.0);
    });
  });
}
