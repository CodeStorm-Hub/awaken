import 'package:awaken/features/alarm/data/models/alarm_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlarmSupabaseDatasource {
  const AlarmSupabaseDatasource();

  SupabaseClient get _client => Supabase.instance.client;
  String get _userId => _client.auth.currentUser!.id;

  Future<List<AlarmModel>> getAlarms() async {
    final data = await _client
        .from('alarms')
        .select()
        .eq('user_id', _userId)
        .order('scheduled_time');
    return (data as List)
        .map((json) => AlarmModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAlarm(AlarmModel alarm) async {
    await _client.from('alarms').upsert(alarm.toSupabaseJson(_userId));
  }

  Future<void> deleteAlarm(String id) async {
    await _client
        .from('alarms')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
