import 'package:awaken/core/services/firebase_google_auth_service.dart';
import 'package:awaken/features/auth/domain/entities/app_user.dart';
import 'package:awaken/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase-backed auth repository.
///
/// Email/password flows talk to Supabase directly. Google sign-in uses
/// **Firebase Auth only** as the OAuth broker: Firebase returns Google ID
/// tokens, which are exchanged for a Supabase session via [signInWithIdToken].
/// Firebase is signed out immediately afterward — Supabase owns the session.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository();

  final SupabaseClient _client = Supabase.instance.client;

  @override
  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _toAppUser(user);
  }

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<void> signInWithGoogle() async {
    try {
      final tokens = await FirebaseGoogleAuthService.signInAndGetGoogleTokens();
      try {
        await _client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: tokens.idToken,
          accessToken: tokens.accessToken,
        );
      } finally {
        // Supabase session is authoritative — do not keep a Firebase session.
        await FirebaseGoogleAuthService.signOut();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'cancelled-popup-request' ||
          e.code == 'web-context-cancelled') {
        throw Exception('Google sign-in cancelled');
      }
      throw Exception(e.message ?? 'Google sign-in failed');
    }
  }

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signUpWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'full_name': displayName} : null,
    );
  }

  @override
  Future<void> signOut() async {
    await FirebaseGoogleAuthService.signOut();
    await _client.auth.signOut();
  }

  static AppUser _toAppUser(User user) => AppUser(
        id: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['full_name'] as String?,
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
      );
}
