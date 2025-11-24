import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

class PremiumLockDialog {
  static void show(BuildContext context, {required bool canActivateTrial}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.diamond,
                color: AppColors.normalHover,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Fitur Premium',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kelola banyak motor dengan upgrade ke Premium',
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.normalHover,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      'Tambah motor tanpa batas',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/premium');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.normalHover,
                    foregroundColor: AppColors.neutral0,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.xxl),
                    ),
                  ),
                  child: Text(
                    canActivateTrial ? 'Coba Gratis 14 Hari' : 'Upgrade ke Premium',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral0,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Nanti Saja',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}