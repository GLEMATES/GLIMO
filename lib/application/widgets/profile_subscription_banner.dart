import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';
import '../providers/subscription_status_provider.dart';

class ProfileSubscriptionBanner extends ConsumerWidget {
  const ProfileSubscriptionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final isActive = subscriptionStatus.isActive && 
                     !ref.read(subscriptionStatusProvider.notifier).isSubscriptionExpired();

    return GestureDetector(
      onTap: () {
        context.push('/premium');
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE6F6E6) : const Color(0xFFF6E6E6),
          borderRadius: BorderRadius.circular(AppSpacing.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isActive 
                    ? Colors.green.withValues(alpha: 0.1)
                    : AppColors.normalHover.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.diamond : Icons.diamond_outlined,
                color: isActive ? Colors.green : AppColors.normalHover,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Premium Aktif' : 'Berlangganan',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.neutral900,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive
                        ? 'Berakhir: ${_formatDate(subscriptionStatus.expiryDate)}\nSisa ${ref.read(subscriptionStatusProvider.notifier).getRemainingDays()} hari'
                        : 'Berlangganan untuk mendapatkan Fitur tambahan lebih banyak',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.neutral600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Lihat Detail',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isActive ? Colors.green.shade700 : AppColors.normalHover,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }
}