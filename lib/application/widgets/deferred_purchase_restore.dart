import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/payment_provider.dart';
import '../providers/subscription_status_provider.dart';

/// Widget that automatically attempts to restore purchases in the background
/// after payment service is ready. This prevents crashes on cold start.
class DeferredPurchaseRestore extends ConsumerStatefulWidget {
  const DeferredPurchaseRestore({super.key});

  @override
  ConsumerState<DeferredPurchaseRestore> createState() => _DeferredPurchaseRestoreState();
}

class _DeferredPurchaseRestoreState extends ConsumerState<DeferredPurchaseRestore> {
  bool _hasAttemptedRestore = false;

  @override
  void initState() {
    super.initState();
    // Schedule deferred restore after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptDeferredRestore();
    });
  }

  Future<void> _attemptDeferredRestore() async {
    if (_hasAttemptedRestore || !mounted) return;

    try {
      // Wait for payment service to be ready
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      debugPrint('🔄 [DeferredRestore] Checking subscription status...');

      final status = ref.read(subscriptionStatusProvider);

      // Only attempt restore if user is not premium
      if (!status.isPremium) {
        debugPrint('🔄 [DeferredRestore] Not premium, attempting restore...');

        // Check if payment service is available
        final paymentInit = ref.read(paymentInitProvider);
        final isAvailable = paymentInit.maybeWhen(
          data: (available) => available,
          orElse: () => false,
        );

        if (isAvailable) {
          _hasAttemptedRestore = true;

          try {
            await ref.read(purchaseProvider.notifier).restorePurchases();
            debugPrint('✅ [DeferredRestore] Restore completed successfully');

            // Reload subscription status after restore
            await ref.read(subscriptionStatusProvider.notifier).loadSubscriptionStatus();
          } catch (restoreError) {
            debugPrint('⚠️ [DeferredRestore] Restore failed: $restoreError');
            // Not critical - user can manually restore later
          }
        } else {
          debugPrint('⚠️ [DeferredRestore] Payment service not available');
        }
      } else {
        debugPrint('✅ [DeferredRestore] Already premium, no restore needed');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [DeferredRestore] Error: $e');
      debugPrint('   Stack: $stackTrace');
      // Don't crash - just log error
    }
  }

  @override
  Widget build(BuildContext context) {
    // Invisible widget - only used for side effects
    return const SizedBox.shrink();
  }
}
