import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const String monthlyProductId = 'glimo_premium_monthly';
  static const String yearlyProductId = 'glimo_premium_yearly';

  // Demo mode untuk testing/presentasi tanpa Google Play setup
  static const bool _demoMode = false; // Set false saat production

  final List<String> _productIds = [
    monthlyProductId,
    yearlyProductId,
  ];

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  Future<void> initialize() async {
    try {
      _isAvailable = await _iap.isAvailable();

      if (!_isAvailable) {
        if (kDebugMode) debugPrint('⚠️ [Payment] In-App Purchase not available');
        return;
      }

      await _loadProducts();

      final purchaseUpdatedStream = _iap.purchaseStream;
      _subscription = purchaseUpdatedStream.listen(
        _onPurchaseUpdate,
        onDone: _onPurchaseDone,
        onError: _onPurchaseError,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Payment] Error initializing: $e');
      _isAvailable = false;
    }
  }

  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(_productIds.toSet());

      if (response.notFoundIDs.isNotEmpty && kDebugMode) {
        debugPrint('⚠️ [Payment] Products not found: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        if (kDebugMode) debugPrint('❌ [Payment] Error loading products: ${response.error}');
        return;
      }

      _products = response.productDetails;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Payment] Error in _loadProducts: $e');
      _products = [];
    }
  }

  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  Future<bool> purchaseSubscription(String productId) async {
    // Demo mode: bypass Google Play untuk testing/presentasi
    if (_demoMode) {
      if (kDebugMode) debugPrint('🎮 DEMO MODE: Simulating purchase for $productId');
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }

    if (!_isAvailable) {
      if (kDebugMode) debugPrint('❌ [Payment] In-App Purchase not available');
      return false;
    }

    final product = getProduct(productId);
    if (product == null) {
      if (kDebugMode) debugPrint('❌ [Payment] Product not found: $productId');
      return false;
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );

    try {
      final bool success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      return success;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Payment] Error purchasing: $e');
      return false;
    }
  }

  Future<List<PurchaseDetails>> restorePurchases() async {
    if (!_isAvailable) {
      throw Exception('In-App Purchase not available');
    }

    try {
      if (Platform.isAndroid) {
        final androidAddition = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        final response = await androidAddition.queryPastPurchases();

        final activePurchases = <PurchaseDetails>[];

        for (var purchase in response.pastPurchases) {
          if (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored) {
            activePurchases.add(purchase);
          }
        }

        return activePurchases;
      } else {
        await _iap.restorePurchases();
        return [];
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [Payment] Error restoring purchases: $e');
        debugPrint('   Stack: $stackTrace');
      }
      rethrow;
    }
  }

  // Callback untuk status purchase
  Function(PurchaseDetails)? onPurchaseSuccess;
  Function(String)? onPurchaseError;
  Function()? onPurchaseCanceled;

  // Track completed purchases to prevent duplicate processing
  final Set<String> _completedPurchaseIds = <String>{};

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      await _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    final purchaseId = purchaseDetails.purchaseID ?? purchaseDetails.productID;

    try {
      // Skip if already processed to prevent duplicate callbacks
      if (_completedPurchaseIds.contains(purchaseId)) {
        return;
      }

      if (purchaseDetails.status == PurchaseStatus.pending) {
        return;
      }

      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Complete purchase BEFORE calling success callback
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }

        _completedPurchaseIds.add(purchaseId);
        onPurchaseSuccess?.call(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        final errorMessage = purchaseDetails.error?.message ?? 'Unknown error';

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }

        _completedPurchaseIds.add(purchaseId);
        onPurchaseError?.call(errorMessage);
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }

        _completedPurchaseIds.add(purchaseId);
        onPurchaseCanceled?.call();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Payment] Error in _handlePurchase: $e');
      _completedPurchaseIds.add(purchaseId);

      if (purchaseDetails.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(purchaseDetails);
        } catch (completeError) {
          if (kDebugMode) debugPrint('❌ [Payment] Error completing purchase: $completeError');
        }
      }
    }
  }

  void _onPurchaseDone() {
    if (kDebugMode) debugPrint('Purchase stream done');
  }

  void _onPurchaseError(dynamic error) {
    if (kDebugMode) debugPrint('Purchase stream error: $error');
  }

  String getPrice(String productId) {
    // Demo mode: return mock prices
    if (_demoMode) {
      if (productId == monthlyProductId) return 'Rp 25.000';
      if (productId == yearlyProductId) return 'Rp 215.000';
    }

    final product = getProduct(productId);
    return product?.price ?? 'N/A';
  }

  bool get isDemoMode => _demoMode;

  void dispose() {
    _subscription?.cancel();
  }
}
