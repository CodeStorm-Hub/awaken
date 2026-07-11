import 'dart:async';

import 'package:awaken/core/services/push_token_service.dart';
import 'package:awaken/core/services/turf_hit_notification_service.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Subscribes to Supabase Realtime on `turf_hit_notifications` filtered by
/// the current user. On INSERT, shows a local turf-hit notification.
/// Also registers the device push token whenever the user signs in.
///
/// Exposed as a [Provider] that is watched in [AwakenApp.build] so it lives
/// for the app lifetime.
final turfHitRealtimeProvider = Provider<void>((ref) {
  RealtimeChannel? channel;

  bool isSupabaseReady() {
    try {
      // Throws if [Supabase.initialize] has not run (widget tests).
      Supabase.instance.client;
      return true;
    } on Object catch (_) {
      return false;
    }
  }

  void subscribe(String userId) {
    if (!isSupabaseReady()) return;
    channel?.unsubscribe();

    channel = Supabase.instance.client
        .channel('turf_hit_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'turf_hit_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'victim_user_id',
            value: userId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            final areaSqm =
                (row['claimed_area_sq_meters'] as num?)?.toDouble() ?? 0.0;
            TurfHitNotificationService.showTurfHit(areaSqm: areaSqm);
          },
        )
        .subscribe();
  }

  void unsubscribe() {
    channel?.unsubscribe();
    channel = null;
  }

  ref.listen(authStateProvider, (previous, next) {
    next.whenData((state) async {
      final userId = state.session?.user.id;
      if (userId != null) {
        subscribe(userId);
        try {
          await PushTokenService.registerForCurrentUser();
        } catch (e) {
          debugPrint('[TurfHitRealtime] push token registration failed: $e');
        }
      } else {
        unsubscribe();
      }
    });
  });

  if (isSupabaseReady()) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null) {
      subscribe(currentUserId);
      unawaited(
        PushTokenService.registerForCurrentUser().catchError(
          (Object e) =>
              debugPrint('[TurfHitRealtime] startup token reg failed: $e'),
        ),
      );
    }
  }

  ref.onDispose(unsubscribe);
});
