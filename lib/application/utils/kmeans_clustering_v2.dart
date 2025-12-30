import 'package:k_means_cluster/k_means_cluster.dart';
import 'dart:math';
import 'user_category_data.dart';

class ClusterPoint {
  final double avgKmPerTrip;
  final double totalKmPerMonth;
  final double tripsPerWeek;
  final double trendSlope;
  final UserCategory? actualCategory;
  UserCategory? predictedCategory;
  int? clusterIndex;

  ClusterPoint({
    required this.avgKmPerTrip,
    required this.totalKmPerMonth,
    required this.tripsPerWeek,
    required this.trendSlope,
    this.actualCategory,
    this.predictedCategory,
    this.clusterIndex,
  });

  List<double> toVector() => [
        avgKmPerTrip,
        totalKmPerMonth,
        tripsPerWeek,
        trendSlope,
      ];
}

class KMeansVisualizationData {
  final List<ClusterPoint> beforeClustering;
  final List<ClusterPoint> afterClustering;
  final List<List<double>> centroids;
  final Map<int, UserCategory> clusterLabels;
  final UserCategory predictedCategory;
  final double distanceToCentroid;
  final List<double> userVector;

  KMeansVisualizationData({
    required this.beforeClustering,
    required this.afterClustering,
    required this.centroids,
    required this.clusterLabels,
    required this.predictedCategory,
    required this.distanceToCentroid,
    required this.userVector,
  });
}

class KMeansClustererV2 {
  static const int k = 3;

  static KMeansVisualizationData clusterAndPredict({
    required MonthlyUsageData currentUser,
    required List<MonthlyUsageData> historicalData,
  }) {
    final allData = [...historicalData, currentUser];
    final normalizedData = _normalizeData(allData.map((d) => d.toVector()).toList());

    final beforePoints = allData.asMap().entries.map((entry) {
      return ClusterPoint(
        avgKmPerTrip: allData[entry.key].avgKmPerTrip,
        totalKmPerMonth: allData[entry.key].totalKmPerMonth,
        tripsPerWeek: allData[entry.key].tripsPerWeek,
        trendSlope: allData[entry.key].trendSlope,
        actualCategory: allData[entry.key].actualCategory,
      );
    }).toList();

    final instances = normalizedData.asMap().entries.map((entry) {
      return Instance(
        id: 'point_${entry.key}',
        location: entry.value,
      );
    }).toList();

    final clusters = initialClusters(k, instances);
    kMeans(clusters: clusters, instances: instances);

    final centroids = clusters.map((cluster) {
      if (cluster.instances.isEmpty) {
        return List<double>.filled(4, 0.0);
      }
      final numFeatures = cluster.instances.first.location.length;
      final sums = List<double>.filled(numFeatures, 0.0);

      for (var instance in cluster.instances) {
        for (var i = 0; i < numFeatures; i++) {
          sums[i] += instance.location[i].toDouble();
        }
      }

      return sums.map((sum) => sum / cluster.instances.length).toList();
    }).toList();

    final clusterAssignments = <int, List<int>>{};
    for (var i = 0; i < k; i++) {
      clusterAssignments[i] = [];
    }

    for (var i = 0; i < instances.length; i++) {
      final instance = instances[i];
      var minDist = double.infinity;
      var assignedCluster = 0;

      final instanceLocation = instance.location.map((e) => e.toDouble()).toList();

      for (var j = 0; j < centroids.length; j++) {
        final dist = _euclideanDistance(instanceLocation, centroids[j]);
        if (dist < minDist) {
          minDist = dist;
          assignedCluster = j;
        }
      }

      clusterAssignments[assignedCluster]!.add(i);
    }

    final clusterLabels = _assignLabelsBasedOnTotalKm(
      clusterAssignments,
      allData,
    );

    final userIndex = allData.length - 1;
    final userVector = normalizedData[userIndex];
    var userClusterIndex = 0;
    var minDistToUser = double.infinity;

    for (var j = 0; j < centroids.length; j++) {
      final dist = _euclideanDistance(userVector, centroids[j]);
      if (dist < minDistToUser) {
        minDistToUser = dist;
        userClusterIndex = j;
      }
    }

    final predictedCategory = clusterLabels[userClusterIndex]!;

    final afterPoints = beforePoints.asMap().entries.map((entry) {
      var clusterIdx = 0;
      var minDist = double.infinity;

      for (var j = 0; j < centroids.length; j++) {
        final dist = _euclideanDistance(normalizedData[entry.key], centroids[j]);
        if (dist < minDist) {
          minDist = dist;
          clusterIdx = j;
        }
      }

      return ClusterPoint(
        avgKmPerTrip: entry.value.avgKmPerTrip,
        totalKmPerMonth: entry.value.totalKmPerMonth,
        tripsPerWeek: entry.value.tripsPerWeek,
        trendSlope: entry.value.trendSlope,
        actualCategory: entry.value.actualCategory,
        predictedCategory: clusterLabels[clusterIdx],
        clusterIndex: clusterIdx,
      );
    }).toList();

    return KMeansVisualizationData(
      beforeClustering: beforePoints,
      afterClustering: afterPoints,
      centroids: centroids,
      clusterLabels: clusterLabels,
      predictedCategory: predictedCategory,
      distanceToCentroid: minDistToUser,
      userVector: userVector,
    );
  }

  static List<List<double>> _normalizeData(List<List<double>> data) {
    if (data.isEmpty) return data;

    final numFeatures = data.first.length;
    final mins = List<double>.filled(numFeatures, double.infinity);
    final maxs = List<double>.filled(numFeatures, double.negativeInfinity);

    for (var vector in data) {
      for (var i = 0; i < numFeatures; i++) {
        if (vector[i] < mins[i]) mins[i] = vector[i];
        if (vector[i] > maxs[i]) maxs[i] = vector[i];
      }
    }

    return data.map((vector) {
      return List.generate(numFeatures, (i) {
        final range = maxs[i] - mins[i];
        return range > 0 ? (vector[i] - mins[i]) / range : 0.0;
      });
    }).toList();
  }

  static double _euclideanDistance(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += pow(a[i] - b[i], 2);
    }
    return sqrt(sum);
  }

  static Map<int, UserCategory> _assignLabelsBasedOnTotalKm(
    Map<int, List<int>> clusterAssignments,
    List<MonthlyUsageData> allData,
  ) {
    final clusterAvgKm = <int, double>{};

    for (var entry in clusterAssignments.entries) {
      final clusterIdx = entry.key;
      final dataIndices = entry.value;

      if (dataIndices.isEmpty) {
        clusterAvgKm[clusterIdx] = 0.0;
        continue;
      }

      final totalKm = dataIndices.fold<double>(
        0.0,
        (sum, idx) => sum + allData[idx].totalKmPerMonth,
      );
      clusterAvgKm[clusterIdx] = totalKm / dataIndices.length;
    }

    final sortedClusters = clusterAvgKm.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return {
      sortedClusters[0].key: UserCategory.light,
      sortedClusters[1].key: UserCategory.medium,
      sortedClusters[2].key: UserCategory.heavy,
    };
  }
}
