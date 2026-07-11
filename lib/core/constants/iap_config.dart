/// Monetization — StoreKit / Play Billing via `in_app_purchase`.
///
/// Create matching products in App Store Connect / Play Console:
/// - [productMonthly]
/// - [productYearly]
/// Entitlement is cached locally under [localProPrefKey] after a successful
/// purchase or restore. Debug builds can unlock without a store.
abstract final class IapConfig {
  static const String entitlementPro = 'awaken_pro';
  static const String productMonthly = 'awaken_pro_monthly';
  static const String productYearly = 'awaken_pro_yearly';
  static const String localProPrefKey = 'awaken_pro_unlocked';

  static const List<String> proFeatures = [
    'Multi-exercise alarm dismiss',
    'Unlimited territory history',
    'Custom alarm sounds',
    'Friends leaderboard',
    'Extra HUD themes (acid / mono)',
  ];

  /// Themes that require Pro in addition to streak unlock.
  static const Set<String> proHudThemes = {'acid', 'mono'};
}
