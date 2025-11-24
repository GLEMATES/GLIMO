import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';
import '../providers/statistics_provider.dart';

class MonthlyStatsCard extends ConsumerWidget {
  const MonthlyStatsCard({super.key});

  void _showDetailedStats(BuildContext context, TripStatistics stats) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.only(
            top: AppSpacing.l,
            left: AppSpacing.l,
            right: AppSpacing.l,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE40000), Color(0xFFB71C1C)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bar_chart,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Statistik',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB71C1C),
                          ),
                        ),
                        Text(
                          _getCurrentMonthYear(),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              _buildDetailRow(
                icon: Icons.directions_bike,
                label: 'Total Perjalanan',
                value: '${stats.monthlyTripCount} trip',
              ),
              const SizedBox(height: AppSpacing.m),
              _buildDetailRow(
                icon: Icons.route,
                label: 'Total Jarak Tempuh',
                value: '${stats.monthlyTotalDistance.toStringAsFixed(2)} km',
              ),
              const SizedBox(height: AppSpacing.m),
              _buildDetailRow(
                icon: Icons.speed,
                label: 'Rata-rata per Trip',
                value: '${stats.monthlyAverageDistance.toStringAsFixed(2)} km',
              ),
              const SizedBox(height: AppSpacing.m),
              _buildDetailRow(
                icon: Icons.access_time,
                label: 'Total Waktu Berkendara',
                value: _formatDurationLong(stats.monthlyTotalDuration),
              ),
              const SizedBox(height: AppSpacing.l),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(bottomSheetContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.normalHover,
                    foregroundColor: AppColors.neutral0,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.xxl),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Tutup',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.neutral0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFCDD2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE40000), Color(0xFFB71C1C)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFFC62828),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB71C1C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral900.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE40000),
                  Color(0xFF860000),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistik Bulan Ini',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _getCurrentMonthYear(),
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Content
          if (stats.monthlyTripCount == 0)
            _buildEmptyState()
          else
            InkWell(
              onTap: () => _showDetailedStats(context, stats),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCompactStatCard(
                        icon: Icons.directions_bike,
                        value: stats.monthlyTripCount.toString(),
                        label: 'Perjalanan',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildCompactStatCard(
                        icon: Icons.route,
                        value: stats.monthlyTotalDistance.toStringAsFixed(0),
                        label: 'Total KM',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildCompactStatCard(
                        icon: Icons.speed,
                        value: stats.monthlyAverageDistance.toStringAsFixed(1),
                        label: 'Rata-rata',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildCompactStatCard(
                        icon: Icons.access_time,
                        value: _formatDurationShort(stats.monthlyTotalDuration),
                        label: 'Waktu',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Compact stat card for 3-column layout
  Widget _buildCompactStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFEBEE),
            Color(0xFFFFCDD2),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE57373),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE57373).withValues(alpha: 0.15),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE40000), Color(0xFFB71C1C)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE40000).withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFB71C1C),
              fontSize: 20,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFFC62828),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFEBEE),
                  const Color(0xFFFFCDD2),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE57373).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.insert_chart_outlined_rounded,
              size: 40,
              color: Color(0xFFE57373),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            'Belum Ada Perjalanan',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFB71C1C),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Mulai perjalanan pertama kamu\nbulan ini dengan GPS tracking',
            style: AppTypography.bodyMedium.copyWith(
              color: const Color(0xFFE57373),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getCurrentMonthYear() {
    final now = DateTime.now();
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  String _formatDurationShort(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).floor();
      return '${minutes}m';
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).floor();
      if (minutes == 0) {
        return '${hours}h';
      }
      return '${hours}h ${minutes}m';
    }
  }

  String _formatDurationLong(int seconds) {
    if (seconds == 0) {
      return '0 menit';
    } else if (seconds < 60) {
      return '$seconds detik';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).floor();
      final secs = seconds % 60;
      if (secs == 0) {
        return '$minutes menit';
      }
      return '$minutes menit $secs detik';
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).floor();
      if (minutes == 0) {
        return '$hours jam';
      }
      return '$hours jam $minutes menit';
    }
  }
}
