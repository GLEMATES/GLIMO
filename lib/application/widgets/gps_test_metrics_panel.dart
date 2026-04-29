import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gps_tracking_provider.dart';
import '../services/tracking_metrics_service.dart';
import '../models/gps_quality_metrics.dart';
import '../themes/app_colors.dart';
import '../themes/app_typography.dart';

class GPSTestMetricsPanel extends ConsumerWidget {
  const GPSTestMetricsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(gpsTrackingProvider);
    final metrics = ref.read(gpsTrackingProvider.notifier).getSessionMetrics();

    if (trackingState.status == TrackingStatus.idle || metrics == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.normal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GPS Test Metrics',
                style: AppTypography.titleLarge.copyWith(color: AppColors.normal),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _exportMetrics(context, metrics),
                tooltip: 'Export Data',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildMetricRow('Method', 'Haversine'),
          _buildMetricRow('GPS Points', '${metrics.totalGPSPoints}'),
          _buildMetricRow('Distance', '${metrics.totalDistanceHaversine.toStringAsFixed(3)} km'),
          _buildMetricRow('Avg Accuracy', '${metrics.averageAccuracy.toStringAsFixed(2)} m'),
          const Divider(height: 16),
          Text(
            'GPS Quality Distribution',
            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          _buildQualityBar(
            'Excellent (≤5m)',
            metrics.excellentQualityPercentage,
            Colors.green,
          ),
          _buildQualityBar(
            'Good (≤10m)',
            metrics.goodQualityPercentage,
            Colors.lightGreen,
          ),
          _buildQualityBar(
            'Fair (≤20m)',
            metrics.fairQualityPercentage,
            Colors.orange,
          ),
          _buildQualityBar(
            'Poor (≤50m)',
            metrics.poorQualityPercentage,
            Colors.red,
          ),
          const Divider(height: 16),
          Text(
            'Issues Detection',
            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          _buildMetricRow('GPS Jumps', '${metrics.jumpCount}'),
          _buildMetricRow('Signal Gaps (>30s)', '${metrics.gapCount}'),
          _buildMetricRow('Max Gap', '${metrics.maxGapDuration.toStringAsFixed(0)}s'),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityBar(String label, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.labelSmall),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Future<void> _exportMetrics(BuildContext context, TrackingSessionMetrics metrics) async {
    try {
      await TrackingMetricsService.shareMetrics(metrics);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Metrics exported successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}
