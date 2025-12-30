import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'trip_history_provider.dart';
import 'motor_list_provider.dart';
import '../utils/kmeans_clustering_v2.dart';
import '../utils/user_category_data.dart';

class UsageAnalytics {
  final UserCategory category;
  final double averageKmPerTrip;
  final double totalKmThisMonth;
  final int tripsThisWeek;
  final int tripsThisMonth;
  final double predictedKmIn2Days;
  final double predictedKmIn7Days;
  final int daysUntilNextService;
  final Map<int, double> weeklyUsage;
  final List<double> last30DaysKm;
  final double trendSlope;
  final bool isUsingKMeans; // true = K-Means clustering, false = rule-based
  final int totalUsersInCluster; // Jumlah user yang digunakan untuk clustering

  UsageAnalytics({
    required this.category,
    required this.averageKmPerTrip,
    required this.totalKmThisMonth,
    required this.tripsThisWeek,
    required this.tripsThisMonth,
    required this.predictedKmIn2Days,
    required this.predictedKmIn7Days,
    required this.daysUntilNextService,
    required this.weeklyUsage,
    required this.last30DaysKm,
    required this.trendSlope,
    required this.isUsingKMeans,
    required this.totalUsersInCluster,
  });
}

class UsageAnalyticsNotifier extends Notifier<UsageAnalytics?> {
  @override
  UsageAnalytics? build() {
    return null;
  }

