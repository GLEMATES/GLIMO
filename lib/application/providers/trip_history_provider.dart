import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'motor_list_provider.dart';

/// Model untuk satu record riwayat perjalanan
class TripHistory {
  final String id; // Unique ID
  final String motorId; // ID motor yang dipakai
  final String motorName; // Nama motor (untuk display)
  final int startOdometer; // Odometer awal (km)
  final int endOdometer; // Odometer akhir (km)
  final double distance; // Jarak tempuh (km) - auto calculated
  final DateTime date; // Tanggal perjalanan
  final String source; // "gps" atau "manual"
  final String? startLocation; // Optional: Lokasi awal (untuk GPS mode)
  final String? endLocation; // Optional: Lokasi akhir (untuk GPS mode)
  final double? startLat; // Optional: GPS coordinates
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final List<Map<String, dynamic>>? routePoints; // Optional: GPS route points for polyline
  final int? duration; // Optional: Duration in seconds
  final double? gpsDistance; // Optional: Actual GPS distance for GPS trips

  TripHistory({
    required this.id,
    required this.motorId,
    required this.motorName,
    required this.startOdometer,
    required this.endOdometer,
    required this.date,
    required this.source,
    this.startLocation,
    this.endLocation,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.routePoints,
    this.duration,
    this.gpsDistance,
  }) : distance = (endOdometer - startOdometer).toDouble();

  /// Get relative time string (e.g., "4 jam lalu", "2 hari lalu")
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Baru saja';
        }
        return '${difference.inMinutes} menit lalu';
      }
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan lalu';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years tahun lalu';
    }
  }

  /// Get formatted distance with unit
  String getFormattedDistance() {
    if (source == 'gps' && gpsDistance != null) {
      return '${gpsDistance!.toStringAsFixed(2)} km';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'motorId': motorId,
      'motorName': motorName,
      'startOdometer': startOdometer,
      'endOdometer': endOdometer,
      'date': date.toIso8601String(),
      'source': source,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'startLat': startLat,
      'startLng': startLng,
      'endLat': endLat,
      'endLng': endLng,
      'routePoints': routePoints,
      'duration': duration,
      'gpsDistance': gpsDistance,
    };
  }

  /// Create dari JSON
  factory TripHistory.fromJson(Map<String, dynamic> json) {
    return TripHistory(
      id: json['id'] ?? '',
      motorId: json['motorId'] ?? '',
      motorName: json['motorName'] ?? '',
      startOdometer: json['startOdometer'] ?? 0,
      endOdometer: json['endOdometer'] ?? 0,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      source: json['source'] ?? 'manual',
      startLocation: json['startLocation'],
      endLocation: json['endLocation'],
      startLat: json['startLat']?.toDouble(),
      startLng: json['startLng']?.toDouble(),
      endLat: json['endLat']?.toDouble(),
      endLng: json['endLng']?.toDouble(),
      routePoints: json['routePoints'] != null
          ? List<Map<String, dynamic>>.from(json['routePoints'])
          : null,
      duration: json['duration'],
      gpsDistance: json['gpsDistance']?.toDouble(),
    );
  }

  /// Create dari Firestore Document
  factory TripHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripHistory(
      id: doc.id,
      motorId: data['motorId'] ?? '',
      motorName: data['motorName'] ?? '',
      startOdometer: data['startOdometer'] ?? 0,
      endOdometer: data['endOdometer'] ?? 0,
      date: data['date'] != null ? (data['date'] as Timestamp).toDate() : DateTime.now(),
      source: data['source'] ?? 'manual',
      startLocation: data['startLocation'],
      endLocation: data['endLocation'],
      startLat: data['startLat']?.toDouble(),
      startLng: data['startLng']?.toDouble(),
      endLat: data['endLat']?.toDouble(),
      endLng: data['endLng']?.toDouble(),
      routePoints: data['routePoints'] != null
          ? List<Map<String, dynamic>>.from(data['routePoints'])
          : null,
      duration: data['duration'],
      gpsDistance: data['gpsDistance']?.toDouble(),
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'motorId': motorId,
      'motorName': motorName,
      'startOdometer': startOdometer,
      'endOdometer': endOdometer,
      'date': Timestamp.fromDate(date),
      'source': source,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'startLat': startLat,
      'startLng': startLng,
      'endLat': endLat,
      'endLng': endLng,
      'routePoints': routePoints,
      'duration': duration,
      'gpsDistance': gpsDistance,
    };
  }
}

