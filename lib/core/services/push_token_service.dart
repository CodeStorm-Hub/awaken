import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registers device push tokens in `push_tokens` for FCM (or a stable local
/// fallback id when FCM is unavailable).
abstract final class PushTokenService {
  static const _prefKey = 'awaken_device_push_id';

  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final id = _generateId();
    await prefs.setString(_prefKey, id);
    return id;
  }

  /// Upserts an explicit FCM token (preferred) for the signed-in user.
  static Future<void> registerToken(String token) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null || token.isEmpty) return;

    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await client.from('push_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': platform,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,token',
      );
    } catch (e) {
      debugPrint('[PushTokenService] FCM upsert failed: $e');
    }
  }

  /// Fallback registration using a stable local device id.
  static Future<void> registerForCurrentUser() async {
    final token = await getOrCreateDeviceId();
    await registerToken(token);
  }

  static String _generateId() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
