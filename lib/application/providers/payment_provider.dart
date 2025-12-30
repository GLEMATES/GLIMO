import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../services/payment_service.dart';
import 'subscription_status_provider.dart';

// Notifier untuk track last purchase result
class LastPurchaseResultNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setResult(String result) {
    state = result;
  }

  void clear() {
    state = null;
  }
}

final lastPurchaseResultProvider = NotifierProvider<LastPurchaseResultNotifier, String?>(() {
  return LastPurchaseResultNotifier();
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  final service = PaymentService();

  service.onPurchaseSuccess = (purchaseDetails) async {
    try {
      String plan;
      DateTime? expiryDate;

      if (purchaseDetails.productID == PaymentService.monthlyProductId) {
        plan = 'Monthly Premium';
      } else if (purchaseDetails.productID == PaymentService.yearlyProductId) {
        plan = 'Yearly Premium';
      } else {
        if (kDebugMode) debugPrint('⚠️ [Provider] Unknown product ID: ${purchaseDetails.productID}');
        try {
          ref.read(lastPurchaseResultProvider.notifier).setResult('error:Unknown product');
        } catch (e) {
          if (kDebugMode) debugPrint('❌ [Provider] Failed to set result: $e');
        }
        return;
      }

      if (Platform.isAndroid) {
        if (purchaseDetails is GooglePlayPurchaseDetails) {
          try {
            final billingClientPurchase = purchaseDetails.billingClientPurchase;
            final originalJson = jsonDecode(billingClientPurchase.originalJson);

            final expiryTimeMillis = originalJson['expiryTimeMillis'];
            final purchaseTimeMillis = originalJson['purchaseTime'];

            if (expiryTimeMillis != null) {
              expiryDate = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryTimeMillis.toString()));
            } else if (purchaseTimeMillis != null) {
              final purchaseTime = DateTime.fromMillisecondsSinceEpoch(int.parse(purchaseTimeMillis.toString()));
              final durationMonths = purchaseDetails.productID == PaymentService.monthlyProductId ? 1 : 12;
              expiryDate = DateTime(
                purchaseTime.year,
                purchaseTime.month + durationMonths,
                purchaseTime.day,
                purchaseTime.hour,
                purchaseTime.minute,
                purchaseTime.second,
              );
            }
          } catch (e, stackTrace) {
            if (kDebugMode) {
              debugPrint('⚠️ [Provider] Error parsing expiry date: $e');
              debugPrint('   Stack: $stackTrace');
            }
          }
        }
      }

      // Update subscription status in Firestore
      try {
        // Add timeout to prevent hanging
        if (expiryDate != null) {
          await ref.read(subscriptionStatusProvider.notifier).activateSubscriptionUntil(
            plan: plan,
            expiryDate: expiryDate,
            productId: purchaseDetails.productID,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Firestore save timeout after 30 seconds');
            },
          );
        } else {
          final durationMonths = purchaseDetails.productID == PaymentService.monthlyProductId ? 1 : 12;
          await ref.read(subscriptionStatusProvider.notifier).activateSubscription(
            plan: plan,
            durationMonths: durationMonths,
            productId: purchaseDetails.productID,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Firestore save timeout after 30 seconds');
            },
          );
        }

        try {
          ref.read(lastPurchaseResultProvider.notifier).setResult('success:${purchaseDetails.productID}');
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ [Provider] Failed to set success result: $e');
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('❌ [Provider] Failed to activate subscription!');
          debugPrint('   Error: $e');
          debugPrint('   Stack trace: $stackTrace');
        }
        try {
          ref.read(lastPurchaseResultProvider.notifier).setResult('error:Failed to activate subscription: $e');
        } catch (resultError) {
          if (kDebugMode) debugPrint('❌ [Provider] Failed to set error result: $resultError');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [Provider] Error in purchase success callback: $e');
        debugPrint('   Stack: $stackTrace');
      }
    }
  };

  service.onPurchaseError = (error) {
    try {
      try {
        ref.read(lastPurchaseResultProvider.notifier).setResult('error:$error');
      } catch (e) {
        if (kDebugMode) debugPrint('❌ [Provider] Failed to set error result: $e');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [Provider] Error in purchase error callback: $e');
        debugPrint('   Stack: $stackTrace');
      }
    }
  };

  service.onPurchaseCanceled = () {
    try {
      try {
        ref.read(lastPurchaseResultProvider.notifier).setResult('canceled');
      } catch (e) {
        if (kDebugMode) debugPrint('❌ [Provider] Failed to set canceled result: $e');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [Provider] Error in purchase canceled callback: $e');
        debugPrint('   Stack: $stackTrace');
      }
    }
  };

  return service;
});

final paymentInitProvider = FutureProvider<bool>((ref) async {
  final paymentService = ref.watch(paymentServiceProvider);
  await paymentService.initialize();
  return paymentService.isAvailable;
});

final productsProvider = Provider<List<ProductDetails>>((ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.products;
});

class PurchaseNotifier extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() {
    return const AsyncValue.data(false);
  }

  Future<void> purchaseMonthly() async {
    state = const AsyncValue.loading();
    try {
      final paymentService = ref.read(paymentServiceProvider);
      final success = await paymentService.purchaseSubscription(
        PaymentService.monthlyProductId,
      );
      // Note: activateSubscription is now handled by purchase stream callback
      // in paymentServiceProvider
      state = AsyncValue.data(success);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> purchaseYearly() async {
    state = const AsyncValue.loading();
    try {
      final paymentService = ref.read(paymentServiceProvider);
      final success = await paymentService.purchaseSubscription(
        PaymentService.yearlyProductId,
      );
      // Note: activateSubscription is now handled by purchase stream callback
      // in paymentServiceProvider
      state = AsyncValue.data(success);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> activateFreeTrial() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(subscriptionStatusProvider.notifier).activateTrial();
      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> restorePurchases() async {
    state = const AsyncValue.loading();
    try {
      final paymentService = ref.read(paymentServiceProvider);
      final purchases = await paymentService.restorePurchases();

      if (purchases.isEmpty) {
        state = const AsyncValue.data(false);
        return;
      }

      for (var purchase in purchases) {
        if (paymentService.onPurchaseSuccess != null) {
          await paymentService.onPurchaseSuccess!(purchase);
        }
      }

      state = const AsyncValue.data(true);
    } catch (e, st) {
      if (kDebugMode) debugPrint('❌ [Provider] Error in restorePurchases: $e');
      state = AsyncValue.error(e, st);
    }
  }
}

final purchaseProvider = NotifierProvider<PurchaseNotifier, AsyncValue<bool>>(() {
  return PurchaseNotifier();
});
