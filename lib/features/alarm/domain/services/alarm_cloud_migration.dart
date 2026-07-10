import 'package:awaken/features/alarm/data/datasources/alarm_local_datasource.dart';
import 'package:awaken/features/alarm/data/datasources/alarm_supabase_datasource.dart';
import 'package:flutter/foundation.dart';

/// Copies SharedPreferences alarms into Supabase on first sign-in so local
/// schedules are not orphaned when the repository switches to cloud.
class AlarmCloudMigration {
  const AlarmCloudMigration({
    this.local = const AlarmLocalDatasource(),
    this.remote = const AlarmSupabaseDatasource(),
  });

  final AlarmLocalDatasource local;
  final AlarmSupabaseDatasource remote;

  Future<int> migrateLocalAlarmsToCloud() async {
    final localAlarms = await local.getAlarms();
    if (localAlarms.isEmpty) return 0;

    var migrated = 0;
    for (final alarm in localAlarms) {
      try {
        await remote.saveAlarm(alarm);
        migrated++;
      } catch (e) {
        debugPrint('[AlarmMigration] Failed to migrate ${alarm.id}: $e');
      }
    }
    return migrated;
  }
}
