import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/kmeans_clustering_v2.dart';
import '../utils/user_category_data.dart';

class UsageAnalyticsV2State {
  final KMeansVisualizationData visualizationData;
  final UserCategory predictedCategory;
  final double distanceToCentroid;
  final MonthlyUsageData currentUserData;

  UsageAnalyticsV2State({
    required this.visualizationData,
    required this.predictedCategory,
    required this.distanceToCentroid,
    required this.currentUserData,
  });
}

class UsageAnalyticsV2Notifier extends Notifier<UsageAnalyticsV2State?> {
  @override
  UsageAnalyticsV2State? build() {
    return null;
  }

  Future<void> runClustering() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final historicalData = HistoricalDataGenerator.generate12MonthsData();
    final currentUser = HistoricalDataGenerator.getCurrentUserData();

    final result = KMeansClustererV2.clusterAndPredict(
      currentUser: currentUser,
      historicalData: historicalData,
    );

    state = UsageAnalyticsV2State(
      visualizationData: result,
      predictedCategory: result.predictedCategory,
      distanceToCentroid: result.distanceToCentroid,
      currentUserData: currentUser,
    );
  }
}

final usageAnalyticsV2Provider =
    NotifierProvider<UsageAnalyticsV2Notifier, UsageAnalyticsV2State?>(
  UsageAnalyticsV2Notifier.new,
);
