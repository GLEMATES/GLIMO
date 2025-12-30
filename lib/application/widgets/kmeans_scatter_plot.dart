import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/kmeans_clustering_v2.dart';
import '../utils/user_category_data.dart';
import '../themes/app_colors.dart';
import '../themes/app_typography.dart';
import '../themes/app_spacing.dart';

class KMeansScatterPlot extends StatelessWidget {
  final KMeansVisualizationData data;
  final bool showAfter;

  const KMeansScatterPlot({
    super.key,
    required this.data,
    required this.showAfter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          showAfter ? 'After K-Means Clustering' : 'Before K-Means',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        SizedBox(
          height: 250,
          child: ScatterChart(
            ScatterChartData(
              scatterSpots: _buildScatterSpots(),
              minX: 0,
              maxX: 4000,
              minY: 0,
              maxY: 45,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Total KM/Bulan',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.neutral600,
                          fontSize: 9,
                        ),
                      );
                    },
                    interval: 1000,
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Trip/Minggu',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.neutral600,
                          fontSize: 9,
                        ),
                      );
                    },
                    interval: 10,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 10,
                verticalInterval: 1000,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.neutral300,
                    strokeWidth: 0.5,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: AppColors.neutral300,
                    strokeWidth: 0.5,
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: AppColors.neutral400,
                  width: 1,
                ),
              ),
              scatterTouchData: ScatterTouchData(
                enabled: true,
              ),
            ),
          ),
        ),
        if (showAfter) ...[
          const SizedBox(height: AppSpacing.m),
          _buildLegend(),
        ],
      ],
    );
  }

  List<ScatterSpot> _buildScatterSpots() {
    final points = showAfter ? data.afterClustering : data.beforeClustering;
    final isLastIndex = points.length - 1;

    return points.asMap().entries.map((entry) {
      final point = entry.value;
      final isCurrentUser = entry.key == isLastIndex;

      Color color;
      double radius;

      if (showAfter) {
        color = _getCategoryColor(point.predictedCategory ?? UserCategory.medium);
        radius = isCurrentUser ? 10 : 4;
      } else {
        color = AppColors.neutral500;
        radius = isCurrentUser ? 10 : 3;
      }

      return ScatterSpot(
        point.totalKmPerMonth,
        point.tripsPerWeek,
        show: true,
        dotPainter: FlDotCirclePainter(
          radius: radius,
          color: color,
          strokeWidth: isCurrentUser ? 2 : 0,
          strokeColor: AppColors.neutral0,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: AppSpacing.m,
      runSpacing: AppSpacing.s,
      children: UserCategory.values.map((category) {
        final info = UserCategoryInfo.getInfo(category);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getCategoryColor(category),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${info.emoji} ${info.label}',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 10,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(UserCategory category) {
    switch (category) {
      case UserCategory.light:
        return Colors.green.shade600;
      case UserCategory.medium:
        return Colors.orange.shade600;
      case UserCategory.heavy:
        return Colors.red.shade600;
    }
  }
}
