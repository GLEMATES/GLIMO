import 'package:flutter_test/flutter_test.dart';
import 'package:glimo/application/utils/kmeans_clustering.dart';

void main() {
  group('KMeansClusterer', () {
    late KMeansClusterer clusterer;

    setUp(() {
      clusterer = KMeansClusterer(k: 3);
    });

    test('should classify light usage correctly', () {
      final features = UsageFeatures(
        avgKmPerTrip: 5.0,
        totalKmPerMonth: 300.0,
        tripsPerWeek: 10.0,
        trendSlope: 0.1,
      );

      final historicalData = [
        UsageFeatures(
          avgKmPerTrip: 6.0,
          totalKmPerMonth: 350.0,
          tripsPerWeek: 12.0,
          trendSlope: 0.2,
        ),
        UsageFeatures(
          avgKmPerTrip: 15.0,
          totalKmPerMonth: 900.0,
          tripsPerWeek: 15.0,
          trendSlope: 0.3,
        ),
        UsageFeatures(
          avgKmPerTrip: 25.0,
          totalKmPerMonth: 1800.0,
          tripsPerWeek: 20.0,
          trendSlope: 0.5,
        ),
      ];

      final result = clusterer.predict(features, historicalData);
      expect(result.label, 'light');
    });

    test('should classify medium usage correctly', () {
      final features = UsageFeatures(
        avgKmPerTrip: 15.0,
        totalKmPerMonth: 1000.0,
        tripsPerWeek: 15.0,
        trendSlope: 0.2,
      );

      final historicalData = [
        UsageFeatures(
          avgKmPerTrip: 5.0,
          totalKmPerMonth: 350.0,
          tripsPerWeek: 10.0,
          trendSlope: 0.1,
        ),
        UsageFeatures(
          avgKmPerTrip: 14.0,
          totalKmPerMonth: 950.0,
          tripsPerWeek: 14.0,
          trendSlope: 0.25,
        ),
        UsageFeatures(
          avgKmPerTrip: 30.0,
          totalKmPerMonth: 2000.0,
          tripsPerWeek: 25.0,
          trendSlope: 0.6,
        ),
      ];

      final result = clusterer.predict(features, historicalData);
      expect(result.label, 'medium');
    });

    test('should classify heavy usage correctly', () {
      final features = UsageFeatures(
        avgKmPerTrip: 30.0,
        totalKmPerMonth: 2200.0,
        tripsPerWeek: 25.0,
        trendSlope: 0.5,
      );

      final historicalData = [
        UsageFeatures(
          avgKmPerTrip: 5.0,
          totalKmPerMonth: 350.0,
          tripsPerWeek: 10.0,
          trendSlope: 0.1,
        ),
        UsageFeatures(
          avgKmPerTrip: 15.0,
          totalKmPerMonth: 900.0,
          tripsPerWeek: 15.0,
          trendSlope: 0.3,
        ),
        UsageFeatures(
          avgKmPerTrip: 28.0,
          totalKmPerMonth: 2100.0,
          tripsPerWeek: 23.0,
          trendSlope: 0.55,
        ),
      ];

      final result = clusterer.predict(features, historicalData);
      expect(result.label, 'heavy');
    });

    test('should fallback to rule-based when insufficient data', () {
      final lightFeatures = UsageFeatures(
        avgKmPerTrip: 5.0,
        totalKmPerMonth: 400.0,
        tripsPerWeek: 10.0,
        trendSlope: 0.1,
      );

      final mediumFeatures = UsageFeatures(
        avgKmPerTrip: 15.0,
        totalKmPerMonth: 1000.0,
        tripsPerWeek: 15.0,
        trendSlope: 0.2,
      );

      final heavyFeatures = UsageFeatures(
        avgKmPerTrip: 30.0,
        totalKmPerMonth: 1800.0,
        tripsPerWeek: 25.0,
        trendSlope: 0.5,
      );

      final insufficientData = <UsageFeatures>[];

      expect(clusterer.predict(lightFeatures, insufficientData).label, 'light');
      expect(clusterer.predict(mediumFeatures, insufficientData).label, 'medium');
      expect(clusterer.predict(heavyFeatures, insufficientData).label, 'heavy');
    });

    test('should convert features to vector correctly', () {
      final features = UsageFeatures(
        avgKmPerTrip: 10.0,
        totalKmPerMonth: 500.0,
        tripsPerWeek: 12.0,
        trendSlope: 0.3,
      );

      final vector = features.toVector();

      expect(vector.length, 4);
      expect(vector[0], 10.0);
      expect(vector[1], 500.0);
      expect(vector[2], 12.0);
      expect(vector[3], 0.3);
    });

    test('should handle edge case with identical features', () {
      final features = UsageFeatures(
        avgKmPerTrip: 10.0,
        totalKmPerMonth: 500.0,
        tripsPerWeek: 12.0,
        trendSlope: 0.2,
      );

      final historicalData = List.generate(
        5,
        (_) => UsageFeatures(
          avgKmPerTrip: 10.0,
          totalKmPerMonth: 500.0,
          tripsPerWeek: 12.0,
          trendSlope: 0.2,
        ),
      );

      final result = clusterer.predict(features, historicalData);
      expect(['light', 'medium', 'heavy'].contains(result.label), true);
    });
  });
}
