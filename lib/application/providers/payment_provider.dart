import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/payment_service.dart';
import 'subscription_status_provider.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
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
      if (success) {
        await ref.read(subscriptionStatusProvider.notifier).activateSubscription(
          plan: 'Monthly Premium',
          durationMonths: 1,
          productId: PaymentService.monthlyProductId,
        );
      }
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
      if (success) {
        await ref.read(subscriptionStatusProvider.notifier).activateSubscription(
          plan: 'Yearly Premium',
          durationMonths: 12,
          productId: PaymentService.yearlyProductId,
        );
      }
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
      await paymentService.restorePurchases();
      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final purchaseProvider = NotifierProvider<PurchaseNotifier, AsyncValue<bool>>(() {
  return PurchaseNotifier();
});
