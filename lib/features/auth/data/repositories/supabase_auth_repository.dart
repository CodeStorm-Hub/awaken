import 'dart:io';

import 'package:awaken/core/constants/supabase_config.dart';
import 'package:awaken/features/auth/domain/entities/app_user.dart';
import 'package:awaken/features/auth/domain/repositories/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository()
      : _googleSignIn = GoogleSignIn(
          clientId: Platform.isIOS ? SupabaseConfig.googleIosClientId : null,
          serverClientId: SupabaseConfig.googleWebClientId,
          scopes: ['email', 'profile'],
        );

  final SupabaseClient _client = Supabase.instance.client;
  final GoogleSignIn _googleSignIn;

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
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) throw Exception('No ID token from Google');

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _client.auth.signOut();
  }

  static AppUser _toAppUser(User user) => AppUser(
        id: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['full_name'] as String?,
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
      );
}
