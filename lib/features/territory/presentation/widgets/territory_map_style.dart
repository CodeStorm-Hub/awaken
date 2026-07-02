import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' show ThemeReader;

/// Loads Awaken's bundled, re-themed OpenFreeMap "dark" vector style.
///
/// `assets/map_styles/awaken_dark.json` is a fork of OpenFreeMap's public
/// `dark` style (itself forked from `openmaptiles/dark-matter-gl-style`),
/// re-painted to match `AppColors` — see `tool/retheme_map_style.py` for how
/// it was generated. Re-run that script if OpenFreeMap's upstream style
/// changes.
///
/// Deliberately not `vector_map_tiles`'s `StyleReader` directly: that class
/// always fetches the *style document* itself over HTTP, whereas we want the
/// style bundled with the app so branding is deterministic and the style
/// parses even if the network is briefly unavailable. Resolving the actual
/// tile source still requires one HTTP round-trip (OpenFreeMap serves the
/// `openmaptiles` source as a TileJSON document, not inline tile URLs),
/// matching what `StyleReader` would do for the same style document.
abstract final class TerritoryMapStyle {
  static const String assetPath = 'assets/map_styles/awaken_dark.json';

  static Future<Style> load() async {
    final styleText = await rootBundle.loadString(assetPath);
    final styleJson = jsonDecode(styleText) as Map<String, dynamic>;
    final sources = styleJson['sources'] as Map<String, dynamic>;

    final providerByName = <String, VectorTileProvider>{};
    for (final entry in sources.entries) {
      final sourceValue = entry.value as Map<String, dynamic>;
      final provider = await _resolveProvider(sourceValue);
      if (provider != null) providerByName[entry.key] = provider;
    }

    if (providerByName.isEmpty) {
      throw StateError('Awaken map style has no usable tile sources.');
    }

    return Style(
      theme: ThemeReader().read(styleJson),
      providers: TileProviders(providerByName),
    );
  }

  static Future<VectorTileProvider?> _resolveProvider(
    Map<String, dynamic> sourceValue,
  ) async {
    final type = _tileProviderType(sourceValue['type'] as String?);
    if (type == null) return null;

    Map<String, dynamic> resolvedSource;
    final sourceUrl = sourceValue['url'] as String?;
    if (sourceUrl != null) {
      final response = await http
          .get(Uri.parse(sourceUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw StateError(
          'Failed to resolve tile source "$sourceUrl": HTTP ${response.statusCode}',
        );
      }
      resolvedSource = jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      resolvedSource = sourceValue;
    }

    final tiles = resolvedSource['tiles'] as List?;
    if (tiles == null || tiles.isEmpty) return null;

    return NetworkVectorTileProvider(
      type: type,
      urlTemplate: tiles.first as String,
      maximumZoom: (resolvedSource['maxzoom'] as num?)?.toInt() ?? 14,
      minimumZoom: (resolvedSource['minzoom'] as num?)?.toInt() ?? 1,
    );
  }

  static TileProviderType? _tileProviderType(String? name) {
    for (final type in TileProviderType.values) {
      if (type.name == name) return type;
    }
    return null;
  }
}
