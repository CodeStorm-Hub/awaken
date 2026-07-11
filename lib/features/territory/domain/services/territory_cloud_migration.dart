import 'package:awaken/features/territory/data/datasources/territory_supabase_datasource.dart';
import 'package:awaken/features/territory/data/repositories/territory_local_repository_impl.dart';
import 'package:flutter/foundation.dart';

/// Uploads SharedPreferences territories into Supabase on first sign-in so
/// offline guest captures are not orphaned when the repository switches.
class TerritoryCloudMigration {
  TerritoryCloudMigration({
    TerritoryLocalRepositoryImpl? local,
    this.remote = const TerritorySupabaseDatasource(),
  }) : local = local ?? TerritoryLocalRepositoryImpl();

  final TerritoryLocalRepositoryImpl local;
  final TerritorySupabaseDatasource remote;

  Future<int> migrateLocalTerritoriesToCloud() async {
    final territories = await local.getAllTerritories();
    final owned = territories
        .where((t) => t.userId == 'local-user' || t.isOwnedByCurrentUser)
        .toList();
    if (owned.isEmpty) return 0;

    var migrated = 0;
    for (final territory in owned) {
      for (final ring in territory.polygons) {
        if (ring.length < 6) continue;
        try {
          await remote.captureTerritory(ring);
          migrated++;
        } catch (e) {
          debugPrint('[TerritoryMigration] Failed ring migrate: $e');
        }
      }
    }

    if (migrated > 0) {
      await local.clearOwnedLocalTerritories();
    }
    return migrated;
  }
}
