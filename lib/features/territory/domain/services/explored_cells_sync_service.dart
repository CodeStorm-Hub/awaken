import 'package:awaken/features/territory/data/datasources/explored_cells_store.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Syncs local fog cells to Supabase and merges remote cells on sign-in.
abstract final class ExploredCellsSyncService {
  static Future<void> push(ExploredCellsStore store) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || store.isEmpty) return;
    try {
      await Supabase.instance.client.rpc<void>(
        'upsert_explored_cells',
        params: {'p_cells': store.cells.toList()},
      );
    } catch (e) {
      debugPrint('[ExploredCellsSync] push failed: $e');
    }
  }

  static Future<void> pullInto(ExploredCellsStore store) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final row = await Supabase.instance.client
          .from('explored_cells')
          .select('cells')
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return;
      final cells = (row['cells'] as List<dynamic>?)?.cast<String>() ?? [];
      if (cells.isEmpty) return;
      // Re-reveal via path of cell centers is heavy; merge keys directly.
      await store.mergeRemoteCells(cells);
    } catch (e) {
      debugPrint('[ExploredCellsSync] pull failed: $e');
    }
  }
}
