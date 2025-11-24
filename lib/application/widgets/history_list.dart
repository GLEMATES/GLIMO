import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';
import '../providers/trip_history_provider.dart';
import 'history_item_card.dart';

class HistoryList extends ConsumerWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTrips = ref.watch(recentTripsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Perjalanan',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                context.go('/riwayat?tab=1');
              },
              child: Text(
                'Lihat Semua',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.darkHover),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        if (recentTrips.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppSpacing.m),
              border: Border.all(
                color: AppColors.neutral200,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.route_outlined,
                  size: 48,
                  color: AppColors.neutral400,
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'Belum ada riwayat perjalanan',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.neutral600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Tambahkan perjalanan di tab Riwayat',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.neutral500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...recentTrips.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final trip = entry.value;
            return HistoryItemCard(
              number: index,
              distance: trip.getFormattedDistance(),
              startKm: trip.startOdometer.toString(),
              endKm: trip.endOdometer.toString(),
              date: trip.getRelativeTime(),
              source: trip.source,
              startLocation: trip.startLocation,
              endLocation: trip.endLocation,
              onDelete: null, // No delete in beranda, only in riwayat tab
            );
          }),
      ],
    );
  }
}