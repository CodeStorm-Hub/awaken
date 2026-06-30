import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';

abstract class AlarmRepository {
  Future<List<AlarmEntity>> getAlarms();
  Future<void> saveAlarm(AlarmEntity alarm);
  Future<void> deleteAlarm(String id);
}
