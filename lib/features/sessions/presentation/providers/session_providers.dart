import 'package:awaken/features/sessions/data/repositories/composite_session_repository.dart';
import 'package:awaken/features/sessions/data/repositories/local_session_repository.dart';
import 'package:awaken/features/sessions/data/repositories/supabase_session_repository.dart';
import 'package:awaken/features/sessions/domain/repositories/session_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return const CompositeSessionRepository(
    remote: SupabaseSessionRepository(),
    local: LocalSessionRepository(),
  );
});
