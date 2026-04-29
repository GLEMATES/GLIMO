import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import '../models/gps_quality_metrics.dart';

class TrackingMetricsService {
  static Future<TrackingSessionMetrics> generateSessionMetrics({
    required String sessionId,
    required DateTime startTime,
    DateTime? endTime,
    required List<Position> positions,
    required List<GPSQualityMetrics> qualityMetrics,
    required List<SegmentData> segments,
    required double totalDistance,
  }) async {
    final jumpCount = qualityMetrics.where((m) => m.isPotentialJump).length;

    final avgAccuracy = qualityMetrics.isEmpty
        ? 0.0
        : qualityMetrics.map((m) => m.accuracy).reduce((a, b) => a + b) / qualityMetrics.length;

    final excellentCount = qualityMetrics.where((m) => m.quality == GPSQuality.excellent).length;
    final goodCount = qualityMetrics.where((m) => m.quality == GPSQuality.good).length;
    final fairCount = qualityMetrics.where((m) => m.quality == GPSQuality.fair).length;
    final poorCount = qualityMetrics.where((m) => m.quality == GPSQuality.poor).length;
    final total = qualityMetrics.length;

    final excellentPct = total > 0 ? (excellentCount / total) * 100 : 0.0;
    final goodPct = total > 0 ? (goodCount / total) * 100 : 0.0;
    final fairPct = total > 0 ? (fairCount / total) * 100 : 0.0;
    final poorPct = total > 0 ? (poorCount / total) * 100 : 0.0;

    int gapCount = 0;
    double maxGapDuration = 0.0;

    for (int i = 1; i < positions.length; i++) {
      final timeDiff = positions[i].timestamp.difference(positions[i - 1].timestamp).inSeconds;
      if (timeDiff > 30) {
        gapCount++;
        if (timeDiff > maxGapDuration) {
          maxGapDuration = timeDiff.toDouble();
        }
      }
    }

    return TrackingSessionMetrics(
      sessionId: sessionId,
      startTime: startTime,
      endTime: endTime,
      qualityMetrics: qualityMetrics,
      segments: segments,
      totalDistanceHaversine: totalDistance,
      totalGPSPoints: positions.length,
      jumpCount: jumpCount,
      averageAccuracy: avgAccuracy,
      excellentQualityPercentage: excellentPct,
      goodQualityPercentage: goodPct,
      fairQualityPercentage: fairPct,
      poorQualityPercentage: poorPct,
      gapCount: gapCount,
      maxGapDuration: maxGapDuration,
    );
  }