  Future<void> calculateAnalytics() async {
    final trips = ref.read(tripHistoryProvider);
    final activeMotor = ref.read(motorListProvider.notifier).getActiveMotor();

    if (trips.isEmpty || activeMotor == null) {
      state = null;
      return;
    }

    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));
    final last7Days = now.subtract(const Duration(days: 7));
    final thisMonth = DateTime(now.year, now.month, 1);

    final recent30DaysTrips = trips.where((t) => t.date.isAfter(last30Days)).toList();
    final recent7DaysTrips = trips.where((t) => t.date.isAfter(last7Days)).toList();
    final thisMonthTrips = trips.where((t) => t.date.isAfter(thisMonth)).toList();

    if (recent30DaysTrips.isEmpty) {
      state = null;
      return;
    }

    final totalKm30Days = recent30DaysTrips.fold(0.0, (total, t) => total + t.distance);
    final totalKmThisMonth = thisMonthTrips.fold(0.0, (total, t) => total + t.distance);
    final avgKmPerTrip = totalKm30Days / recent30DaysTrips.length;

    final weeklyUsage = _calculateWeeklyUsage(recent7DaysTrips);

    final last30DaysKm = _getLast30DaysKm(trips);

    final movingAvgDailyKm = totalKm30Days / 30;

    final predictionResults = _linearRegressionPrediction(last30DaysKm);
    final trendSlope = predictionResults['slope'] ?? 0.0;

    // K-Means clustering dengan data REAL dari semua user
    final allUsersData = await _fetchAllUsersData();
    UserCategory category;
    bool isUsingKMeans;
    int totalUsersInCluster;

    if (allUsersData.length < 30) {
      // Belum cukup data untuk K-Means, pakai rule-based sementara
      category = _determineCategory(totalKmThisMonth);
      isUsingKMeans = false;
      totalUsersInCluster = allUsersData.length;
    } else {
      // Cukup data, pakai K-Means clustering
      final currentUserData = MonthlyUsageData(
        avgKmPerTrip: avgKmPerTrip,
        totalKmPerMonth: totalKmThisMonth,
        tripsPerWeek: recent7DaysTrips.length.toDouble(),
        trendSlope: trendSlope,
      );

      final kmeansResult = KMeansClustererV2.clusterAndPredict(
        currentUser: currentUserData,
        historicalData: allUsersData,
      );

      category = kmeansResult.predictedCategory;
      isUsingKMeans = true;
      totalUsersInCluster = allUsersData.length + 1; // +1 untuk current user
    }

    final predictedKmIn2Days = (int.tryParse(activeMotor.odometer) ?? 0) +
        (movingAvgDailyKm * 2);
    final predictedKmIn7Days = (int.tryParse(activeMotor.odometer) ?? 0) +
        (movingAvgDailyKm * 7);

    final currentOdometer = int.tryParse(activeMotor.odometer) ?? 0;
    final nextServiceKm = ((currentOdometer / 1000).ceil() + 1) * 1000;
    final kmUntilService = nextServiceKm - currentOdometer;
    final daysUntilService = movingAvgDailyKm > 0
        ? (kmUntilService / movingAvgDailyKm).ceil()
        : 999;

    state = UsageAnalytics(
      category: category,
      averageKmPerTrip: avgKmPerTrip,
      totalKmThisMonth: totalKmThisMonth,
      tripsThisWeek: recent7DaysTrips.length,
      tripsThisMonth: thisMonthTrips.length,
      predictedKmIn2Days: predictedKmIn2Days,
      predictedKmIn7Days: predictedKmIn7Days,
      daysUntilNextService: daysUntilService,
      weeklyUsage: weeklyUsage,
      last30DaysKm: last30DaysKm,
      trendSlope: trendSlope,
      isUsingKMeans: isUsingKMeans,
      totalUsersInCluster: totalUsersInCluster,
    );
  }

  /// Fetch trip data dari SEMUA user di Firebase (100% REAL data)
  Future<List<MonthlyUsageData>> _fetchAllUsersData() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) return [];

      // Ambil semua user IDs
      final usersSnapshot = await firestore.collection('users').get();
      final allUsersData = <MonthlyUsageData>[];

      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;

        // Skip current user (akan ditambahkan terpisah di calculateAnalytics)
        if (userId == currentUser.uid) continue;

        // Ambil trip history user ini
        final tripsSnapshot = await firestore
            .collection('users')
            .doc(userId)
            .collection('trip_history')
            .get();

        if (tripsSnapshot.docs.isEmpty) continue;

        // Convert ke TripHistory objects
        final userTrips = tripsSnapshot.docs.map((doc) {
          final data = doc.data();
          return TripHistory(
            id: doc.id,
            motorId: data['motorId'] ?? '',
            motorName: data['motorName'] ?? '',
            startOdometer: data['startOdometer'] ?? 0,
            endOdometer: data['endOdometer'] ?? 0,
            date: data['date'] != null
                ? (data['date'] as Timestamp).toDate()
                : DateTime.now(),
            source: data['source'] ?? 'manual',
          );
        }).toList();

        // Hitung stats untuk user ini
        final now = DateTime.now();
        final last30Days = now.subtract(const Duration(days: 30));
        final last7Days = now.subtract(const Duration(days: 7));
        final thisMonth = DateTime(now.year, now.month, 1);

        final recent30DaysTrips = userTrips.where((t) => t.date.isAfter(last30Days)).toList();
        final recent7DaysTrips = userTrips.where((t) => t.date.isAfter(last7Days)).toList();
        final thisMonthTrips = userTrips.where((t) => t.date.isAfter(thisMonth)).toList();

        // Skip user yang tidak punya data cukup
        if (recent30DaysTrips.isEmpty || thisMonthTrips.isEmpty) continue;

        final totalKm30Days = recent30DaysTrips.fold(0.0, (total, t) => total + t.distance);
        final totalKmThisMonth = thisMonthTrips.fold(0.0, (total, t) => total + t.distance);
        final avgKmPerTrip = totalKm30Days / recent30DaysTrips.length;

        final last30DaysKm = _getLast30DaysKmForUser(userTrips);
        final predictionResults = _linearRegressionPrediction(last30DaysKm);
        final trendSlope = predictionResults['slope'] ?? 0.0;

        allUsersData.add(MonthlyUsageData(
          avgKmPerTrip: avgKmPerTrip,
          totalKmPerMonth: totalKmThisMonth,
          tripsPerWeek: recent7DaysTrips.length.toDouble(),
          trendSlope: trendSlope,
        ));
      }

      return allUsersData;
    } catch (e) {
      // Error fetching data, return empty
      return [];
    }
  }

  List<double> _getLast30DaysKmForUser(List<TripHistory> trips) {
    final now = DateTime.now();
    final dailyKm = <double>[];

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final dayTrips = trips.where((t) =>
          t.date.isAfter(startOfDay) && t.date.isBefore(endOfDay));

      final totalKm = dayTrips.fold(0.0, (total, t) => total + t.distance);
      dailyKm.add(totalKm);
    }

    return dailyKm;
  }

  Map<int, double> _calculateWeeklyUsage(List<TripHistory> trips) {
    final usage = <int, double>{
      1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0,
    };

    for (var trip in trips) {
      final weekday = trip.date.weekday;
      usage[weekday] = (usage[weekday] ?? 0) + trip.distance;
    }

    return usage;
  }

  List<double> _getLast30DaysKm(List<TripHistory> trips) {
    final now = DateTime.now();
    final dailyKm = <double>[];

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final dayTrips = trips.where((t) =>
          t.date.isAfter(startOfDay) && t.date.isBefore(endOfDay));

      final totalKm = dayTrips.fold(0.0, (total, t) => total + t.distance);
      dailyKm.add(totalKm);
    }

    return dailyKm;
  }

  Map<String, double> _linearRegressionPrediction(List<double> data) {
    if (data.length < 2) {
      return {'slope': 0.0, 'intercept': 0.0};
    }

    final n = data.length;
    final x = List.generate(n, (i) => i.toDouble());
    final y = data;

    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((xi) => xi * xi).reduce((a, b) => a + b);

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    return {'slope': slope, 'intercept': intercept};
  }

  UserCategory _determineCategory(double totalKmPerMonth) {
    // Kategori berdasarkan total KM per bulan (100% data real)
    // Light: < 500 km/bulan
    // Medium: 500 - 1500 km/bulan
    // Heavy: > 1500 km/bulan
    if (totalKmPerMonth < 500) {
      return UserCategory.light;
    } else if (totalKmPerMonth <= 1500) {
      return UserCategory.medium;
    } else {
      return UserCategory.heavy;
    }
  }
}

final usageAnalyticsProvider = NotifierProvider<UsageAnalyticsNotifier, UsageAnalytics?>(
  () => UsageAnalyticsNotifier(),
);
