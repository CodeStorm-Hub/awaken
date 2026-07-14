import 'dart:convert';

import 'package:awaken/features/alarm/data/models/alarm_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists alarms to SharedPreferences as a JSON-encoded list.
/// Will be replaced by a Supabase datasource in Phase 6.
class AlarmLocalDatasource {
  const AlarmLocalDatasource();

  static const _key = 'awaken_alarms';

  Future<List<AlarmModel>> getAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) => AlarmModel.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAlarm(AlarmModel alarm) async {
    final prefs = await SharedPreferences.getInstance();
    final alarms = await getAlarms();
    // Upsert: replace existing entry with same id
    final updated = [...alarms.where((a) => a.id != alarm.id), alarm]
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    await prefs.setStringList(
      _key,
      updated.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }

  Future<void> deleteAlarm(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final alarms = await getAlarms();
    final updated = alarms.where((a) => a.id != id).toList();
    await prefs.setStringList(
      _key,
      updated.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }
}
