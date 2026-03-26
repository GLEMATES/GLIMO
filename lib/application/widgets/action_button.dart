import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const ActionButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.normalHover,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.xxl),
                ),
              ),
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral0,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.normalHover, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.xxl),
                ),
              ),
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.normalHover,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}