  static Future<String> exportToCSV(TrackingSessionMetrics metrics) async {
    final buffer = StringBuffer();

    buffer.writeln('GLIMO GPS Tracking Test - Haversine Method');
    buffer.writeln('Session ID,${metrics.sessionId}');
    buffer.writeln('Start Time,${metrics.startTime.toIso8601String()}');
    buffer.writeln('End Time,${metrics.endTime?.toIso8601String() ?? 'N/A'}');
    buffer.writeln('Total GPS Points,${metrics.totalGPSPoints}');
    buffer.writeln('Total Distance (Haversine),${metrics.totalDistanceHaversine.toStringAsFixed(6)} km');
    buffer.writeln('Average Accuracy,${metrics.averageAccuracy.toStringAsFixed(2)} m');
    buffer.writeln('Jump Count,${metrics.jumpCount}');
    buffer.writeln('Gap Count (>30s),${metrics.gapCount}');
    buffer.writeln('Max Gap Duration,${metrics.maxGapDuration.toStringAsFixed(0)} s');
    buffer.writeln('');

    buffer.writeln('GPS Quality Distribution');
    buffer.writeln('Excellent (≤5m),${metrics.excellentQualityPercentage.toStringAsFixed(2)}%');
    buffer.writeln('Good (≤10m),${metrics.goodQualityPercentage.toStringAsFixed(2)}%');
    buffer.writeln('Fair (≤20m),${metrics.fairQualityPercentage.toStringAsFixed(2)}%');
    buffer.writeln('Poor (≤50m),${metrics.poorQualityPercentage.toStringAsFixed(2)}%');
    buffer.writeln('');

    buffer.writeln('Segment Data');
    buffer.writeln('Index,Start Time,End Time,Start Lat,Start Lng,End Lat,End Lng,Distance (km),Start Accuracy (m),End Accuracy (m),Duration (s),Speed (km/h)');

    for (final segment in metrics.segments) {
      buffer.writeln(
        '${segment.segmentIndex},'
        '${segment.startTime.toIso8601String()},'
        '${segment.endTime.toIso8601String()},'
        '${segment.startLat},'
        '${segment.startLng},'
        '${segment.endLat},'
        '${segment.endLng},'
        '${segment.distanceHaversine.toStringAsFixed(6)},'
        '${segment.startAccuracy.toStringAsFixed(2)},'
        '${segment.endAccuracy.toStringAsFixed(2)},'
        '${segment.durationSeconds.toStringAsFixed(1)},'
        '${segment.speedKmh.toStringAsFixed(2)}'
      );
    }
    buffer.writeln('');

    buffer.writeln('Quality Metrics');
    buffer.writeln('Timestamp,Accuracy (m),Quality,Is Jump,Jump Distance (m),Speed (km/h)');

    for (final quality in metrics.qualityMetrics) {
      buffer.writeln(
        '${quality.timestamp.toIso8601String()},'
        '${quality.accuracy.toStringAsFixed(2)},'
        '${quality.quality.toString().split('.').last},'
        '${quality.isPotentialJump},'
        '${quality.jumpDistance?.toStringAsFixed(2) ?? 'N/A'},'
        '${quality.speedKmh?.toStringAsFixed(2) ?? 'N/A'}'
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/glimo_tracking_${metrics.sessionId}.csv');
    await file.writeAsString(buffer.toString());

    return file.path;
  }

  static Future<void> shareMetrics(TrackingSessionMetrics metrics) async {
    final filePath = await exportToCSV(metrics);
    final text = 'GPS Tracking Test Results\n'
          'Distance: ${metrics.totalDistanceHaversine.toStringAsFixed(2)} km\n'
          'Points: ${metrics.totalGPSPoints}\n'
          'Avg Accuracy: ${metrics.averageAccuracy.toStringAsFixed(2)} m\n\n'
          'CSV exported to: $filePath';

    await share_plus.SharePlus.instance.share(
      share_plus.ShareParams(text: text),
    );
  }

  static String generateSummaryText(TrackingSessionMetrics metrics) {
    return '''
=== GLIMO GPS Tracking Test ===
Method: Haversine

Session: ${metrics.sessionId}
Start: ${metrics.startTime}
End: ${metrics.endTime ?? 'In Progress'}

--- Distance & Coverage ---
Total Distance: ${metrics.totalDistanceHaversine.toStringAsFixed(3)} km
GPS Points: ${metrics.totalGPSPoints}
Segments: ${metrics.segments.length}

--- GPS Quality ---
Average Accuracy: ${metrics.averageAccuracy.toStringAsFixed(2)} m
Excellent (≤5m): ${metrics.excellentQualityPercentage.toStringAsFixed(1)}%
Good (≤10m): ${metrics.goodQualityPercentage.toStringAsFixed(1)}%
Fair (≤20m): ${metrics.fairQualityPercentage.toStringAsFixed(1)}%
Poor (≤50m): ${metrics.poorQualityPercentage.toStringAsFixed(1)}%

--- Issues Detection ---
GPS Jumps: ${metrics.jumpCount}
Signal Gaps (>30s): ${metrics.gapCount}
Max Gap: ${metrics.maxGapDuration.toStringAsFixed(0)}s
''';
  }
}
