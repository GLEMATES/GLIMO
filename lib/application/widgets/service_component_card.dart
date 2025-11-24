import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';
import '../providers/service_history_provider.dart';

class ServiceComponentCard extends StatelessWidget {
  final ComponentServiceGroup componentGroup;
  final VoidCallback? onTap;

  const ServiceComponentCard({
    super.key,
    required this.componentGroup,
    this.onTap,
  });

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: AppSpacing.m,
          left: AppSpacing.l,
          right: AppSpacing.l,
        ),
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppColors.neutral0,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.neutral200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neutral900.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Component Name
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.normalHover.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.build_circle,
                    color: AppColors.normalHover,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        componentGroup.componentName,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${componentGroup.getTotalServices()}x servis',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.neutral400,
                  size: 24,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.m),

            // Divider
            Container(
              height: 1,
              color: AppColors.neutral200,
            ),

            const SizedBox(height: AppSpacing.m),

            // Last Ganti
            if (componentGroup.lastGanti != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.normalHover.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'GANTI',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.normalHover,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      'Terakhir: ${_formatDate(componentGroup.lastGanti!.date)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(width: 54), // Offset untuk alignment
                  Icon(
                    Icons.speed,
                    size: 14,
                    color: AppColors.neutral600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${componentGroup.lastGanti!.odometer} km',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.neutral600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          componentGroup.lastGanti!.getRelativeTime(),
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppColors.neutral700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
            ],

            // Last Periksa
            if (componentGroup.lastPeriksa != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PERIKSA',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      'Terakhir: ${_formatDate(componentGroup.lastPeriksa!.date)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(width: 64), // Offset untuk alignment
                  Icon(
                    Icons.speed,
                    size: 14,
                    color: AppColors.neutral600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${componentGroup.lastPeriksa!.odometer} km',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.neutral600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          componentGroup.lastPeriksa!.getRelativeTime(),
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppColors.neutral700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Summary
            const SizedBox(height: AppSpacing.m),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 16,
                    color: AppColors.neutral700,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      'Total: ${componentGroup.totalGanti}x Ganti, ${componentGroup.totalPeriksa}x Periksa',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral700,
                        fontWeight: FontWeight.w500,
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
}
