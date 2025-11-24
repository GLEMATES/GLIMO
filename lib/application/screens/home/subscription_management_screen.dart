import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../providers/subscription_status_provider.dart';
import '../../widgets/cancel_confirmation_dialog.dart';

class SubscriptionManagementScreen extends ConsumerWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kelola Berlangganan',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.neutral0),
        ),
        backgroundColor: AppColors.normalHover,
        iconTheme: const IconThemeData(color: AppColors.neutral0),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.l),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.normalHover.withValues(alpha: 0.1),
                      AppColors.normalHover.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.normalHover.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.diamond,
                      size: 56,
                      color: AppColors.normalHover,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      subscriptionStatus.plan,
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.normalHover,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Aktif hingga ${_formatDate(subscriptionStatus.expiryDate)}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Sisa ${ref.read(subscriptionStatusProvider.notifier).getRemainingDays()} hari lagi',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Benefit Premium Anda',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              _buildBenefitItem(
                icon: Icons.history,
                title: 'Riwayat Servis Lengkap',
                description: 'Pantau seluruh riwayat perawatan motor',
              ),
              _buildBenefitItem(
                icon: Icons.motorcycle,
                title: 'Kelola Banyak Motor',
                description: 'Manage kondisi semua kendaraan dalam satu akun',
              ),
              _buildBenefitItem(
                icon: Icons.analytics,
                title: 'Analisis Kesehatan Motor',
                description: 'Saran perawatan untuk performa terbaik',
              ),
              const SizedBox(height: AppSpacing.xxl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Text(
                        'Berlangganan akan otomatis diperpanjang. Batalkan kapan saja sebelum tanggal perpanjangan.',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    _showCancelConfirmation(context, ref, subscriptionStatus);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.xxl),
                    ),
                  ),
                  child: Text(
                    'Batalkan Berlangganan',
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
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.l),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.green.shade700,
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
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(
    BuildContext context,
    WidgetRef ref,
    SubscriptionStatus status,
  ) {
    final remainingDays = ref.read(subscriptionStatusProvider.notifier).getRemainingDays();

    CancelConfirmationDialog.show(
      context: context,
      title: 'Batalkan Berlangganan?',
      message: 'Anda akan kehilangan akses ke semua fitur premium.',
      warnings: [
        'Sisa $remainingDays hari berlangganan akan hangus',
        'Semua fitur premium tidak dapat digunakan',
        'Anda dapat berlangganan kembali kapan saja',
      ],
      onConfirm: () async {
        await ref.read(subscriptionStatusProvider.notifier).cancelSubscription();
        if (context.mounted) {
          context.go('/profil');
        }
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }
}