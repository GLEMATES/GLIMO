import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'trip_history_provider.dart';
import 'motor_list_provider.dart';

enum UsageCategory {
  light,
  medium,
  heavy,
}

class UsageAnalytics {
  final UsageCategory category;
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

    final totalKm30Days = recent30DaysTrips.fold(0.0, (sum, t) => sum + t.distance);
    final totalKmThisMonth = thisMonthTrips.fold(0.0, (sum, t) => sum + t.distance);
    final avgKmPerTrip = totalKm30Days / recent30DaysTrips.length;

    final category = _classifyUsage(totalKmThisMonth);

    final weeklyUsage = _calculateWeeklyUsage(recent7DaysTrips);

    final last30DaysKm = _getLast30DaysKm(trips);

    final movingAvgDailyKm = totalKm30Days / 30;

    final predictionResults = _linearRegressionPrediction(last30DaysKm);
    final trendSlope = predictionResults['slope'] ?? 0.0;

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
    );
  }

  UsageCategory _classifyUsage(double kmPerMonth) {
    if (kmPerMonth < 500) return UsageCategory.light;
    if (kmPerMonth < 1500) return UsageCategory.medium;
    return UsageCategory.heavy;
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

      final totalKm = dayTrips.fold(0.0, (sum, t) => sum + t.distance);
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
}

final usageAnalyticsProvider = NotifierProvider<UsageAnalyticsNotifier, UsageAnalytics?>(
  () => UsageAnalyticsNotifier(),
);
