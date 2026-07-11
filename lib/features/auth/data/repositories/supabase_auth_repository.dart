import 'package:awaken/core/services/google_auth_service.dart';
import 'package:awaken/features/auth/domain/entities/app_user.dart';
import 'package:awaken/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase-backed auth repository.
///
/// Email/password flows talk to Supabase directly. Google sign-in uses native
/// [GoogleAuthService] to obtain Google ID tokens, then exchanges them for a
/// Supabase session via [signInWithIdToken]. Supabase owns the session.
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
      final tokens = await GoogleAuthService.signInAndGetGoogleTokens();
      try {
        await _client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: tokens.idToken,
          accessToken: tokens.accessToken,
        );
      } finally {
        // Clear only the ephemeral Google account picker session — never the
        // Supabase session we just created (or any prior email session).
        await GoogleAuthService.signOut();
      }
    } on GoogleSignInCanceledException {
      // Soft cancel — rethrow typed so the UI can dismiss loading without an
      // error banner. Does not touch the Supabase session.
      rethrow;
    } on AuthException catch (e) {
      throw Exception(e.message);
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
    await GoogleAuthService.signOut();
    await _client.auth.signOut();
  }

  static AppUser _toAppUser(User user) => AppUser(
        id: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['full_name'] as String?,
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
      );
}
