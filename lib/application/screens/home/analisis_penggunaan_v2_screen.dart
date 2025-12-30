import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/usage_analytics_v2_provider.dart';
import '../../providers/motor_list_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../utils/user_category_data.dart';
import '../../widgets/kmeans_scatter_plot.dart';

class AnalisisPenggunaanV2Screen extends ConsumerStatefulWidget {
  const AnalisisPenggunaanV2Screen({super.key});

  @override
  ConsumerState<AnalisisPenggunaanV2Screen> createState() =>
      _AnalisisPenggunaanV2ScreenState();
}

class _AnalisisPenggunaanV2ScreenState
    extends ConsumerState<AnalisisPenggunaanV2Screen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(usageAnalyticsV2Provider.notifier).runClustering();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(usageAnalyticsV2Provider);
    final activeMotor = ref.watch(motorListProvider.notifier).getActiveMotor();

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text(
          'Analisis K-Means Clustering',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.neutral0,
            fontSize: 18,
          ),
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
              await ref
                  .read(usageAnalyticsV2Provider.notifier)
                  .runClustering();
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
                    'Menjalankan K-Means clustering...',
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
              'Demo Error',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.neutral900,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Gagal generate demo data',
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

  Widget _buildAnalyticsView(
    UsageAnalyticsV2State analytics,
    Motor? activeMotor,
  ) {
    final categoryInfo =
        UserCategoryInfo.getInfo(analytics.predictedCategory);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(),
          const SizedBox(height: AppSpacing.l),
          _buildResultCard(categoryInfo, analytics),
          const SizedBox(height: AppSpacing.l),
          _buildDataInfoCard(analytics),
          const SizedBox(height: AppSpacing.l),
          _buildVisualizationCard(analytics),
          const SizedBox(height: AppSpacing.l),
          _buildCategoryDetailsCard(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(
                  'K-Means Clustering (k=3)',
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Menggunakan package k_means_cluster dengan 36 data point (12 bulan × 3 kategori)',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.blue.shade800,
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Visualisasi Before/After menunjukkan bagaimana K-Means mengelompokkan data menjadi 3 cluster intensitas penggunaan (unsupervised learning).',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.blue.shade700,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    UserCategoryInfo categoryInfo,
    UsageAnalyticsV2State analytics,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getCategoryColor(analytics.predictedCategory).withValues(alpha: 0.8),
            _getCategoryColor(analytics.predictedCategory),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor(analytics.predictedCategory)
                .withValues(alpha: 0.3),
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
              Text(
                categoryInfo.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kamu adalah',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral0.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      categoryInfo.label,
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.neutral0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            categoryInfo.description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral0.withValues(alpha: 0.95),
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: AppSpacing.m),
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.neutral0.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insights,
                  color: AppColors.neutral0,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    'Distance to centroid: ${analytics.distanceToCentroid.toStringAsFixed(4)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral0,
                      fontWeight: FontWeight.w600,
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

  Widget _buildDataInfoCard(UsageAnalyticsV2State analytics) {
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
                'Data Kamu (Current User)',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          _buildDataRow(
            'Rata-rata KM per Trip',
            '${analytics.currentUserData.avgKmPerTrip.toStringAsFixed(1)} km',
          ),
          const SizedBox(height: AppSpacing.m),
          _buildDataRow(
            'Total KM per Bulan',
            '${analytics.currentUserData.totalKmPerMonth.toStringAsFixed(0)} km',
          ),
          const SizedBox(height: AppSpacing.m),
          _buildDataRow(
            'Trip per Minggu',
            '${analytics.currentUserData.tripsPerWeek.toStringAsFixed(1)} trip',
          ),
          const SizedBox(height: AppSpacing.m),
          _buildDataRow(
            'Trend Slope',
            analytics.currentUserData.trendSlope.toStringAsFixed(3),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.neutral700,
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

  Widget _buildVisualizationCard(UsageAnalyticsV2State analytics) {
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
              Icon(Icons.scatter_plot, color: AppColors.normalHover),
              const SizedBox(width: AppSpacing.m),
              Text(
                'Visualisasi K-Means',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Text(
              'Titik besar = posisi kamu. Sebelum clustering semua abu-abu, setelah clustering berwarna sesuai kategori.',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.amber.shade900,
                fontSize: 10,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          KMeansScatterPlot(
            data: analytics.visualizationData,
            showAfter: false,
          ),
          const SizedBox(height: AppSpacing.xl),
          KMeansScatterPlot(
            data: analytics.visualizationData,
            showAfter: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.green.shade700, size: 24),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(
                  '3 Kategori Intensitas Penggunaan',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          ...UserCategory.values.map((category) {
            final info = UserCategoryInfo.getInfo(category);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: _buildCategoryItem(info, category),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(UserCategoryInfo info, UserCategory category) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getCategoryColor(category).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getCategoryColor(category),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Text(
            info.emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  info.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.neutral600,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
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
