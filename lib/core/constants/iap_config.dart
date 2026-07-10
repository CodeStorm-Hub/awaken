/// Monetization hooks (RevenueCat) — wired in Phase 6.
///
/// Keep product IDs and entitlement names here so UI can gate premium features
/// without scattering string literals.
abstract final class IapConfig {
  static const String entitlementPro = 'awaken_pro';
  static const String productMonthly = 'awaken_pro_monthly';
  static const String productYearly = 'awaken_pro_yearly';

  /// Features reserved for Pro once RevenueCat is integrated.
  static const List<String> proFeatures = [
    'Multi-exercise alarm dismiss',
    'Unlimited territory history',
    'Custom alarm sounds',
    'Friends leaderboard',
  ];
}
