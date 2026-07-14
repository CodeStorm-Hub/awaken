import 'package:awaken/core/services/alarm_notification_service.dart';
import 'package:awaken/features/alarm/data/datasources/alarm_local_datasource.dart';
import 'package:awaken/features/alarm/data/datasources/alarm_supabase_datasource.dart';
import 'package:awaken/features/alarm/data/repositories/alarm_repository_impl.dart';
import 'package:awaken/features/alarm/data/repositories/alarm_supabase_repository_impl.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/domain/repositories/alarm_repository.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'alarm_schedule_providers.g.dart';

/// Picks the correct repository based on auth state:
///   - Signed in  → Supabase (cloud-synced)
///   - Signed out → SharedPreferences (local-only)
@Riverpod(keepAlive: true)
AlarmRepository alarmRepository(Ref ref) {
  final signedIn = ref.watch(isSignedInProvider);
  if (signedIn) {
    return const AlarmSupabaseRepositoryImpl(AlarmSupabaseDatasource());
  }
  return const AlarmRepositoryImpl(AlarmLocalDatasource());
}

// ── Alarm list notifier ───────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class AlarmList extends _$AlarmList {
  @override
  Future<List<AlarmEntity>> build() async {
    // Rebuild if auth state flips (local ↔ cloud)
    ref.watch(isSignedInProvider);
    final alarms = await ref.read(alarmRepositoryProvider).getAlarms();

    // Sync local active alarms to OS scheduler upon app load
    final now = DateTime.now();
    for (final alarm in alarms) {
      if (alarm.isActive && alarm.scheduledTime.isAfter(now)) {
        try {
          await AlarmNotificationService.scheduleAlarm(alarm);
        } catch (e) {
          debugPrint('[Alarm] schedule on load failed: $e');
        }
      }
    }

    return alarms;
  }

  Future<void> addAlarm(AlarmEntity alarm) async {
    final repo = ref.read(alarmRepositoryProvider);
    await repo.saveAlarm(alarm);
    await AlarmNotificationService.scheduleAlarm(alarm);
    state = AsyncData(
      [...state.value ?? [], alarm]
        ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime)),
    );
  }

  /// Re-adds a just-deleted alarm (swipe-to-delete undo). Unlike [addAlarm],
  /// only reschedules the notification when the alarm was actually active.
  Future<void> restoreAlarm(AlarmEntity alarm) async {
    final repo = ref.read(alarmRepositoryProvider);
    await repo.saveAlarm(alarm);
    if (alarm.isActive) {
      await AlarmNotificationService.scheduleAlarm(alarm);
    }
    state = AsyncData(
      [...state.value ?? [], alarm]
        ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime)),
    );
  }

  Future<void> removeAlarm(AlarmEntity alarm) async {
    final repo = ref.read(alarmRepositoryProvider);
    await repo.deleteAlarm(alarm.id);
    await AlarmNotificationService.cancelAlarm(alarm);
    state = AsyncData(
      (state.value ?? []).where((a) => a.id != alarm.id).toList(),
    );
  }

  Future<void> markCompleted(AlarmEntity alarm) async {
    final updated = alarm.copyWith(isActive: false, penaltyMultiplier: 1);
    final repo = ref.read(alarmRepositoryProvider);
    await repo.saveAlarm(updated);
    try {
      await AlarmNotificationService.cancelAlarm(updated);
    } catch (e) {
      // Plugin may be uninitialized in tests / early cold start.
      debugPrint('[Alarm] cancel after complete failed: $e');
    }

    state = AsyncData(
      (state.value ?? []).map((a) => a.id == alarm.id ? updated : a).toList(),
    );
  }

  Future<void> toggleAlarm(AlarmEntity alarm) async {
    final updated = alarm.copyWith(isActive: !alarm.isActive);
    final repo = ref.read(alarmRepositoryProvider);
    await repo.saveAlarm(updated);

    if (updated.isActive) {
      await AlarmNotificationService.scheduleAlarm(updated);
    } else {
      await AlarmNotificationService.cancelAlarm(updated);
    }

    state = AsyncData(
      (state.value ?? []).map((a) => a.id == alarm.id ? updated : a).toList(),
    );
  }
}

// ── Derived: next upcoming active alarm ──────────────────────────────────────

@Riverpod(keepAlive: true)
AlarmEntity? nextAlarm(Ref ref) {
  final alarms = ref.watch(alarmListProvider).value ?? [];
  final now = DateTime.now();
  final upcoming =
      alarms.where((a) => a.isActive && a.scheduledTime.isAfter(now)).toList()
        ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  return upcoming.isEmpty ? null : upcoming.first;
}
