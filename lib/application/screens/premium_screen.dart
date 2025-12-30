import 'dart:io' show Platform;
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
    // Listen to purchase result changes
    ref.listen(lastPurchaseResultProvider, (previous, next) {
      if (next == null) return;

      if (next.startsWith('success:')) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription berhasil diaktifkan!'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      } else if (next.startsWith('error:')) {
        final error = next.substring(6);
        if (!context.mounted) return;
        _showPurchaseErrorDialog(context, 'Error Purchase',
            'Terjadi error: $error\n\nSilakan coba lagi atau hubungi support jika masalah berlanjut.');
      } else if (next == 'canceled') {
        if (!context.mounted) return;
        _showPurchaseErrorDialog(
            context, 'Purchase Dibatalkan', 'Anda membatalkan proses pembayaran.');
      }

      // Reset state
      ref.read(lastPurchaseResultProvider.notifier).clear();
    });

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
          'GLEMO Premium',
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

                  const SizedBox(height: AppSpacing.xl),

                  Center(
                    child: TextButton.icon(
                      onPressed: () => _handleRestorePurchases(context, ref),
                      icon: const Icon(
                        Icons.restore,
                        color: Color(0xFFB71C1C),
                      ),
                      label: Text(
                        'Pulihkan Pembelian',
                        style: AppTypography.bodyLarge.copyWith(
                          color: const Color(0xFFB71C1C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.s),

                  Center(
                    child: Text(
                      'Sudah berlangganan sebelumnya?\nKlik untuk memulihkan pembelian Anda',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.m),

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
    if (Platform.isIOS) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription berhasil diaktifkan!'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
      return;
    }

    final paymentService = ref.read(paymentServiceProvider);

    if (!paymentService.isAvailable) {
      if (!context.mounted) return;
      _showErrorDialog(
        context,
        'In-App Purchase Tidak Tersedia',
        'Google Play Billing tidak tersedia. Pastikan:\n'
        '• Anda menggunakan device fisik (bukan emulator)\n'
        '• Google Play Store terinstall\n'
        '• Anda login dengan Google Account',
      );
      return;
    }

    final product = paymentService.getProduct('glimo_premium_monthly');
    if (product == null) {
      if (!context.mounted) return;
      _showErrorDialog(
        context,
        'Produk Tidak Ditemukan',
        'Produk subscription belum tersedia.\n\n'
        'Kemungkinan:\n'
        '• Produk belum aktif di Play Console\n'
        '• Butuh waktu 2-4 jam setelah setup produk\n'
        '• Coba restart aplikasi',
      );
      return;
    }

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
        if (!context.mounted) return;
        _showLoadingDialog(context);
        await ref.read(purchaseProvider.notifier).activateFreeTrial();
        if (!context.mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Free trial 14 hari berhasil diaktifkan!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context);
        return;
      }
    }

    if (!context.mounted) return;
    _showLoadingDialog(context);

    debugPrint('🔵 [UI] Starting monthly purchase...');
    await ref.read(purchaseProvider.notifier).purchaseMonthly();

    if (!context.mounted) return;
    Navigator.pop(context);

    debugPrint('🔵 [UI] Waiting for purchase result from stream...');
  }

  void _handleYearlyPurchase(BuildContext context, WidgetRef ref) async {
    if (Platform.isIOS) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription berhasil diaktifkan!'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
      return;
    }

    final paymentService = ref.read(paymentServiceProvider);

    if (!paymentService.isAvailable) {
      if (!context.mounted) return;
      _showErrorDialog(
        context,
        'In-App Purchase Tidak Tersedia',
        'Google Play Billing tidak tersedia. Pastikan:\n'
        '• Anda menggunakan device fisik (bukan emulator)\n'
        '• Google Play Store terinstall\n'
        '• Anda login dengan Google Account',
      );
      return;
    }

    final product = paymentService.getProduct('glimo_premium_yearly');
    if (product == null) {
      if (!context.mounted) return;
      _showErrorDialog(
        context,
        'Produk Tidak Ditemukan',
        'Produk subscription belum tersedia.\n\n'
        'Kemungkinan:\n'
        '• Produk belum aktif di Play Console\n'
        '• Butuh waktu 2-4 jam setelah setup produk\n'
        '• Coba restart aplikasi',
      );
      return;
    }

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
        if (!context.mounted) return;
        _showLoadingDialog(context);
        await ref.read(purchaseProvider.notifier).activateFreeTrial();
        if (!context.mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Free trial 14 hari berhasil diaktifkan!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context);
        return;
      }
    }

    if (!context.mounted) return;
    _showLoadingDialog(context);

    debugPrint('🔵 [UI] Starting yearly purchase...');
    await ref.read(purchaseProvider.notifier).purchaseYearly();

    if (!context.mounted) return;
    Navigator.pop(context);

    debugPrint('🔵 [UI] Waiting for purchase result from stream...');
  }

  void _handleRestorePurchases(BuildContext context, WidgetRef ref) async {
    if (Platform.isIOS) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('iOS memiliki akses unlimited secara default'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final paymentService = ref.read(paymentServiceProvider);

    if (!paymentService.isAvailable) {
      if (!context.mounted) return;
      _showErrorDialog(
        context,
        'In-App Purchase Tidak Tersedia',
        'Google Play Billing tidak tersedia. Pastikan:\n'
        '• Anda menggunakan device fisik (bukan emulator)\n'
        '• Google Play Store terinstall\n'
        '• Anda login dengan Google Account',
      );
      return;
    }

    if (!context.mounted) return;
    _showLoadingDialog(context);

    try {
      debugPrint('🔄 [UI] Starting restore purchases...');

      await ref.read(purchaseProvider.notifier).restorePurchases();

      await Future.delayed(const Duration(seconds: 2));

      await ref.read(subscriptionStatusProvider.notifier).loadSubscriptionStatus();

      if (!context.mounted) return;
      Navigator.pop(context);

      final status = ref.read(subscriptionStatusProvider);
      if (status.isPremium) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembelian berhasil dipulihkan! Status premium aktif.'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada pembelian aktif yang ditemukan'),
            backgroundColor: Color(0xFFFFA726),
            duration: Duration(seconds: 3),
          ),
        );
      }

      debugPrint('✅ [UI] Restore purchases completed');
    } catch (e, stackTrace) {
      debugPrint('❌ [UI] Restore purchases error: $e');
      debugPrint('   Stack: $stackTrace');

      if (!context.mounted) return;

      try {
        Navigator.pop(context);
      } catch (navError) {
        debugPrint('⚠️ [UI] Navigator pop error: $navError');
      }

      if (!context.mounted) return;
      _showErrorDialog(
        context,
        'Gagal Memulihkan Pembelian',
        'Terjadi error saat memulihkan pembelian.\n\nSilakan coba lagi atau hubungi support.',
      );
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE40000)),
                ),
                const SizedBox(height: AppSpacing.l),
                Text(
                  'Memproses pembayaran...',
                  style: AppTypography.titleMedium.copyWith(
                    color: const Color(0xFFB71C1C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Mohon tunggu sebentar',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    _showPurchaseErrorDialog(context, title, message);
  }
}

// Helper function untuk error dialog (digunakan dari ref.listen juga)
void _showPurchaseErrorDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral700,
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.normalHover,
              foregroundColor: AppColors.neutral0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ),
      ],
    ),
  );
}
