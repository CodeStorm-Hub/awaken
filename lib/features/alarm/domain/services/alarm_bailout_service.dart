import 'dart:convert';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_exercise_type.dart';
import 'package:awaken/features/alarm/domain/repositories/alarm_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Local record of an alarm firing that must be completed or incurs bailout.
class AlarmTriggerRecord {
  const AlarmTriggerRecord({
    required this.id,
    required this.alarmId,
    required this.firedAt,
    required this.requiredReps,
    required this.exerciseType,
    this.resolvedAt,
  });

  final String id;
  final String alarmId;
  final DateTime firedAt;
  final int requiredReps;
  final AlarmExerciseType exerciseType;
  final DateTime? resolvedAt;

  bool get isResolved => resolvedAt != null;

  AlarmTriggerRecord copyWith({DateTime? resolvedAt}) => AlarmTriggerRecord(
        id: id,
        alarmId: alarmId,
        firedAt: firedAt,
        requiredReps: requiredReps,
        exerciseType: exerciseType,
        resolvedAt: resolvedAt ?? this.resolvedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'alarm_id': alarmId,
        'fired_at': firedAt.toIso8601String(),
        'required_reps': requiredReps,
        'exercise_type': exerciseType.wireName,
        if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
      };

  factory AlarmTriggerRecord.fromJson(Map<String, dynamic> json) {
    return AlarmTriggerRecord(
      id: json['id'] as String,
      alarmId: json['alarm_id'] as String,
      firedAt: DateTime.parse(json['fired_at'] as String),
      requiredReps: json['required_reps'] as int,
      exerciseType: AlarmExerciseTypeX.tryParse(json['exercise_type'] as String?) ??
          AlarmExerciseType.squats,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }
}

/// SharedPreferences-backed alarm trigger log + bailout penalty application.
class AlarmBailoutService {
  const AlarmBailoutService();

  static const _key = 'awaken_alarm_triggers';

  Future<List<AlarmTriggerRecord>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) => AlarmTriggerRecord.fromJson(
              jsonDecode(e) as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<void> _writeAll(List<AlarmTriggerRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      records.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  Future<AlarmTriggerRecord> recordFire({
    required AlarmEntity alarm,
    required AlarmExerciseType exerciseType,
    required int requiredReps,
    DateTime? now,
  }) async {
    final records = await _readAll();
    final open = records.where(
      (r) => r.alarmId == alarm.id && !r.isResolved,
    );
    if (open.isNotEmpty) return open.first;

    final record = AlarmTriggerRecord(
      id: '${alarm.id}_${(now ?? DateTime.now()).millisecondsSinceEpoch}',
      alarmId: alarm.id,
      firedAt: now ?? DateTime.now(),
      requiredReps: requiredReps,
      exerciseType: exerciseType,
    );
    records.add(record);
    await _writeAll(records);
    return record;
  }

  Future<void> resolveForAlarm(String alarmId, {DateTime? now}) async {
    final records = await _readAll();
    final at = now ?? DateTime.now();
    var changed = false;
    final updated = records.map((r) {
      if (r.alarmId == alarmId && !r.isResolved) {
        changed = true;
        return r.copyWith(resolvedAt: at);
      }
      return r;
    }).toList();
    if (changed) await _writeAll(updated);
  }

  /// Applies 2× penalty to alarms with unresolved triggers past the bailout window.
  Future<int> applyBailoutPenalties({
    required AlarmRepository repository,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final records = await _readAll();
    final alarms = await repository.getAlarms();
    var applied = 0;

    for (final alarm in alarms) {
      final stale = records.where(
        (r) =>
            r.alarmId == alarm.id &&
            !r.isResolved &&
            at.difference(r.firedAt) >= AppConstants.bailoutWindow,
      );
      if (stale.isEmpty) continue;
      if (alarm.penaltyMultiplier >= 2) continue;

      await repository.saveAlarm(alarm.copyWith(penaltyMultiplier: 2));
      applied++;
      // Notify squadmates that this user bailed (shared suffering).
      try {
        await Supabase.instance.client.rpc<void>('report_squad_bailout');
      } on Object catch (_) {}
    }

    // Consume peer bailouts → double this user's next tax too.
    try {
      final hit = await Supabase.instance.client
          .rpc<bool>('consume_squad_bailout_penalty');
      if (hit == true) {
        for (final alarm in await repository.getAlarms()) {
          if (alarm.penaltyMultiplier >= 2) continue;
          await repository.saveAlarm(alarm.copyWith(penaltyMultiplier: 2));
          applied++;
        }
      }
    } on Object catch (_) {}

    return applied;
  }

  Future<bool> hasPendingPenalty(String alarmId) async {
    final records = await _readAll();
    return records.any((r) => r.alarmId == alarmId && !r.isResolved);
  }

  Future<bool> anyUnresolvedPastWindow({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final records = await _readAll();
    return records.any(
      (r) =>
          !r.isResolved &&
          at.difference(r.firedAt) >= AppConstants.bailoutWindow,
    );
  }
}
