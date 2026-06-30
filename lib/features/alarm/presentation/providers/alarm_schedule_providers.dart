import 'package:awaken/core/services/alarm_notification_service.dart';
import 'package:awaken/features/alarm/data/datasources/alarm_local_datasource.dart';
import 'package:awaken/features/alarm/data/datasources/alarm_supabase_datasource.dart';
import 'package:awaken/features/alarm/data/repositories/alarm_repository_impl.dart';
import 'package:awaken/features/alarm/data/repositories/alarm_supabase_repository_impl.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/domain/repositories/alarm_repository.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Picks the correct repository based on auth state:
///   - Signed in  → Supabase (cloud-synced)
///   - Signed out → SharedPreferences (local-only)
final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  final signedIn = ref.watch(isSignedInProvider);
  if (signedIn) {
    return const AlarmSupabaseRepositoryImpl(AlarmSupabaseDatasource());
  }
  return const AlarmRepositoryImpl(AlarmLocalDatasource());
});

// ── Alarm list notifier ───────────────────────────────────────────────────────

class AlarmListNotifier extends AsyncNotifier<List<AlarmEntity>> {
  @override
  Future<List<AlarmEntity>> build() async {
    // Rebuild if auth state flips (local ↔ cloud)
    ref.watch(isSignedInProvider);
    return ref.read(alarmRepositoryProvider).getAlarms();
  }

  Future<void> addAlarm(AlarmEntity alarm) async {
    final repo = ref.read(alarmRepositoryProvider);
    await repo.saveAlarm(alarm);
    await AlarmNotificationService.scheduleAlarm(alarm);
    state = AsyncData([...state.valueOrNull ?? [], alarm]
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime)));
  }

  Future<void> removeAlarm(AlarmEntity alarm) async {
    final repo = ref.read(alarmRepositoryProvider);
    await repo.deleteAlarm(alarm.id);
    await AlarmNotificationService.cancelAlarm(alarm);
    state = AsyncData(
      (state.valueOrNull ?? []).where((a) => a.id != alarm.id).toList(),
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
      (state.valueOrNull ?? []).map((a) => a.id == alarm.id ? updated : a).toList(),
    );
  }
}

final alarmListProvider =
    AsyncNotifierProvider<AlarmListNotifier, List<AlarmEntity>>(
  AlarmListNotifier.new,
);

// ── Derived: next upcoming active alarm ──────────────────────────────────────

final nextAlarmProvider = Provider<AlarmEntity?>((ref) {
  final alarms = ref.watch(alarmListProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final upcoming = alarms
      .where((a) => a.isActive && a.scheduledTime.isAfter(now))
      .toList()
    ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  return upcoming.isEmpty ? null : upcoming.first;
});
