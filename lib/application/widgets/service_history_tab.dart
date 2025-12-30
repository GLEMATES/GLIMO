import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';
import '../providers/service_history_provider.dart';
import 'service_component_card.dart';

class ServiceHistoryTab extends ConsumerWidget {
  const ServiceHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedComponents = ref.watch(groupedServicesByComponentForActiveMotorProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Info Card
        Container(
          margin: const EdgeInsets.all(AppSpacing.l),
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.normalHover.withValues(alpha: 0.1),
                AppColors.normalHover.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.normalHover.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s),
                decoration: BoxDecoration(
                  color: AppColors.normalHover.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: AppColors.normalHover,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(
                  'Tap komponen untuk lihat timeline lengkap',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.neutral700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Empty State
        if (groupedComponents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon instead of image
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.build_circle_outlined,
                    size: 60,
                    color: AppColors.neutral400,
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                Text(
                  'Belum ada riwayat servis',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.neutral600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(
                    'Riwayat servis motor Anda akan muncul di sini',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          // Component Groups
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.l,
                  right: AppSpacing.l,
                  bottom: AppSpacing.m,
                ),
                child: Row(
                  children: [
                    Text(
                      'Riwayat Per Komponen',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.normalHover.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${groupedComponents.length} komponen',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.normalHover,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...groupedComponents.map((group) {
                return ServiceComponentCard(
                  componentGroup: group,
                  onTap: () {
                    // Navigate to timeline screen
                    context.push('/component-timeline', extra: group.componentName);
                  },
                );
              }),
            ],
          ),
        const SizedBox(height: 100),
      ],
    );
  }
}