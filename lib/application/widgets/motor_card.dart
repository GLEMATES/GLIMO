import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

class MotorCard extends StatelessWidget {
  final String model;
  final String type;
  final String odometer;
  final bool isLocked;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MotorCard({
    super.key,
    required this.model,
    required this.type,
    required this.odometer,
    this.isLocked = false,
    this.isActive = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.m),
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: AppColors.neutral0,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? AppColors.normalHover : AppColors.neutral300,
                width: isActive ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive 
                      ? AppColors.normalHover.withValues(alpha: 0.1)
                      : AppColors.neutral900.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isActive 
                        ? AppColors.normalHover.withValues(alpha: 0.1)
                        : AppColors.neutral100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.two_wheeler,
                    color: isActive ? AppColors.normalHover : AppColors.neutral600,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              type,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isActive ? AppColors.normalHover : AppColors.neutral900,
                              ),
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Aktif',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        model,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '$odometer Km',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLocked && onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    onPressed: onDelete,
                  ),
                if (!isLocked)
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.neutral500,
                  ),
              ],
            ),
          ),
          if (isLocked)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.m),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock,
                        color: AppColors.neutral0,
                        size: 48,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        'Fitur Premium',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.neutral0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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