import 'package:awaken/features/auth/domain/entities/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  /// Currently authenticated user, or null.
  AppUser? get currentUser;

  /// Stream of auth-state changes (login / logout / token refresh).
  Stream<AuthState> get authStateChanges;

  Future<void> signInWithGoogle();
  Future<void> signOut();
}
