import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class GeocodingService {
  /// Convert coordinates to readable address
  /// Returns formatted address string or null if failed
  static Future<String?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      return _formatPlacemark(place);
    } catch (e) {
      debugPrint('Geocoding error: $e');
      return null;
    }
  }

  /// Format placemark to readable Indonesian address
  static String _formatPlacemark(Placemark place) {
    List<String> parts = [];

    // Add street if available
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }

    // Add subLocality (kelurahan/desa)
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }

    // Add locality (kota/kabupaten)
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }

    // Add administrative area (provinsi)
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }

    // If no parts available, use country
    if (parts.isEmpty && place.country != null) {
      parts.add(place.country!);
    }

    return parts.isEmpty ? 'Lokasi tidak diketahui' : parts.join(', ');
  }

  /// Get short address (just street and city)
  static Future<String?> getShortAddress({
    required double latitude,
    required double longitude,
  }) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      List<String> parts = [];

      // Street or subLocality
      if (place.street != null && place.street!.isNotEmpty) {
        parts.add(place.street!);
      } else if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        parts.add(place.subLocality!);
      }

      // City
      if (place.locality != null && place.locality!.isNotEmpty) {
        parts.add(place.locality!);
      }

      return parts.isEmpty ? null : parts.join(', ');
    } catch (e) {
      debugPrint('Geocoding error: $e');
      return null;
    }
  }

  /// Format coordinates to display string
  static String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}
