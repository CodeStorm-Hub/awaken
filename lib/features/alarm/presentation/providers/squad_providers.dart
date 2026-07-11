import 'dart:async';

import 'package:awaken/features/alarm/domain/entities/squad_mate_progress.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Squad membership ─────────────────────────────────────────────────────────

/// The squad id the current user belongs to, or null when not in a squad.
/// Fetches from `squad_members` on first watch; refreshed on sign-in.
final currentSquadIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    final rows = await Supabase.instance.client
        .from('squad_members')
        .select('squad_id')
        .eq('user_id', user.id)
        .limit(1) as List<dynamic>;
    if (rows.isEmpty) return null;
    return (rows.first as Map<String, dynamic>)['squad_id'] as String?;
  } catch (e) {
    debugPrint('[SquadProviders] fetchSquadId failed: $e');
    return null;
  }
});

// ── Squad mate progress stream ────────────────────────────────────────────────

/// Streams live [SquadMateProgress] for every squad mate (excluding the
/// current user) during an active alarm session.
///
/// Subscribes to Realtime INSERT/UPDATE on `squad_alarms` filtered by
/// `squad_id`. Returns an empty list when the user has no squad.
final squadMateProgressProvider =
    StreamProvider<List<SquadMateProgress>>((ref) async* {
  final squadIdAsync = ref.watch(currentSquadIdProvider);
  final squadId = squadIdAsync.valueOrNull;
  if (squadId == null) {
    yield const [];
    return;
  }

  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  if (currentUserId == null) {
    yield const [];
    return;
  }

  final controller = StreamController<List<SquadMateProgress>>();
  final progress = <String, SquadMateProgress>{};

  Future<void> bootstrapFromDb() async {
    try {
      final rows = await Supabase.instance.client
          .from('squad_alarms')
          .select('user_id, rep_count, required_reps, exercise_type')
          .eq('squad_id', squadId) as List<dynamic>;
      for (final row in rows) {
        if (row is Map<String, dynamic>) {
          final uid = row['user_id'] as String?;
          if (uid == null || uid == currentUserId) continue;
          progress[uid] = SquadMateProgress.fromRow(row);
        }
      }
      if (!controller.isClosed) {
        controller.add(List.unmodifiable(progress.values.take(3).toList()));
      }
    } catch (e) {
      debugPrint('[SquadProviders] bootstrap failed: $e');
    }
  }

  await bootstrapFromDb();

  final channel = Supabase.instance.client
      .channel('squad_alarms_$squadId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'squad_alarms',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'squad_id',
          value: squadId,
        ),
        callback: (payload) {
          final row = payload.newRecord;
          if (row.isEmpty) return;
          final uid = row['user_id'] as String?;
          if (uid == null || uid == currentUserId) return;
          progress[uid] = SquadMateProgress.fromRow(row);
          if (!controller.isClosed) {
            controller
                .add(List.unmodifiable(progress.values.take(3).toList()));
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  yield* controller.stream;
});

// ── Own row upsert ────────────────────────────────────────────────────────────

/// Upserts the current user's row in `squad_alarms` with latest rep progress.
/// Called on each rep count change from [ActiveAlarmScreen].
Future<void> upsertSquadAlarmProgress({
  required String squadId,
  required String userId,
  required int repCount,
  required int requiredReps,
  required String exerciseType,
}) async {
  try {
    await Supabase.instance.client.from('squad_alarms').upsert(
      {
        'squad_id': squadId,
        'user_id': userId,
        'rep_count': repCount,
        'required_reps': requiredReps,
        'exercise_type': exerciseType,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'squad_id,user_id',
    );
  } catch (e) {
    debugPrint('[SquadProviders] upsert failed: $e');
  }
}

// ── Squad management stubs ────────────────────────────────────────────────────

/// Creates a new squad and adds the current user as its first member.
/// Returns the invite code, or null on failure.
Future<String?> createSquad({required String name}) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  try {
    final inserted = await Supabase.instance.client
        .from('squads')
        .insert({'name': name, 'created_by': userId})
        .select('id, invite_code')
        .single();
    final squadId = inserted['id'] as String;
    final code = inserted['invite_code'] as String?;
    await Supabase.instance.client.from('squad_members').insert({
      'squad_id': squadId,
      'user_id': userId,
    });
    return code ?? squadId;
  } catch (e) {
    debugPrint('[SquadProviders] createSquad failed: $e');
    return null;
  }
}

/// Joins an existing squad by its invite code.
/// Returns the squad id on success, or null on failure.
Future<String?> joinSquadByCode({required String code}) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  try {
    final rows = await Supabase.instance.client
        .from('squads')
        .select('id')
        .eq('invite_code', code)
        .limit(1) as List<dynamic>;
    if (rows.isEmpty) return null;
    final squadId = (rows.first as Map<String, dynamic>)['id'] as String;
    await Supabase.instance.client.from('squad_members').upsert(
      {'squad_id': squadId, 'user_id': userId},
      onConflict: 'squad_id,user_id',
    );
    return squadId;
  } catch (e) {
    debugPrint('[SquadProviders] joinSquadByCode failed: $e');
    return null;
  }
}
