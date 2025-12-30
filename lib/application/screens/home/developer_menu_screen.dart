import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../providers/subscription_status_provider.dart';
import '../../providers/payment_provider.dart';

class DeveloperMenuScreen extends ConsumerStatefulWidget {
  const DeveloperMenuScreen({super.key});

  @override
  ConsumerState<DeveloperMenuScreen> createState() => _DeveloperMenuScreenState();
}

class _DeveloperMenuScreenState extends ConsumerState<DeveloperMenuScreen> {

  @override
  Widget build(BuildContext context) {
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final notifier = ref.read(subscriptionStatusProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '🛠️ Developer Menu',
          style: AppTypography.titleLarge.copyWith(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.greenAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.greenAccent, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        subscriptionStatus.isActive
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: subscriptionStatus.isActive
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Text(
                        'Current Status',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  _buildStatusRow('Plan:', subscriptionStatus.plan),
                  _buildStatusRow(
                    'Is Active:',
                    subscriptionStatus.isActive ? 'YES' : 'NO',
                  ),
                  _buildStatusRow(
                    'Is Trial:',
                    subscriptionStatus.isTrial ? 'YES' : 'NO',
                  ),
                  _buildStatusRow(
                    'Is Premium:',
                    subscriptionStatus.isPremium ? 'YES' : 'NO',
                  ),
                  _buildStatusRow(
                    'Has Used Trial:',
                    subscriptionStatus.hasUsedTrial ? 'YES' : 'NO',
                  ),
                  if (subscriptionStatus.expiryDate != null)
                    _buildStatusRow(
                      'Expiry Date:',
                      _formatDate(subscriptionStatus.expiryDate!),
                    ),
                  if (subscriptionStatus.isActive)
                    _buildStatusRow(
                      'Days Remaining:',
                      notifier.getRemainingDays(),
                    ),
                  if (subscriptionStatus.purchaseDate != null)
                    _buildStatusRow(
                      'Purchase Date:',
                      _formatDate(subscriptionStatus.purchaseDate!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '⚡ Quick Actions',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            _buildActionButton(
              context: context,
              icon: Icons.verified_user,
              label: '⚡ Activate Until 4 Jan 2026',
              color: Colors.purple,
              onPressed: () async {
                try {
                  // Manual activate sampai 4 Jan 2026 (sesuai purchase email)
                  await notifier.activateSubscriptionUntil(
                    plan: 'Monthly Premium (Manual Recovery)',
                    expiryDate: DateTime(2026, 1, 4, 23, 59, 59),
                    productId: 'glimo_premium_monthly_recovered',
                  );
                  if (context.mounted) {
                    _showSnackBar(
                      context,
                      '✅ Activated until 4 Jan 2026!',
                      Colors.greenAccent,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    _showSnackBar(
                      context,
                      '❌ Activation failed: $e',
                      Colors.redAccent,
                    );
                  }
                }
              },
            ),
            const SizedBox(height: AppSpacing.m),
            _buildActionButton(
              context: context,
              icon: Icons.auto_fix_high,
              label: '🔥 Fix Missing Subscription (Force Save)',
              color: Colors.red,
              onPressed: () async {
                try {
                  _showLoadingDialog(context, '🔥 Fixing subscription...');
                  await notifier.activateSubscription(
                    plan: 'Monthly Premium',
                    durationMonths: 1,
                    productId: 'glimo_monthly_premium',
                  );
                  await Future.delayed(const Duration(seconds: 1));
                  await notifier.loadSubscriptionStatus();
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showSnackBar(
                      context,
                      '✅ Subscription FIXED! Restart app to see changes',
                      Colors.greenAccent,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showSnackBar(
                      context,
                      '❌ Fix failed: $e',
                      Colors.redAccent,
                    );
                  }
                }
              },
            ),
            const SizedBox(height: AppSpacing.m),
            _buildActionButton(
              context: context,
              icon: Icons.restore,
              label: '🔄 Restore Purchases',
              color: Colors.green,
              onPressed: () async {
                try {
                  _showLoadingDialog(context, '🔄 Restoring purchases...');
                  await ref.read(purchaseProvider.notifier).restorePurchases();
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    _showSnackBar(
                      context,
                      '✅ Restore completed! Check subscription status',
                      Colors.greenAccent,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    _showSnackBar(
                      context,
                      '❌ Restore failed: $e',
                      Colors.redAccent,
                    );
                  }
                }
              },
            ),
            const SizedBox(height: AppSpacing.m),
            _buildActionButton(
              context: context,
              icon: Icons.science,
              label: 'Activate Free Trial (14 Days)',
              color: Colors.blue,
              onPressed: () async {
                await notifier.activateTrial();
                if (context.mounted) {
                  _showSnackBar(
                    context,
                    '✅ Free Trial Activated (14 days)',
                    Colors.greenAccent,
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.m),
            _buildActionButton(
              context: context,
              icon: Icons.calendar_today,
              label: 'Activate Monthly Premium',
              color: Colors.orange,
              onPressed: () async {
                await notifier.activateSubscription(
                  plan: 'Monthly Premium',
                  durationMonths: 1,
                  productId: 'glimo_premium_monthly',
                );
                if (context.mounted) {
                  _showSnackBar(
                    context,
                    '✅ Monthly Premium Activated',
                    Colors.greenAccent,
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.m),
            _buildActionButton(
              context: context,
              icon: Icons.calendar_month,
              label: 'Activate Yearly Premium',
              color: Colors.purple,
              onPressed: () async {
                await notifier.activateSubscription(
                  plan: 'Yearly Premium',
                  durationMonths: 12,
                  productId: 'glimo_premium_yearly',
                );
                if (context.mounted) {
                  _showSnackBar(
                    context,
                    '✅ Yearly Premium Activated',
                    Colors.greenAccent,
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.m),
            _buildActionButton(
              context: context,
              icon: Icons.delete_forever,
              label: 'Reset to Free',
              color: Colors.red,
              onPressed: () async {
                await notifier.cancelSubscription();
                if (context.mounted) {
                  _showSnackBar(
                    context,
                    '✅ Reset to Free Version',
                    Colors.redAccent,
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: Colors.yellow[900]?.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.yellow),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      'Developer Mode Only\nThese changes are for testing purposes',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.yellow,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.grey[400],
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.m),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.s),
            Text(
              label,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.greenAccent),
            const SizedBox(height: AppSpacing.m),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
