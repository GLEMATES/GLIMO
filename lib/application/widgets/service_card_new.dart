import 'package:flutter/material.dart';
import '../providers/servis_schedule_provider.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

class ServiceCardNew extends StatelessWidget {
  final String component;
  final String note;
  final NextServiceInfo nextServiceInfo;
  final VoidCallback? onPressed;

  const ServiceCardNew({
    super.key,
    required this.component,
    required this.note,
    required this.nextServiceInfo,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDue = nextServiceInfo.isDue();
    final progressPercentage = nextServiceInfo.getProgressPercentage();

    // Determine color based on progress
    Color progressColor;
    String colorName;
    if (progressPercentage >= 99) {
      progressColor = AppColors.error;
      colorName = 'MERAH';
    } else if (progressPercentage >= 75) {
      progressColor = AppColors.warning;
      colorName = 'KUNING';
    } else {
      progressColor = AppColors.success;
      colorName = 'HIJAU';
    }

    debugPrint('🎨 [CARD] $component: $progressPercentage% → $colorName (trigger: ${nextServiceInfo.triggerType})');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(AppSpacing.m),
        border: Border.all(
          color: isDue ? AppColors.error : AppColors.neutral200,
          width: isDue ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral800.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: isDue
                  ? AppColors.error.withValues(alpha: 0.05)
                  : AppColors.normalHover.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.m),
                topRight: Radius.circular(AppSpacing.m),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            component,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (note.isNotEmpty) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.neutral200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                note,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 10,
                                  color: AppColors.neutral600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: nextServiceInfo.nextService.action.contains('Ganti')
                                  ? AppColors.normalHover.withValues(alpha: 0.1)
                                  : Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              nextServiceInfo.nextService.action,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: nextServiceInfo.nextService.action.contains('Ganti')
                                    ? AppColors.normalHover
                                    : Colors.blue,
                              ),
                            ),
                          ),
                          if (isDue) ...[
                            const SizedBox(width: AppSpacing.s),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_rounded,
                                    size: 12,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Waktunya Servis!',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '$progressPercentage%',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ),

          // Progress indicators
          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KM Progress
                Row(
                  children: [
                    Icon(
                      Icons.speed,
                      size: 16,
                      color: (nextServiceInfo.triggerType == 'km' || nextServiceInfo.triggerType == 'both')
                          ? progressColor
                          : AppColors.neutral400,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Kilometer',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: (nextServiceInfo.triggerType == 'km' || nextServiceInfo.triggerType == 'both')
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: (nextServiceInfo.triggerType == 'km' || nextServiceInfo.triggerType == 'both')
                                      ? progressColor
                                      : AppColors.neutral600,
                                ),
                              ),
                              Text(
                                '${nextServiceInfo.currentKm} / ${nextServiceInfo.nextService.km} km',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: (nextServiceInfo.triggerType == 'km' || nextServiceInfo.triggerType == 'both')
                                      ? progressColor
                                      : AppColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: nextServiceInfo.kmProgress,
                              backgroundColor: AppColors.neutral200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                (nextServiceInfo.triggerType == 'km' || nextServiceInfo.triggerType == 'both')
                                    ? progressColor
                                    : AppColors.neutral400,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),

                // Time Progress
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: (nextServiceInfo.triggerType == 'time' || nextServiceInfo.triggerType == 'both')
                          ? progressColor
                          : AppColors.neutral400,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Waktu',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: (nextServiceInfo.triggerType == 'time' || nextServiceInfo.triggerType == 'both')
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: (nextServiceInfo.triggerType == 'time' || nextServiceInfo.triggerType == 'both')
                                      ? progressColor
                                      : AppColors.neutral600,
                                ),
                              ),
                              Text(
                                '${nextServiceInfo.monthsSinceStart} / ${nextServiceInfo.nextService.months} bulan',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: (nextServiceInfo.triggerType == 'time' || nextServiceInfo.triggerType == 'both')
                                      ? progressColor
                                      : AppColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: nextServiceInfo.timeProgress,
                              backgroundColor: AppColors.neutral200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                (nextServiceInfo.triggerType == 'time' || nextServiceInfo.triggerType == 'both')
                                    ? progressColor
                                    : AppColors.neutral400,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Trigger indicator
                if (nextServiceInfo.triggerType != 'both') ...[
                  const SizedBox(height: AppSpacing.m),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.s,
                    ),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.s),
                      border: Border.all(
                        color: progressColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          nextServiceInfo.triggerType == 'km'
                              ? Icons.speed
                              : Icons.calendar_today,
                          size: 14,
                          color: progressColor,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            nextServiceInfo.triggerType == 'km'
                                ? 'Servis lebih dekat berdasarkan Kilometer'
                                : 'Servis lebih dekat berdasarkan Waktu',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: progressColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Button
                const SizedBox(height: AppSpacing.m),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: onPressed != null
                          ? (isDue ? AppColors.error : AppColors.normalHover)
                          : AppColors.neutral200,
                      foregroundColor: AppColors.neutral0,
                      disabledBackgroundColor: AppColors.neutral200,
                      disabledForegroundColor: AppColors.neutral400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.s),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.m,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      onPressed != null
                          ? 'Sudah ${nextServiceInfo.nextService.action}'
                          : 'Belum Waktunya Servis',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: onPressed != null
                            ? AppColors.neutral0  // Putih untuk enabled (merah atau normalHover)
                            : AppColors.neutral900,  // Hitam untuk disabled (abu-abu)
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
}
