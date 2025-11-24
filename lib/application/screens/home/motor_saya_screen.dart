import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/motor_list_provider.dart';
import '../../providers/subscription_status_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../widgets/premium_lock_dialog.dart';

class MotorSayaScreen extends ConsumerWidget {
  const MotorSayaScreen({super.key});

  void _showMotorSwitcher(BuildContext context, WidgetRef ref) {
    final motors = ref.read(motorListProvider);
    final subscriptionStatus = ref.read(subscriptionStatusProvider);
    final isPremium = subscriptionStatus.isActive;
    final canActivateTrial = ref.read(subscriptionStatusProvider.notifier).canActivateTrial();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.neutral0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neutral300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                    child: Text(
                      'Pilih Motor Aktif',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  const Divider(height: 1),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: motors.length,
                    itemBuilder: (context, index) {
                    final motor = motors[index];
                    final isLocked = !isPremium && index > 0;

                    return ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: motor.isActive
                              ? AppColors.normalHover.withValues(alpha: 0.1)
                              : AppColors.neutral100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.two_wheeler,
                          color: motor.isActive ? AppColors.normalHover : AppColors.neutral600,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        motor.type,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: motor.isActive ? AppColors.normalHover : AppColors.neutral900,
                        ),
                      ),
                      subtitle: Text(
                        '${motor.model} • ${motor.odometer} Km',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                      trailing: motor.isActive
                          ? Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 24,
                            )
                          : isLocked
                              ? Icon(
                                  Icons.lock,
                                  color: AppColors.neutral400,
                                  size: 24,
                                )
                              : null,
                      onTap: isLocked
                          ? null
                          : () async {
                              if (!motor.isActive) {
                                Navigator.pop(context);
                                await ref.read(motorListProvider.notifier).setActiveMotor(motor.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Motor aktif berubah ke ${motor.type}',
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.neutral0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      backgroundColor: AppColors.normalHover,
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.all(AppSpacing.m),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppSpacing.m),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.normalHover.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.add,
                      color: AppColors.normalHover,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    'Tambah Motor Baru',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.normalHover,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (isPremium || motors.isEmpty) {
                      context.push('/motor-details?from=motor-saya');
                    } else {
                      PremiumLockDialog.show(context, canActivateTrial: canActivateTrial);
                    }
                  },
                ),
              ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, String motorId, String motorName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Hapus Motor?',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Yakin ingin menghapus motor "$motorName"?',
            style: AppTypography.bodyLarge,
          ),
          actionsPadding: const EdgeInsets.only(bottom: AppSpacing.l, right: AppSpacing.l),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.m),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  ),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: AppSpacing.m),
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(motorListProvider.notifier).deleteMotor(motorId);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Motor berhasil dihapus',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.neutral0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: AppColors.normalHover,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(AppSpacing.m),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.m),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.normalHover,
                    foregroundColor: AppColors.neutral0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.m),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  ),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motors = ref.watch(motorListProvider);
    final activeMotor = ref.read(motorListProvider.notifier).getActiveMotor();
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final isPremium = subscriptionStatus.isActive;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Motor Saya',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.neutral0),
        ),
        backgroundColor: AppColors.normalHover,
        iconTheme: const IconThemeData(color: AppColors.neutral0),
      ),
      backgroundColor: AppColors.normalHover,
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: motors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.two_wheeler_outlined,
                            size: 80,
                            color: AppColors.neutral400,
                          ),
                          const SizedBox(height: AppSpacing.l),
                          Text(
                            'Belum ada motor terdaftar',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.neutral600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Text(
                            'Tambahkan motor pertama Anda',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Motor Aktif Saat Ini',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neutral900,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showMotorSwitcher(context, ref),
                                child: Icon(
                                  Icons.swap_horiz,
                                  size: 28,
                                  color: AppColors.normalHover,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),
                          GestureDetector(
                            onTap: () {
                              if (activeMotor != null) {
                                context.push('/motor-details?from=motor-saya&motorId=${activeMotor.id}');
                              }
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.l),
                                  decoration: BoxDecoration(
                                    color: AppColors.neutral0,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.normalHover,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.normalHover.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: AppColors.normalHover.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.two_wheeler,
                                          color: AppColors.normalHover,
                                          size: 40,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.m),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              activeMotor?.type ?? 'Motor',
                                              style: AppTypography.titleLarge.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.normalHover,
                                              ),
                                            ),
                                            const SizedBox(height: AppSpacing.xs),
                                            Text(
                                              activeMotor?.model ?? '-',
                                              style: AppTypography.bodyLarge.copyWith(
                                                color: AppColors.neutral600,
                                              ),
                                            ),
                                            const SizedBox(height: AppSpacing.xs),
                                            Text(
                                              '${activeMotor?.odometer ?? '0'} Km',
                                              style: AppTypography.bodyMedium.copyWith(
                                                color: AppColors.neutral500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (motors.length > 1)
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: AppColors.error,
                                          ),
                                          onPressed: () {
                                            if (activeMotor != null) {
                                              _showDeleteConfirmationDialog(
                                                context,
                                                ref,
                                                activeMotor.id,
                                                activeMotor.type,
                                              );
                                            }
                                          },
                                        ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: AppColors.neutral500,
                                        size: 32,
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.s,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: AppColors.success,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Aktif',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (motors.length > 1 && isPremium) ...[
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'Semua Motor (${motors.length})',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.neutral700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.m),
                            Text(
                              'Ketuk motor aktif untuk mengganti motor',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.neutral500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}