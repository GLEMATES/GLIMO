import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const String monthlyProductId = 'glimo_premium_monthly';
  static const String yearlyProductId = 'glimo_premium_yearly';

  final List<String> _productIds = [
    monthlyProductId,
    yearlyProductId,
  ];

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();

    if (!_isAvailable) {
      debugPrint('In-App Purchase not available');
      return;
    }


    await _loadProducts();

    final purchaseUpdatedStream = _iap.purchaseStream;
    _subscription = purchaseUpdatedStream.listen(
      _onPurchaseUpdate,
      onDone: _onPurchaseDone,
      onError: _onPurchaseError,
    );
  }

  Future<void> _loadProducts() async {
    final ProductDetailsResponse response = await _iap.queryProductDetails(_productIds.toSet());

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }

    if (response.error != null) {
      debugPrint('Error loading products: ${response.error}');
      return;
    }

    _products = response.productDetails;
    debugPrint('Loaded ${_products.length} products');
  }

  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  Future<bool> purchaseSubscription(String productId) async {
    if (!_isAvailable) {
      debugPrint('In-App Purchase not available');
      return false;
    }

    final product = getProduct(productId);
    if (product == null) {
      debugPrint('Product not found: $productId');
      return false;
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );

    try {
      final bool success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      return success;
    } catch (e) {
      debugPrint('Error purchasing: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      debugPrint('In-App Purchase not available');
      return;
    }

    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      await _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      debugPrint('Purchase successful: ${purchaseDetails.productID}');
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      debugPrint('Purchase error: ${purchaseDetails.error}');
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      debugPrint('Purchase canceled');
    }

    if (purchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(purchaseDetails);
    }
  }

  void _onPurchaseDone() {
    debugPrint('Purchase stream done');
  }

  void _onPurchaseError(dynamic error) {
    debugPrint('Purchase stream error: $error');
  }

  String getPrice(String productId) {
    final product = getProduct(productId);
    return product?.price ?? 'N/A';
  }

  void dispose() {
    _subscription?.cancel();
  }
}
