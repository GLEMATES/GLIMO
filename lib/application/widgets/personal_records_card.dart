import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';
import '../providers/statistics_provider.dart';
import '../providers/trip_history_provider.dart';

class PersonalRecordsCard extends ConsumerWidget {
  const PersonalRecordsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(AppSpacing.l),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral900.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.s),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.amber[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Text(
                'Rekor Pribadi',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          if (stats.longestTrip == null)
            _buildEmptyState()
          else
            Column(
              children: [
                if (stats.longestTrip != null)
                  _buildRecordRow(
                    icon: Icons.trending_up,
                    medal: '🥇',
                    label: 'Trip Terpanjang',
                    value: '${stats.longestTrip!.distance.toStringAsFixed(1)} km',
                    subtitle: stats.longestTrip!.motorName,
                    color: Colors.blue,
                  ),
                if (stats.fastestTrip != null &&
                    stats.fastestTrip!.duration != null &&
                    stats.fastestTrip!.duration! > 0) ...[
                  const SizedBox(height: AppSpacing.m),
                  _buildRecordRow(
                    icon: Icons.speed,
                    medal: '🥈',
                    label: 'Kecepatan Rata-rata Tertinggi',
                    value: '${_calculateAverageSpeed(stats.fastestTrip!)} km/h',
                    subtitle: stats.fastestTrip!.motorName,
                    color: Colors.orange,
                  ),
                ],
                if (stats.mostActiveDay != null) ...[
                  const SizedBox(height: AppSpacing.m),
                  _buildRecordRow(
                    icon: Icons.calendar_today,
                    medal: '🥉',
                    label: 'Hari Teraktif',
                    value: '${stats.mostActiveDay} (${stats.mostActiveDayCount}x)',
                    subtitle: 'Total perjalanan di hari ${stats.mostActiveDay}',
                    color: Colors.green,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRecordRow({
    required IconData icon,
    required String medal,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Medal emoji
        Text(
          medal,
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(width: AppSpacing.m),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.neutral500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Belum ada rekor perjalanan',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAverageSpeed(TripHistory trip) {
    if (trip.duration == null || trip.duration == 0) return 0;
    return trip.distance / (trip.duration! / 3600.0);
  }
}
