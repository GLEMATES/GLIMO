import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

class CancelConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<String> warnings;
  final VoidCallback onConfirm;
  final bool isDanger;

  const CancelConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.warnings,
    required this.onConfirm,
    this.isDanger = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDanger 
                    ? Colors.red.shade50 
                    : Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_rounded,
                size: 48,
                color: isDanger 
                    ? Colors.red.shade600 
                    : Colors.orange.shade600,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.l),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Text(
                        'Yang Akan Terjadi:',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  ...warnings.map((warning) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            warning,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
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
                      child: Text(
                        'Batal',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.normalHover,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: AppColors.neutral0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.xxl),
                        ),
                      ),
                      child: Text(
                        'Ya, Batalkan',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.neutral0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required List<String> warnings,
    required VoidCallback onConfirm,
    bool isDanger = true,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CancelConfirmationDialog(
        title: title,
        message: message,
        warnings: warnings,
        onConfirm: onConfirm,
        isDanger: isDanger,
      ),
    );
  }
}