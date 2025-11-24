import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';
import '../providers/subscription_status_provider.dart';
import '../providers/payment_provider.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFFB71C1C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'GLIMO Premium',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB71C1C),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE40000), Color(0xFF860000)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    'Upgrade ke Premium',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Kelola semua motor tanpa batas',
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Benefit Premium',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB71C1C),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  _buildFeatureItem(
                    icon: Icons.directions_bike,
                    title: 'Unlimited Motor',
                    description: 'Tambahkan dan kelola motor sebanyak yang kamu mau',
                    isPremium: true,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  _buildFeatureItem(
                    icon: Icons.history,
                    title: 'Riwayat Unlimited',
                    description: 'Akses semua riwayat perjalanan tanpa batas waktu',
                    isPremium: true,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  _buildFeatureItem(
                    icon: Icons.bar_chart,
                    title: 'Statistik Lengkap',
                    description: 'Analisa perjalanan dengan data yang lebih detail',
                    isPremium: true,
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Pilih Paket',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB71C1C),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  _buildPlanCard(
                    context: context,
                    ref: ref,
                    title: 'Bulanan',
                    price: 'Rp 25.000',
                    period: '/bulan',
                    features: [
                      'Unlimited motor',
                      'Unlimited riwayat',
                      'Statistik lengkap',
                      'Free trial 14 hari',
                    ],
                    isPopular: false,
                    onTap: () => _handleMonthlyPurchase(context, ref),
                  ),

                  const SizedBox(height: AppSpacing.m),

                  _buildPlanCard(
                    context: context,
                    ref: ref,
                    title: 'Tahunan',
                    price: 'Rp 215.000',
                    period: '/tahun',
                    savings: 'Hemat Rp 85.000',
                    features: [
                      'Semua benefit bulanan',
                      'Hemat 28%',
                      'Free trial 14 hari',
                    ],
                    isPopular: true,
                    onTap: () => _handleYearlyPurchase(context, ref),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isPremium,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE40000), Color(0xFFB71C1C)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFB71C1C),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String price,
    required String period,
    String? savings,
    required List<String> features,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? const Color(0xFFE40000) : const Color(0xFFFFCDD2),
          width: isPopular ? 2 : 1,
        ),
        color: Colors.white,
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: const Color(0xFFE40000).withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE40000), Color(0xFFB71C1C)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Text(
                'PALING POPULER',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFB71C1C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                price,
                                style: AppTypography.headlineSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFE40000),
                                ),
                              ),
                              Text(
                                period,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                          if (savings != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                savings,
                                style: AppTypography.labelSmall.copyWith(
                                  color: const Color(0xFFE40000),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.neutral800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: AppSpacing.m),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.normalHover,
                      foregroundColor: AppColors.neutral0,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.m,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.xxl),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Pilih Paket Ini',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.neutral0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMonthlyPurchase(BuildContext context, WidgetRef ref) async {
    final canActivateTrial = ref.read(subscriptionStatusProvider.notifier).canActivateTrial();

    if (canActivateTrial) {
      final shouldActivateTrial = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Free Trial 14 Hari'),
          content: const Text(
            'Kamu bisa coba gratis 14 hari dulu sebelum subscribe. Mau aktivasi free trial?',
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.l),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.normalHover,
                      foregroundColor: AppColors.neutral0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.xxl),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Aktivasi Free Trial'),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.normalHover,
                      side: BorderSide(
                        color: AppColors.normalHover,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.xxl),
                      ),
                    ),
                    child: const Text('Langsung Subscribe'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      if (shouldActivateTrial == true) {
        await ref.read(purchaseProvider.notifier).activateFreeTrial();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Free trial 14 hari berhasil diaktifkan!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }
    }

    await ref.read(purchaseProvider.notifier).purchaseMonthly();

    if (context.mounted) {
      final purchaseState = ref.read(purchaseProvider);
      purchaseState.when(
        data: (success) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription berhasil diaktifkan!'),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
            Navigator.pop(context);
          }
        },
        loading: () {},
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    }
  }

  void _handleYearlyPurchase(BuildContext context, WidgetRef ref) async {
    final canActivateTrial = ref.read(subscriptionStatusProvider.notifier).canActivateTrial();

    if (canActivateTrial) {
      final shouldActivateTrial = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Free Trial 14 Hari'),
          content: const Text(
            'Kamu bisa coba gratis 14 hari dulu sebelum subscribe. Mau aktivasi free trial?',
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.l),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.normalHover,
                      foregroundColor: AppColors.neutral0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.xxl),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Aktivasi Free Trial'),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.normalHover,
                      side: BorderSide(
                        color: AppColors.normalHover,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.xxl),
                      ),
                    ),
                    child: const Text('Langsung Subscribe'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      if (shouldActivateTrial == true) {
        await ref.read(purchaseProvider.notifier).activateFreeTrial();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Free trial 14 hari berhasil diaktifkan!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }
    }

    await ref.read(purchaseProvider.notifier).purchaseYearly();

    if (context.mounted) {
      final purchaseState = ref.read(purchaseProvider);
      purchaseState.when(
        data: (success) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription berhasil diaktifkan!'),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
            Navigator.pop(context);
          }
        },
        loading: () {},
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    }
  }
}
