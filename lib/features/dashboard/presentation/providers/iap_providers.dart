import 'package:awaken/features/dashboard/domain/services/pro_iap_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// StateNotifier/StateNotifierProvider moved to legacy.dart in Riverpod 3.
import 'package:flutter_riverpod/legacy.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Pro entitlement from StoreKit / Play Billing (cached in prefs).
final isProEntitledProvider =
    StateNotifierProvider<ProEntitlementNotifier, bool>(
      (ref) => ProEntitlementNotifier(),
    );

final proProductsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  return ProIapService.instance.loadProducts();
});

class ProEntitlementNotifier extends StateNotifier<bool> {
  ProEntitlementNotifier() : super(false) {
    _init();
  }

  Future<void> _init() async {
    state = await ProIapService.instance.readCachedEntitlement();
    await ProIapService.instance.ensureListening((entitled) {
      if (mounted) state = entitled;
    });
  }

  Future<bool> purchasePro() async {
    final started = await ProIapService.instance.purchasePro();
    if (!started && kDebugMode) {
      // Store products not configured yet — allow local unlock in debug.
      await ProIapService.instance.setDebugPro(true);
      state = true;
      return true;
    }
    return started;
  }

  Future<void> restore() async {
    await ProIapService.instance.restorePurchases();
  }

  /// Debug-only toggle (HUD picker / QA).
  Future<void> setPro(bool value) async {
    if (!kDebugMode) return;
    await ProIapService.instance.setDebugPro(value);
    state = value;
  }
}
