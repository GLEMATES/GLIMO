import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/usage_analytics_provider.dart';
import '../../providers/motor_list_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../utils/user_category_data.dart';

class AnalisisPenggunaanScreen extends ConsumerStatefulWidget {
  const AnalisisPenggunaanScreen({super.key});

  @override
  ConsumerState<AnalisisPenggunaanScreen> createState() => _AnalisisPenggunaanScreenState();
}

class _AnalisisPenggunaanScreenState extends ConsumerState<AnalisisPenggunaanScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(usageAnalyticsProvider.notifier).calculateAnalytics();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(usageAnalyticsProvider);
    final activeMotor = ref.watch(motorListProvider.notifier).getActiveMotor();

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text(
          'Analisis Penggunaan',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.neutral0),
        ),
        backgroundColor: AppColors.normalHover,
        iconTheme: const IconThemeData(color: AppColors.neutral0),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await ref.read(usageAnalyticsProvider.notifier).calculateAnalytics();
              setState(() {
                _isLoading = false;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.normalHover),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    'Menganalisis data...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.neutral700,
                    ),
                  ),
                ],
              ),
            )
          : analytics == null
              ? _buildNoDataView()
              : _buildAnalyticsView(analytics, activeMotor),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              'Belum Ada Data',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.neutral900,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Mulai tracking perjalanan untuk melihat analisis penggunaan motormu',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsView(UsageAnalytics analytics, Motor? activeMotor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClusteringInfoBanner(analytics),
          const SizedBox(height: AppSpacing.l),
          _buildHeaderCard(analytics, activeMotor),
          const SizedBox(height: AppSpacing.l),
          _buildCategoryCard(analytics),
          const SizedBox(height: AppSpacing.l),
          _buildPredictionCard(analytics, activeMotor),
          const SizedBox(height: AppSpacing.l),
          _buildWeeklyUsageCard(analytics),
          const SizedBox(height: AppSpacing.l),
          _buildTrendCard(analytics),
          const SizedBox(height: AppSpacing.l),
          _buildInsightsCard(analytics),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildClusteringInfoBanner(UsageAnalytics analytics) {
    final isKMeans = analytics.isUsingKMeans;
    final totalUsers = analytics.totalUsersInCluster;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: isKMeans ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isKMeans ? Colors.green.shade200 : Colors.orange.shade200,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isKMeans ? Icons.verified : Icons.info_outline,
            color: isKMeans ? Colors.green.shade700 : Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(
              isKMeans
                  ? 'Kategori ditentukan dengan K-Means clustering berdasarkan data $totalUsers pengguna real'
                  : 'Kategori menggunakan analisis sederhana (data user: $totalUsers). K-Means clustering akan aktif setelah ≥30 pengguna',
              style: AppTypography.bodySmall.copyWith(
                color: isKMeans ? Colors.green.shade900 : Colors.orange.shade900,
                fontSize: 11,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(UsageAnalytics analytics, Motor? activeMotor) {
    final categoryInfo = _getCategoryInfo(analytics.category);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: categoryInfo['colors'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (categoryInfo['colors'] as List<Color>)[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: AppColors.neutral0,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kamu adalah ${categoryInfo['label']} User!',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.neutral0,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      activeMotor != null ? '${activeMotor.model} - ${activeMotor.type}' : '',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral0.withValues(alpha: 0.9),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${analytics.totalKmThisMonth.toStringAsFixed(1)} km bulan ini',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.neutral0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            categoryInfo['description'] as String,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral0.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(UsageAnalytics analytics) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: AppColors.normalHover),
              const SizedBox(width: AppSpacing.m),
              Text(
                'Kategori Pengguna',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: analytics.category == UserCategory.light ? 100 : 25,
                    title: 'Light\n<500 km',
                    color: Colors.green,
                    radius: analytics.category == UserCategory.light ? 80 : 70,
                    titleStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral0,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    titlePositionPercentageOffset: 0.6,
                  ),
                  PieChartSectionData(
                    value: analytics.category == UserCategory.medium ? 100 : 25,
                    title: 'Medium\n500-1500',
                    color: Colors.orange,
                    radius: analytics.category == UserCategory.medium ? 80 : 70,
                    titleStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral0,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    titlePositionPercentageOffset: 0.6,
                  ),
                  PieChartSectionData(
                    value: analytics.category == UserCategory.heavy ? 100 : 25,
                    title: 'Heavy\n>1500 km',
                    color: Colors.red,
                    radius: analytics.category == UserCategory.heavy ? 80 : 70,
                    titleStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral0,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    titlePositionPercentageOffset: 0.6,
                  ),
                ],
                sectionsSpace: 4,
                centerSpaceRadius: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(UsageAnalytics analytics, Motor? activeMotor) {
    final currentOdometer = int.tryParse(activeMotor?.odometer ?? '0') ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.normalHover),
              const SizedBox(width: AppSpacing.m),
              Text(
                'Prediksi Odometer',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            children: [
              Expanded(
                child: _buildPredictionItem(
                  'Dalam 2 Hari',
                  '~${analytics.predictedKmIn2Days.toStringAsFixed(0)} km',
                  '+${(analytics.predictedKmIn2Days - currentOdometer).toStringAsFixed(0)} km',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: _buildPredictionItem(
                  'Dalam 7 Hari',
                  '~${analytics.predictedKmIn7Days.toStringAsFixed(0)} km',
                  '+${(analytics.predictedKmIn7Days - currentOdometer).toStringAsFixed(0)} km',
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.normalHover.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.build_circle, color: AppColors.normalHover, size: 20),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    analytics.daysUntilNextService < 999
                        ? 'Servis berikutnya: ~${analytics.daysUntilNextService} hari lagi'
                        : 'Belum ada estimasi servis',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.normalHover,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.neutral300,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.neutral600,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 15,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('30 Hari Lalu', style: TextStyle(fontSize: 8, color: Colors.grey)),
                          );
                        } else if (value == 30) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('Hari Ini', style: TextStyle(fontSize: 8, color: Colors.grey)),
                          );
                        } else if (value == 36) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('7 Hari Lagi', style: TextStyle(fontSize: 8, color: Colors.grey)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      analytics.last30DaysKm.length > 30 ? 30 : analytics.last30DaysKm.length,
                      (i) => FlSpot(i.toDouble(), analytics.last30DaysKm[i]),
                    ),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: [
                      FlSpot(29, analytics.last30DaysKm.isNotEmpty ? analytics.last30DaysKm.last : 0),
                      FlSpot(36, (analytics.predictedKmIn7Days - currentOdometer) / 7),
                    ],
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(Colors.blue, 'Data Aktual'),
              const SizedBox(width: AppSpacing.l),
              _buildLegend(Colors.orange, 'Prediksi'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionItem(String title, String value, String delta, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.neutral600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: AppSpacing.s),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            delta,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.neutral600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyUsageCard(UsageAnalytics analytics) {
    final weekDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: AppColors.normalHover),
              const SizedBox(width: AppSpacing.m),
              Text(
                'Pola Penggunaan Mingguan',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: analytics.weeklyUsage.values.reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${weekDays[group.x.toInt()]}\n${rod.toY.toStringAsFixed(1)} km',
                        AppTypography.bodySmall.copyWith(
                          color: AppColors.neutral0,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < weekDays.length) {
                          return Text(
                            weekDays[index],
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.neutral600,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final km = analytics.weeklyUsage[i + 1] ?? 0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: km,
                        color: AppColors.normalHover,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(UsageAnalytics analytics) {
    final trendIcon = analytics.trendSlope > 0.1
        ? Icons.trending_up
        : analytics.trendSlope < -0.1
            ? Icons.trending_down
            : Icons.trending_flat;

    final trendColor = analytics.trendSlope > 0.1
        ? Colors.green
        : analytics.trendSlope < -0.1
            ? Colors.red
            : Colors.orange;

    final trendText = analytics.trendSlope > 0.1
        ? 'Penggunaan meningkat'
        : analytics.trendSlope < -0.1
            ? 'Penggunaan menurun'
            : 'Penggunaan stabil';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(trendIcon, color: trendColor, size: 32),
          ),
          const SizedBox(width: AppSpacing.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trend Penggunaan',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  trendText,
                  style: AppTypography.bodyMedium.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(UsageAnalytics analytics) {
    final mostActiveDay = _getMostActiveDay(analytics.weeklyUsage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.normalHover),
              const SizedBox(width: AppSpacing.m),
              Text(
                'Insights & Tips',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          _buildInsightItem(
            Icons.route,
            'Rata-rata per Trip',
            '${analytics.averageKmPerTrip.toStringAsFixed(1)} km',
          ),
          const SizedBox(height: AppSpacing.m),
          _buildInsightItem(
            Icons.calendar_today,
            'Frekuensi Minggu Ini',
            '${analytics.tripsThisWeek} trip',
          ),
          const SizedBox(height: AppSpacing.m),
          _buildInsightItem(
            Icons.star,
            'Hari Paling Aktif',
            mostActiveDay,
          ),
          const SizedBox(height: AppSpacing.l),
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    'Pertahankan konsistensi untuk hasil prediksi yang lebih akurat!',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.neutral600, size: 20),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral700,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.normalHover,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getCategoryInfo(UserCategory category) {
    final info = UserCategoryInfo.getInfo(category);
    switch (category) {
      case UserCategory.light:
        return {
          'label': info.label,
          'description': info.description,
          'colors': [Colors.green.shade400, Colors.green.shade600],
        };
      case UserCategory.medium:
        return {
          'label': info.label,
          'description': info.description,
          'colors': [Colors.orange.shade400, Colors.orange.shade600],
        };
      case UserCategory.heavy:
        return {
          'label': info.label,
          'description': info.description,
          'colors': [Colors.red.shade400, Colors.red.shade600],
        };
    }
  }

  String _getMostActiveDay(Map<int, double> weeklyUsage) {
    final weekDays = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    var maxKm = 0.0;
    var maxDay = 1;

    weeklyUsage.forEach((day, km) {
      if (km > maxKm) {
        maxKm = km;
        maxDay = day;
      }
    });

    if (maxKm == 0) return 'Belum ada data';
    return weekDays[maxDay];
  }
}