/// Notifier untuk manage riwayat perjalanan
class TripHistoryNotifier extends Notifier<List<TripHistory>> {
  @override
  List<TripHistory> build() {
    _loadHistory();
    return [];
  }

  /// Load riwayat dari Firestore (primary) atau SharedPreferences (cache)
  Future<void> _loadHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = [];
        return;
      }

      debugPrint('🔍 [TRIP DEBUG] Loading trips for user: ${user.uid}');
      debugPrint('🔍 [TRIP DEBUG] User email: ${user.email}');

      // Try load from Firestore first
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('trip_history')
          .orderBy('date', descending: true)
          .get();

      debugPrint('🔍 [TRIP DEBUG] Found ${querySnapshot.docs.length} trips in Firestore');

      if (querySnapshot.docs.isNotEmpty) {
        final trips = querySnapshot.docs
            .map((doc) => TripHistory.fromFirestore(doc))
            .toList();
        state = trips;

        // Sync odometer for all motors that have trips
        final motorIds = trips.map((trip) => trip.motorId).toSet();
        for (var motorId in motorIds) {
          await syncMotorOdometer(motorId);
        }

        // Refresh motor list after syncing all odometers
        if (motorIds.isNotEmpty) {
          ref.invalidate(motorListProvider);
        }

        // Save to SharedPreferences as cache
        await _saveToPreferences();
        return;
      }
    } catch (e) {
      // Error loading from Firestore, try cache
    }

    // Fallback to SharedPreferences cache
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final historyJson = prefs.getString('trip_history_${user.uid}');

        if (historyJson != null) {
          final List<dynamic> decoded = jsonDecode(historyJson);
          state = decoded.map((json) => TripHistory.fromJson(json)).toList();
          // Sort by date desc
          state.sort((a, b) => b.date.compareTo(a.date));
        }
      }
    } catch (e) {
      // Error loading from cache
    }
  }

  /// Add manual trip
  Future<void> addManualTrip({
    required String motorId,
    required String motorName,
    required int startOdometer,
    required int endOdometer,
    DateTime? date,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Validation
      if (endOdometer <= startOdometer) {
        throw Exception('Odometer akhir harus lebih besar dari odometer awal');
      }

      final tripDate = date ?? DateTime.now();
      final firestore = FirebaseFirestore.instance;

      // Create new document
      final docRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('trip_history')
          .doc();

      final newTrip = TripHistory(
        id: docRef.id,
        motorId: motorId,
        motorName: motorName,
        startOdometer: startOdometer,
        endOdometer: endOdometer,
        date: tripDate,
        source: 'manual',
      );

      // Save to Firestore
      await docRef.set(newTrip.toFirestore());

      // Update motor odometer to match the trip's end odometer
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('motors')
          .doc(motorId)
          .update({
        'odometer': endOdometer.toString(),
      });

      // Refresh motor list to update UI immediately
      ref.invalidate(motorListProvider);

      // Update local state
      state = [newTrip, ...state];

      // Save to cache
      await _saveToPreferences();
    } catch (e) {
      rethrow;
    }
  }

  /// Add GPS trip with route data
  Future<void> addGPSTrip({
    required String motorId,
    required String motorName,
    required int startOdometer,
    required int endOdometer,
    String? startLocation,
    String? endLocation,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    List<Map<String, dynamic>>? routePoints,
    int? duration,
    double? gpsDistance,
    DateTime? date,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final tripDate = date ?? DateTime.now();
      final firestore = FirebaseFirestore.instance;

      final docRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('trip_history')
          .doc();

      final newTrip = TripHistory(
        id: docRef.id,
        motorId: motorId,
        motorName: motorName,
        startOdometer: startOdometer,
        endOdometer: endOdometer,
        date: tripDate,
        source: 'gps',
        startLocation: startLocation,
        endLocation: endLocation,
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        routePoints: routePoints,
        duration: duration,
        gpsDistance: gpsDistance,
      );

      await docRef.set(newTrip.toFirestore());

      // Update motor odometer to match the trip's end odometer
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('motors')
          .doc(motorId)
          .update({
        'odometer': endOdometer.toString(),
      });

      // Refresh motor list to update UI immediately
      ref.invalidate(motorListProvider);

      state = [newTrip, ...state];
      await _saveToPreferences();
    } catch (e) {
      rethrow;
    }
  }

  /// Sync motor odometer with the latest trip's end odometer
  Future<void> syncMotorOdometer(String motorId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final firestore = FirebaseFirestore.instance;

      // Get all trips for this motor, sorted by date (newest first)
      final motorTrips = state
          .where((trip) => trip.motorId == motorId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      if (motorTrips.isEmpty) {
        // No trips remaining for this motor
        // Reset odometer back to odometerAwal
        final motorDoc = await firestore
            .collection('users')
            .doc(user.uid)
            .collection('motors')
            .doc(motorId)
            .get();

        if (motorDoc.exists) {
          final motorData = motorDoc.data();
          final odometerAwal = motorData?['odometerAwal'] ?? motorData?['odometer_awal'] ?? '0';

          await firestore
              .collection('users')
              .doc(user.uid)
              .collection('motors')
              .doc(motorId)
              .update({
            'odometer': odometerAwal,
          });
        }
        return;
      }

      // Get the latest trip's end odometer
      final latestTrip = motorTrips.first;
      final latestOdometer = latestTrip.endOdometer;

      // Update motor odometer
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('motors')
          .doc(motorId)
          .update({
        'odometer': latestOdometer.toString(),
      });
    } catch (e) {
      // Silently fail - odometer sync is not critical
    }
  }

  /// Delete trip
  Future<void> deleteTrip(String tripId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Find the trip to get motorId before deleting
      final tripToDelete = state.firstWhere((trip) => trip.id == tripId);
      final motorId = tripToDelete.motorId;

      final firestore = FirebaseFirestore.instance;

      // Delete from Firestore
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('trip_history')
          .doc(tripId)
          .delete();

      // Update local state
      state = state.where((trip) => trip.id != tripId).toList();

      // Sync odometer back to latest remaining trip for this motor
      await syncMotorOdometer(motorId);

      // Refresh motor list to update UI immediately
      ref.invalidate(motorListProvider);

      // Save to cache
      await _saveToPreferences();
    } catch (e) {
      rethrow;
    }
  }

  /// Get trips by motor ID
  List<TripHistory> getTripsByMotor(String motorId) {
    return state.where((trip) => trip.motorId == motorId).toList();
  }

  /// Get trips by date range
  List<TripHistory> getTripsByDateRange(DateTime start, DateTime end) {
    return state.where((trip) {
      return trip.date.isAfter(start.subtract(const Duration(days: 1))) &&
          trip.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get total distance for a motor
  double getTotalDistanceForMotor(String motorId) {
    final trips = getTripsByMotor(motorId);
    return trips.fold(0.0, (total, trip) => total + trip.distance);
  }

  /// Save to SharedPreferences (cache)
  Future<void> _saveToPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(state.map((trip) => trip.toJson()).toList());
      await prefs.setString('trip_history_${user.uid}', historyJson);
    } catch (e) {
      // Error saving to cache
    }
  }

  /// Clear all trip history
  Future<void> clearHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('trip_history_${user.uid}');
    }
    state = [];
  }
}

/// Provider untuk trip history
final tripHistoryProvider = NotifierProvider<TripHistoryNotifier, List<TripHistory>>(
  () => TripHistoryNotifier(),
);

/// Provider untuk get recent trips (limit 5)
final recentTripsProvider = Provider<List<TripHistory>>((ref) {
  final allTrips = ref.watch(tripHistoryProvider);
  return allTrips.take(5).toList();
});

/// Provider untuk get trips by motor
final tripsByMotorProvider = Provider.family<List<TripHistory>, String>((ref, motorId) {
  ref.watch(tripHistoryProvider);
  return ref.read(tripHistoryProvider.notifier).getTripsByMotor(motorId);
});
