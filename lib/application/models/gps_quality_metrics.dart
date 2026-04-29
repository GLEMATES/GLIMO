import 'package:geolocator/geolocator.dart';

enum GPSQuality {
  excellent,
  good,
  fair,
  poor,
  unavailable,
}

class GPSQualityMetrics {
  final DateTime timestamp;
  final double accuracy;
  final GPSQuality quality;
  final bool isPotentialJump;
  final double? jumpDistance;
  final double? speedKmh;
  final int satelliteCount;

  GPSQualityMetrics({
    required this.timestamp,
    required this.accuracy,
    required this.quality,
    this.isPotentialJump = false,
    this.jumpDistance,
    this.speedKmh,
    this.satelliteCount = 0,
  });

  static GPSQuality getQualityFromAccuracy(double accuracy) {
    if (accuracy <= 5) return GPSQuality.excellent;
    if (accuracy <= 10) return GPSQuality.good;
    if (accuracy <= 20) return GPSQuality.fair;
    if (accuracy <= 50) return GPSQuality.poor;
    return GPSQuality.unavailable;
  }

  static bool detectJump(Position current, Position previous) {
    final distance = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );

    final timeDiff = current.timestamp.difference(previous.timestamp).inSeconds;
    if (timeDiff == 0) return false;

    final speedMps = distance / timeDiff;
    final speedKmh = speedMps * 3.6;

    return speedKmh > 200 || (distance > 100 && timeDiff < 5);
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'accuracy': accuracy,
      'quality': quality.toString().split('.').last,
      'isPotentialJump': isPotentialJump,
      'jumpDistance': jumpDistance,
      'speedKmh': speedKmh,
      'satelliteCount': satelliteCount,
    };
  }

  factory GPSQualityMetrics.fromJson(Map<String, dynamic> json) {
    return GPSQualityMetrics(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      accuracy: json['accuracy'],
      quality: GPSQuality.values.firstWhere(
        (e) => e.toString().split('.').last == json['quality'],
      ),
      isPotentialJump: json['isPotentialJump'] ?? false,
      jumpDistance: json['jumpDistance'],
      speedKmh: json['speedKmh'],
      satelliteCount: json['satelliteCount'] ?? 0,
    );
  }
}

class TrackingSessionMetrics {
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<GPSQualityMetrics> qualityMetrics;
  final List<SegmentData> segments;
  final double totalDistanceHaversine;
  final int totalGPSPoints;
  final int jumpCount;
  final double averageAccuracy;
  final double excellentQualityPercentage;
  final double goodQualityPercentage;
  final double fairQualityPercentage;
  final double poorQualityPercentage;
  final int gapCount;
  final double maxGapDuration;

  TrackingSessionMetrics({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    required this.qualityMetrics,
    required this.segments,
    required this.totalDistanceHaversine,
    required this.totalGPSPoints,
    required this.jumpCount,
    required this.averageAccuracy,
    required this.excellentQualityPercentage,
    required this.goodQualityPercentage,
    required this.fairQualityPercentage,
    required this.poorQualityPercentage,
    required this.gapCount,
    required this.maxGapDuration,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'qualityMetrics': qualityMetrics.map((m) => m.toJson()).toList(),
      'segments': segments.map((s) => s.toJson()).toList(),
      'totalDistanceHaversine': totalDistanceHaversine,
      'totalGPSPoints': totalGPSPoints,
      'jumpCount': jumpCount,
      'averageAccuracy': averageAccuracy,
      'excellentQualityPercentage': excellentQualityPercentage,
      'goodQualityPercentage': goodQualityPercentage,
      'fairQualityPercentage': fairQualityPercentage,
      'poorQualityPercentage': poorQualityPercentage,
      'gapCount': gapCount,
      'maxGapDuration': maxGapDuration,
    };
  }
}

class SegmentData {
  final int segmentIndex;
  final DateTime startTime;
  final DateTime endTime;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final double distanceHaversine;
  final double startAccuracy;
  final double endAccuracy;
  final double durationSeconds;
  final double speedKmh;

  SegmentData({
    required this.segmentIndex,
    required this.startTime,
    required this.endTime,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.distanceHaversine,
    required this.startAccuracy,
    required this.endAccuracy,
    required this.durationSeconds,
    required this.speedKmh,
  });

  Map<String, dynamic> toJson() {
    return {
      'segmentIndex': segmentIndex,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'startLat': startLat,
      'startLng': startLng,
      'endLat': endLat,
      'endLng': endLng,
      'distanceHaversine': distanceHaversine,
      'startAccuracy': startAccuracy,
      'endAccuracy': endAccuracy,
      'durationSeconds': durationSeconds,
      'speedKmh': speedKmh,
    };
  }
}
