import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'trip_history_provider.dart';

/// Statistics data class
class TripStatistics {
  // Monthly stats
  final int monthlyTripCount;
  final double monthlyTotalDistance;
  final double monthlyAverageDistance;
  final int monthlyTotalDuration; // in seconds

  // Personal records
  final TripHistory? longestTrip;
  final TripHistory? shortestTrip;
  final TripHistory? fastestTrip; // highest average speed
  final String? mostActiveDay;
  final int mostActiveDayCount;

  // Favorite locations (top 3)
  final List<LocationFrequency> favoriteLocations;

  TripStatistics({
    required this.monthlyTripCount,
    required this.monthlyTotalDistance,
    required this.monthlyAverageDistance,
    required this.monthlyTotalDuration,
    this.longestTrip,
    this.shortestTrip,
    this.fastestTrip,
    this.mostActiveDay,
    required this.mostActiveDayCount,
    required this.favoriteLocations,
  });

  static TripStatistics empty() {
    return TripStatistics(
      monthlyTripCount: 0,
      monthlyTotalDistance: 0,
      monthlyAverageDistance: 0,
      monthlyTotalDuration: 0,
      mostActiveDayCount: 0,
      favoriteLocations: [],
    );
  }
}

/// Location frequency class
class LocationFrequency {
  final String location;
  final int count;

  LocationFrequency({
    required this.location,
    required this.count,
  });
}

/// Statistics provider
final statisticsProvider = Provider<TripStatistics>((ref) {
  final allTrips = ref.watch(tripHistoryProvider);

  if (allTrips.isEmpty) {
    return TripStatistics.empty();
  }

  // Get current month trips
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final monthlyTrips = allTrips.where((trip) {
    return trip.date.isAfter(startOfMonth) ||
           trip.date.isAtSameMomentAs(startOfMonth);
  }).toList();

  // Calculate monthly stats
  final monthlyTripCount = monthlyTrips.length;
  final monthlyTotalDistance = monthlyTrips.fold<double>(
    0.0,
    (sum, trip) => sum + trip.distance,
  );
  final monthlyAverageDistance = monthlyTripCount > 0
      ? monthlyTotalDistance / monthlyTripCount
      : 0.0;
  final monthlyTotalDuration = monthlyTrips.fold<int>(
    0,
    (sum, trip) => sum + (trip.duration ?? 0),
  );

  // Find personal records
  TripHistory? longestTrip;
  TripHistory? shortestTrip;
  TripHistory? fastestTrip;

  for (var trip in allTrips) {
    // Longest trip
    if (longestTrip == null || trip.distance > longestTrip.distance) {
      longestTrip = trip;
    }

    // Shortest trip
    if (shortestTrip == null || trip.distance < shortestTrip.distance) {
      shortestTrip = trip;
    }

    // Fastest trip (only for GPS trips with duration)
    if (trip.source == 'gps' && trip.duration != null && trip.duration! > 0) {
      final avgSpeed = (trip.distance / (trip.duration! / 3600.0)); // km/h
      final currentFastest = fastestTrip;

      if (currentFastest == null ||
          currentFastest.duration == null ||
          currentFastest.duration! == 0) {
        fastestTrip = trip;
      } else {
        final currentSpeed = (currentFastest.distance / (currentFastest.duration! / 3600.0));
        if (avgSpeed > currentSpeed) {
          fastestTrip = trip;
        }
      }
    }
  }

  // Find most active day
  final dayCount = <String, int>{};
  final dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  for (var trip in allTrips) {
    final dayName = dayNames[trip.date.weekday % 7];
    dayCount[dayName] = (dayCount[dayName] ?? 0) + 1;
  }

  String? mostActiveDay;
  int mostActiveDayCount = 0;

  dayCount.forEach((day, count) {
    if (count > mostActiveDayCount) {
      mostActiveDay = day;
      mostActiveDayCount = count;
    }
  });

  // Find favorite locations (from GPS trips)
  final locationCount = <String, int>{};

  for (var trip in allTrips) {
    if (trip.source == 'gps') {
      // Count start location
      if (trip.startLocation != null && trip.startLocation!.isNotEmpty) {
        // Extract city/area from full address
        final location = _extractLocation(trip.startLocation!);
        locationCount[location] = (locationCount[location] ?? 0) + 1;
      }

      // Count end location
      if (trip.endLocation != null && trip.endLocation!.isNotEmpty) {
        final location = _extractLocation(trip.endLocation!);
        locationCount[location] = (locationCount[location] ?? 0) + 1;
      }
    }
  }

  // Sort and get top 3 locations
  final sortedLocations = locationCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final favoriteLocations = sortedLocations
      .take(3)
      .map((entry) => LocationFrequency(
            location: entry.key,
            count: entry.value,
          ))
      .toList();

  return TripStatistics(
    monthlyTripCount: monthlyTripCount,
    monthlyTotalDistance: monthlyTotalDistance,
    monthlyAverageDistance: monthlyAverageDistance,
    monthlyTotalDuration: monthlyTotalDuration,
    longestTrip: longestTrip,
    shortestTrip: shortestTrip,
    fastestTrip: fastestTrip,
    mostActiveDay: mostActiveDay,
    mostActiveDayCount: mostActiveDayCount,
    favoriteLocations: favoriteLocations,
  );
});

/// Extract location name from full address
/// Example: "Jl. Sudirman, Batam Center, Batam" -> "Batam Center"
String _extractLocation(String fullAddress) {
  final parts = fullAddress.split(',').map((s) => s.trim()).toList();

  // Try to get the second part (usually area/district)
  if (parts.length >= 2) {
    return parts[1];
  }

  // Otherwise return first part
  if (parts.isNotEmpty) {
    return parts[0];
  }

  return fullAddress;
}
