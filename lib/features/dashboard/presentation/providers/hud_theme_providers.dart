import 'package:awaken/core/constants/iap_config.dart';
import 'package:awaken/core/theme/hud_theme.dart';
import 'package:awaken/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:awaken/features/dashboard/presentation/providers/iap_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefKey = 'awaken_selected_hud_theme';

/// Unlocked by streak; acid/mono also require Pro (local stub until RevenueCat).
final unlockedHudThemesProvider = Provider<Set<HudThemeId>>((ref) {
  final stats = ref.watch(dashboardStatsProvider).valueOrNull;
  final streak = stats?.currentStreak ?? 0;
  final isPro = ref.watch(isProEntitledProvider);
  return {
    for (final id in HudThemeId.values)
      if (streak >= id.requiredStreak &&
          (!IapConfig.proHudThemes.contains(id.name) || isPro))
        id,
  };
});

final selectedHudThemeIdProvider =
    StateNotifierProvider<_HudThemeIdNotifier, HudThemeId>(
  (ref) => _HudThemeIdNotifier(ref),
);

class _HudThemeIdNotifier extends StateNotifier<HudThemeId> {
  _HudThemeIdNotifier(this._ref) : super(HudThemeId.cyan) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return;
    final id = HudThemeId.values.where((e) => e.name == raw).firstOrNull;
    if (id != null) {
      state = id;
    }
  }

  Future<void> select(HudThemeId id) async {
    final unlocked = _ref.read(unlockedHudThemesProvider);
    if (!unlocked.contains(id)) return;
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, id.name);
  }
}

final activeHudThemeProvider = Provider<HudTheme>((ref) {
  final id = ref.watch(selectedHudThemeIdProvider);
  final unlocked = ref.watch(unlockedHudThemesProvider);
  final safeId = unlocked.contains(id) ? id : HudThemeId.cyan;
  return HudTheme.forId(safeId);
});
