import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';
import '../providers/statistics_provider.dart';

class FavoriteLocationsCard extends ConsumerWidget {
  const FavoriteLocationsCard({super.key});

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
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.s),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.red[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Text(
                'Lokasi Favorit',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            'Berdasarkan GPS tracking',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          if (stats.favoriteLocations.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: stats.favoriteLocations.asMap().entries.map((entry) {
                final index = entry.key;
                final location = entry.value;
                final isLast = index == stats.favoriteLocations.length - 1;

                return Column(
                  children: [
                    _buildLocationRow(
                      rank: index + 1,
                      location: location.location,
                      count: location.count,
                    ),
                    if (!isLast) const SizedBox(height: AppSpacing.m),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required int rank,
    required String location,
    required int count,
  }) {
    // Different colors for top 3
    final colors = [
      Colors.amber[700]!, // Gold for #1
      Colors.grey[600]!,  // Silver for #2
      Colors.brown[600]!, // Bronze for #3
    ];

    final color = rank <= 3 ? colors[rank - 1] : AppColors.normalHover;

    // Medal icons
    final medals = ['🥇', '🥈', '🥉'];
    final medal = rank <= 3 ? medals[rank - 1] : '📍';

    return Row(
      children: [
        // Medal/rank indicator
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              medal,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        // Location info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$count kunjungan',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
        // Count badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            '$count',
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
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
              Icons.explore_outlined,
              size: 48,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Belum ada lokasi favorit',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral500,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Mulai tracking GPS untuk melihat\nlokasi yang sering dikunjungi',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.neutral400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
