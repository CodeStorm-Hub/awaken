import 'dart:async';

import 'package:awaken/core/constants/iap_config.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StoreKit / Play Billing Pro entitlement.
///
/// Product IDs must match App Store Connect / Play Console
/// ([IapConfig.productMonthly], [IapConfig.productYearly]). Until those
/// products exist, [purchasePro] returns false and debug builds can still
/// toggle via [setDebugPro].
class ProIapService {
  ProIapService._();

  static final ProIapService instance = ProIapService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _available = false;
  bool _listening = false;

  static const _productIds = <String>{
    IapConfig.productMonthly,
    IapConfig.productYearly,
  };

  Future<bool> get isStoreAvailable async {
    _available = await _iap.isAvailable();
    return _available;
  }

  Future<void> ensureListening(
    void Function(bool entitled) onEntitlement,
  ) async {
    if (_listening) return;
    _listening = true;
    _sub = _iap.purchaseStream.listen(
      (purchases) => _onPurchases(purchases, onEntitlement),
      onDone: () => _listening = false,
      onError: (Object e) {
        debugPrint('[ProIapService] purchaseStream error: $e');
      },
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _listening = false;
  }

  Future<bool> restorePurchases() async {
    if (!await isStoreAvailable) return false;
    await _iap.restorePurchases();
    return true;
  }

  Future<List<ProductDetails>> loadProducts() async {
    if (!await isStoreAvailable) return const [];
    final response = await _iap.queryProductDetails(_productIds);
    if (response.error != null) {
      debugPrint('[ProIapService] query error: ${response.error}');
    }
    return response.productDetails;
  }

  /// Starts a purchase for the first available Pro product (yearly preferred).
  Future<bool> purchasePro() async {
    final products = await loadProducts();
    if (products.isEmpty) return false;
    ProductDetails? yearly;
    ProductDetails? monthly;
    for (final p in products) {
      if (p.id == IapConfig.productYearly) yearly = p;
      if (p.id == IapConfig.productMonthly) monthly = p;
    }
    final target = yearly ?? monthly ?? products.first;
    final param = PurchaseParam(productDetails: target);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<bool> readCachedEntitlement() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(IapConfig.localProPrefKey) ?? false;
  }

  Future<void> _persist(bool entitled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(IapConfig.localProPrefKey, entitled);
  }

  /// Debug / simulator unlock when store products are not configured.
  Future<void> setDebugPro(bool value) async {
    assert(kDebugMode, 'Debug Pro unlock only in debug builds');
    await _persist(value);
  }

  Future<void> _onPurchases(
    List<PurchaseDetails> purchases,
    void Function(bool entitled) onEntitlement,
  ) async {
    var entitled = false;
    for (final purchase in purchases) {
      if (!_productIds.contains(purchase.productID)) continue;
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        entitled = true;
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('[ProIapService] purchase error: ${purchase.error}');
      }
      if (purchase.pendingCompletePurchase &&
          purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        await _iap.completePurchase(purchase);
      }
    }
    if (entitled) {
      await _persist(true);
      onEntitlement(true);
    }
  }
}
