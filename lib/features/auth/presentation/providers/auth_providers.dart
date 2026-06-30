import 'package:awaken/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:awaken/features/auth/domain/entities/app_user.dart';
import 'package:awaken/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

/// Streams every auth state change from Supabase (sign in / sign out / refresh).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

/// True when a valid Supabase session exists.
final isSignedInProvider = Provider<bool>((ref) {
  return ref
      .watch(authStateProvider)
      .whenData((s) => s.session != null)
      .valueOrNull ?? false;
});

/// The currently signed-in user, or null when not authenticated.
final currentUserProvider = Provider<AppUser?>((ref) {
  // Re-derive any time auth state changes
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).currentUser;
});
