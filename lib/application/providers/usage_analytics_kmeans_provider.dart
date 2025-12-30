import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/kmeans_clustering_v2.dart';
import '../utils/user_category_data.dart';
import 'trip_history_provider.dart';
import 'motor_list_provider.dart';

class UsageAnalyticsKMeansState {
  final UserCategory? predictedCategory;
  final double? distanceToCentroid;
  final MonthlyUsageData? currentUserData;
  final bool hasEnoughData;
  final String? errorMessage;

  UsageAnalyticsKMeansState({
    this.predictedCategory,
    this.distanceToCentroid,
    this.currentUserData,
    required this.hasEnoughData,
    this.errorMessage,
  });

  factory UsageAnalyticsKMeansState.noData() {
    return UsageAnalyticsKMeansState(
      hasEnoughData: false,
      errorMessage: 'Belum ada data perjalanan. Mulai gunakan fitur GPS tracking untuk analisis K-Means.',
    );
  }

  factory UsageAnalyticsKMeansState.loading() {
    return UsageAnalyticsKMeansState(
      hasEnoughData: false,
    );
  }
}

class UsageAnalyticsKMeansNotifier extends Notifier<UsageAnalyticsKMeansState> {
  @override
  UsageAnalyticsKMeansState build() {
    return UsageAnalyticsKMeansState.loading();
  }

  Future<void> analyzeUsage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = UsageAnalyticsKMeansState.noData();
      return;
    }

    final trips = ref.read(tripHistoryProvider);
    final motors = ref.read(motorListProvider);
    final activeMotor = motors.where((m) => m.isActive).firstOrNull ?? motors.firstOrNull;

    if (trips.isEmpty || activeMotor == null) {
      state = UsageAnalyticsKMeansState.noData();
      return;
    }

    final currentUserData = _calculateUserData(trips, activeMotor);

    if (currentUserData == null) {
      state = UsageAnalyticsKMeansState(
        hasEnoughData: false,
        errorMessage: 'Data tidak cukup untuk analisis. Minimal 1 bulan data diperlukan.',
      );
      return;
    }

    final historicalData = HistoricalDataGenerator.generate12MonthsData();

    final result = KMeansClustererV2.clusterAndPredict(
      currentUser: currentUserData,
      historicalData: historicalData,
    );

    state = UsageAnalyticsKMeansState(
      predictedCategory: result.predictedCategory,
      distanceToCentroid: result.distanceToCentroid,
      currentUserData: currentUserData,
      hasEnoughData: true,
    );
  }

  MonthlyUsageData? _calculateUserData(List<TripHistory> trips, Motor activeMotor) {
    if (trips.isEmpty) return null;

    final now = DateTime.now();
    final oneMonthAgo = now.subtract(const Duration(days: 30));
    final twoMonthsAgo = now.subtract(const Duration(days: 60));

    final tripsLastMonth = trips.where((trip) {
      return trip.date.isAfter(oneMonthAgo) && trip.date.isBefore(now);
    }).toList();

    final tripsPreviousMonth = trips.where((trip) {
      return trip.date.isAfter(twoMonthsAgo) && trip.date.isBefore(oneMonthAgo);
    }).toList();

    if (tripsLastMonth.isEmpty) return null;

    final totalKmThisMonth = tripsLastMonth.fold<double>(
      0.0,
      (sum, trip) => sum + trip.distance,
    );

    final totalKmPreviousMonth = tripsPreviousMonth.isEmpty
        ? totalKmThisMonth
        : tripsPreviousMonth.fold<double>(
            0.0,
            (sum, trip) => sum + trip.distance,
          );

    final avgKmPerTrip = totalKmThisMonth / tripsLastMonth.length;

    final tripsPerWeek = (tripsLastMonth.length / 4.3).toDouble();

    final trendSlope = totalKmPreviousMonth == 0
        ? 0.1
        : (totalKmThisMonth - totalKmPreviousMonth) / totalKmPreviousMonth;

    return MonthlyUsageData(
      avgKmPerTrip: avgKmPerTrip,
      totalKmPerMonth: totalKmThisMonth,
      tripsPerWeek: tripsPerWeek,
      trendSlope: trendSlope.clamp(-1.0, 1.0),
    );
  }
}

final usageAnalyticsKMeansProvider =
    NotifierProvider<UsageAnalyticsKMeansNotifier, UsageAnalyticsKMeansState>(
  UsageAnalyticsKMeansNotifier.new,
);
