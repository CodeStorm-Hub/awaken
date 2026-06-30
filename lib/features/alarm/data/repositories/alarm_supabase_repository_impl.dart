import 'package:awaken/features/alarm/data/datasources/alarm_supabase_datasource.dart';
import 'package:awaken/features/alarm/data/models/alarm_model.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/domain/repositories/alarm_repository.dart';

class AlarmSupabaseRepositoryImpl implements AlarmRepository {
  const AlarmSupabaseRepositoryImpl(this._datasource);

  final AlarmSupabaseDatasource _datasource;

  @override
  Future<List<AlarmEntity>> getAlarms() async {
    final models = await _datasource.getAlarms();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveAlarm(AlarmEntity alarm) async {
    await _datasource.saveAlarm(AlarmModel.fromEntity(alarm));
  }

  @override
  Future<void> deleteAlarm(String id) async {
    await _datasource.deleteAlarm(id);
  }
}
