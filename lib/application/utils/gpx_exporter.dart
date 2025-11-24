import '../providers/trip_history_provider.dart';

class GPXExporter {
  /// Export trip to GPX format
  static String generateGPX(TripHistory trip) {
    final buffer = StringBuffer();

    // GPX Header
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="GLIMO App"');
    buffer.writeln('  xmlns="http://www.topografix.com/GPX/1/1"');
    buffer.writeln('  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"');
    buffer.writeln('  xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">');

    // Metadata
    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>${trip.motorName} - ${trip.date.toIso8601String()}</name>');
    buffer.writeln('    <desc>Trip from ${trip.startOdometer}km to ${trip.endOdometer}km (${trip.distance}km)</desc>');
    buffer.writeln('    <time>${trip.date.toIso8601String()}</time>');
    buffer.writeln('  </metadata>');

    // Track
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>${trip.motorName} Trip</name>');
    buffer.writeln('    <type>motorcycle</type>');
    buffer.writeln('    <trkseg>');

    // Route points
    if (trip.routePoints != null && trip.routePoints!.isNotEmpty) {
      for (var point in trip.routePoints!) {
        final lat = point['latitude'];
        final lng = point['longitude'];
        final timestamp = point['timestamp'];

        buffer.writeln('      <trkpt lat="$lat" lon="$lng">');

        // Add timestamp if available
        if (timestamp != null) {
          final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
          buffer.writeln('        <time>${dateTime.toIso8601String()}</time>');
        }

        buffer.writeln('      </trkpt>');
      }
    } else {
      // If no route points, use start and end coordinates
      if (trip.startLat != null && trip.startLng != null) {
        buffer.writeln('      <trkpt lat="${trip.startLat}" lon="${trip.startLng}">');
        buffer.writeln('        <time>${trip.date.toIso8601String()}</time>');
        buffer.writeln('      </trkpt>');
      }

      if (trip.endLat != null && trip.endLng != null) {
        final endTime = trip.duration != null
            ? trip.date.add(Duration(seconds: trip.duration!))
            : trip.date;
        buffer.writeln('      <trkpt lat="${trip.endLat}" lon="${trip.endLng}">');
        buffer.writeln('        <time>${endTime.toIso8601String()}</time>');
        buffer.writeln('      </trkpt>');
      }
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');

    // Waypoints for start and end
    if (trip.startLat != null && trip.startLng != null) {
      buffer.writeln('  <wpt lat="${trip.startLat}" lon="${trip.startLng}">');
      buffer.writeln('    <name>Start</name>');
      if (trip.startLocation != null) {
        buffer.writeln('    <desc>${trip.startLocation}</desc>');
      }
      buffer.writeln('    <sym>Flag, Green</sym>');
      buffer.writeln('  </wpt>');
    }

    if (trip.endLat != null && trip.endLng != null) {
      buffer.writeln('  <wpt lat="${trip.endLat}" lon="${trip.endLng}">');
      buffer.writeln('    <name>End</name>');
      if (trip.endLocation != null) {
        buffer.writeln('    <desc>${trip.endLocation}</desc>');
      }
      buffer.writeln('    <sym>Flag, Red</sym>');
      buffer.writeln('  </wpt>');
    }

    buffer.writeln('</gpx>');

    return buffer.toString();
  }

  /// Generate filename for GPX export
  static String generateFilename(TripHistory trip) {
    final dateStr = trip.date.toIso8601String().split('T')[0];
    final motorName = trip.motorName.replaceAll(' ', '_').replaceAll('-', '_');
    return 'GLIMO_${motorName}_${dateStr}_${trip.distance}km.gpx';
  }
}
