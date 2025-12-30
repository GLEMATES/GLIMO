import 'dart:math';

class UsageFeatures {
  final double avgKmPerTrip;
  final double totalKmPerMonth;
  final double tripsPerWeek;
  final double trendSlope;

  UsageFeatures({
    required this.avgKmPerTrip,
    required this.totalKmPerMonth,
    required this.tripsPerWeek,
    required this.trendSlope,
  });

  List<double> toVector() => [avgKmPerTrip, totalKmPerMonth, tripsPerWeek, trendSlope];
}

class ClusterResult {
  final int clusterIndex;
  final List<List<double>> centroids;
  final Map<int, String> clusterLabels;

  ClusterResult({
    required this.clusterIndex,
    required this.centroids,
    required this.clusterLabels,
  });

  String get label => clusterLabels[clusterIndex] ?? 'unknown';
}

class KMeansClusterer {
  final int k;
  final int maxIterations;
  final double tolerance;
  final Random _random = Random();

  KMeansClusterer({
    this.k = 3,
    this.maxIterations = 100,
    this.tolerance = 0.001,
  });

  ClusterResult predict(UsageFeatures features, List<UsageFeatures> historicalData) {
    if (historicalData.length < k) {
      return _fallbackClassification(features);
    }

    final dataVectors = historicalData.map((f) => f.toVector()).toList();
    final normalized = _normalizeData([features.toVector(), ...dataVectors]);

    final normalizedFeature = normalized.first;
    final normalizedHistorical = normalized.sublist(1);

    final centroids = _runKMeans(normalizedHistorical);
    final clusterIndex = _assignCluster(normalizedFeature, centroids);
    final labels = _assignLabels(centroids);

    return ClusterResult(
      clusterIndex: clusterIndex,
      centroids: centroids,
      clusterLabels: labels,
    );
  }

  List<List<double>> _normalizeData(List<List<double>> data) {
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

  List<List<double>> _runKMeans(List<List<double>> data) {
    if (data.isEmpty) return [];

    var centroids = _initializeCentroids(data);

    for (var iteration = 0; iteration < maxIterations; iteration++) {
      final clusters = List.generate(k, (_) => <List<double>>[]);

      for (var point in data) {
        final clusterIndex = _assignCluster(point, centroids);
        clusters[clusterIndex].add(point);
      }

      final newCentroids = <List<double>>[];
      for (var i = 0; i < k; i++) {
        if (clusters[i].isEmpty) {
          newCentroids.add(centroids[i]);
        } else {
          newCentroids.add(_calculateCentroid(clusters[i]));
        }
      }

      if (_hasConverged(centroids, newCentroids)) {
        break;
      }

      centroids = newCentroids;
    }

    return centroids;
  }

  List<List<double>> _initializeCentroids(List<List<double>> data) {
    final shuffled = List<List<double>>.from(data)..shuffle(_random);
    return shuffled.take(k).toList();
  }

  int _assignCluster(List<double> point, List<List<double>> centroids) {
    var minDistance = double.infinity;
    var clusterIndex = 0;

    for (var i = 0; i < centroids.length; i++) {
      final distance = _euclideanDistance(point, centroids[i]);
      if (distance < minDistance) {
        minDistance = distance;
        clusterIndex = i;
      }
    }

    return clusterIndex;
  }

  double _euclideanDistance(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += pow(a[i] - b[i], 2);
    }
    return sqrt(sum);
  }

  List<double> _calculateCentroid(List<List<double>> cluster) {
    final numFeatures = cluster.first.length;
    final sums = List<double>.filled(numFeatures, 0.0);

    for (var point in cluster) {
      for (var i = 0; i < numFeatures; i++) {
        sums[i] += point[i];
      }
    }

    return sums.map((sum) => sum / cluster.length).toList();
  }

  bool _hasConverged(List<List<double>> oldCentroids, List<List<double>> newCentroids) {
    for (var i = 0; i < oldCentroids.length; i++) {
      final distance = _euclideanDistance(oldCentroids[i], newCentroids[i]);
      if (distance > tolerance) {
        return false;
      }
    }
    return true;
  }

  Map<int, String> _assignLabels(List<List<double>> centroids) {
    final centroidsWithIndex = centroids.asMap().entries.map((e) {
      final totalKmFeature = e.value.length > 1 ? e.value[1] : 0.0;
      return MapEntry(e.key, totalKmFeature);
    }).toList();

    centroidsWithIndex.sort((a, b) => a.value.compareTo(b.value));

    return {
      centroidsWithIndex[0].key: 'light',
      centroidsWithIndex[1].key: 'medium',
      centroidsWithIndex[2].key: 'heavy',
    };
  }

  ClusterResult _fallbackClassification(UsageFeatures features) {
    final kmPerMonth = features.totalKmPerMonth;

    final label = kmPerMonth < 500
        ? 'light'
        : kmPerMonth < 1500
            ? 'medium'
            : 'heavy';

    final clusterIndex = label == 'light' ? 0 : label == 'medium' ? 1 : 2;

    return ClusterResult(
      clusterIndex: clusterIndex,
      centroids: [],
      clusterLabels: {0: 'light', 1: 'medium', 2: 'heavy'},
    );
  }
}
