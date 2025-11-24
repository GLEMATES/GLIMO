import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/background_tracking_service.dart';
import '../services/activity_recognition_service.dart';
import 'tracking_mode_provider.dart';
import 'trip_history_provider.dart';
import 'motor_list_provider.dart';
import '../utils/geocoding_service.dart';
import 'debug_panel_provider.dart';

/// Tracking status enum
enum TrackingStatus {
  idle,     // Not tracking
  tracking, // Currently tracking
  paused,   // Paused tracking
}

/// GPS Tracking State
class GPSTrackingState {
  final TrackingStatus status;
  final List<Position> positions;
  final DateTime? startTime;
  final DateTime? endTime;
  final double totalDistance; // in kilometers

  GPSTrackingState({
    required this.status,
    required this.positions,
    this.startTime,
    this.endTime,
    required this.totalDistance,
  });

  GPSTrackingState copyWith({
    TrackingStatus? status,
    List<Position>? positions,
    DateTime? startTime,
    DateTime? endTime,
    double? totalDistance,
  }) {
    return GPSTrackingState(
      status: status ?? this.status,
      positions: positions ?? this.positions,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalDistance: totalDistance ?? this.totalDistance,
    );
  }

  // Get current position if available
  Position? get currentPosition => positions.isNotEmpty ? positions.last : null;

  // Get start position
  Position? get startPosition => positions.isNotEmpty ? positions.first : null;

  // Get duration
  Duration? get duration {
    if (startTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }

  // Get formatted duration
  String getFormattedDuration() {
    final d = duration;
    if (d == null) return '00:00:00';

    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  // Get polyline for map
  List<LatLng> getPolylinePoints() {
    return positions.map((pos) => LatLng(pos.latitude, pos.longitude)).toList();
  }
}

/// GPS Tracking Notifier
class GPSTrackingNotifier extends Notifier<GPSTrackingState> {
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _durationTimer;
  Timer? _autoSaveTimer;
  Timer? _autoStopTimer;

  final ActivityRecognitionService _activityService = ActivityRecognitionService();
  UserActivityType _lastActivity = UserActivityType.unknown;

  // Minimum trip requirements (adjusted for real-world usage)
  static const double minTripDistance = 0.3; // km (300 meters - reasonable for city trips)
  static const int minTripDuration = 30; // seconds (30 seconds minimum)
  static const int minPositionCount = 5; // number of positions (reduced for quick trips)

  // Auto-save interval
  static const int autoSaveIntervalSeconds = 30; // Save every 30 seconds

  // Auto-stop delay (for automatic mode)
  static const int autoStopDelaySeconds = 120; // 2 minutes after detecting STILL/WALKING

  // Location settings
  static const double distanceFilter = 10.0; // meters - update every 10 meters

  @override
  GPSTrackingState build() {
    // Cleanup when provider is disposed
    ref.onDispose(() {
      _positionStreamSubscription?.cancel();
      _durationTimer?.cancel();
      _autoSaveTimer?.cancel();
      _autoStopTimer?.cancel();
      _activityService.stopListening();
    });

    // Initialize activity recognition
    _initActivityRecognition();

    // Try to recover previous tracking session
    _tryRecoverTracking();

    return GPSTrackingState(
      status: TrackingStatus.idle,
      positions: [],
      totalDistance: 0.0,
    );
  }

  /// Try to recover tracking from previous session
  Future<void> _tryRecoverTracking() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final trackingData = prefs.getString('active_tracking_${user.uid}');

      if (trackingData != null) {
        final Map<String, dynamic> data = jsonDecode(trackingData);
        final status = data['status'] as String;

        // Only recover if status was tracking or paused
        if (status == 'tracking' || status == 'paused') {
          final positions = (data['positions'] as List)
              .map((p) => Position(
                    latitude: p['latitude'],
                    longitude: p['longitude'],
                    timestamp: DateTime.fromMillisecondsSinceEpoch(p['timestamp']),
                    accuracy: p['accuracy'] ?? 0.0,
                    altitude: p['altitude'] ?? 0.0,
                    heading: p['heading'] ?? 0.0,
                    speed: p['speed'] ?? 0.0,
                    speedAccuracy: p['speedAccuracy'] ?? 0.0,
                    altitudeAccuracy: p['altitudeAccuracy'] ?? 0.0,
                    headingAccuracy: p['headingAccuracy'] ?? 0.0,
                  ))
              .toList();

          state = GPSTrackingState(
            status: TrackingStatus.paused, // Set to paused for safety
            positions: positions,
            startTime: DateTime.parse(data['startTime']),
            totalDistance: data['totalDistance']?.toDouble() ?? 0.0,
          );
        }
      }
    } catch (e) {
      // Ignore recovery errors
    }
  }

  /// Initialize activity recognition for automatic mode
  Future<void> _initActivityRecognition() async {
    try {
      final trackingMode = ref.read(trackingModeProvider);

      debugPrint('🎯 [GPS TRACKING] Initializing activity recognition...');
      debugPrint('   Mode: ${trackingMode.mode}');

      final hasPermission = await _activityService.hasPermission();

      if (!hasPermission) {
        debugPrint('⚠️ [GPS TRACKING] Activity recognition permission not granted');
        final granted = await _activityService.requestPermission();

        if (!granted) {
          debugPrint('❌ [GPS TRACKING] Activity recognition permission denied');
          ref.read(trackingModeProvider.notifier).setActivityRecognitionAvailable(false);
          return;
        }
      }

      debugPrint('✅ [GPS TRACKING] Activity recognition permission granted');
      ref.read(trackingModeProvider.notifier).setActivityRecognitionAvailable(true);

      _activityService.onActivityChanged = _onActivityChanged;

      await _activityService.startListening();

      debugPrint('✅ [GPS TRACKING] Activity recognition started');
    } catch (e) {
      debugPrint('❌ [GPS TRACKING] Failed to initialize activity recognition: $e');
      ref.read(trackingModeProvider.notifier).setActivityRecognitionAvailable(false);
    }
  }

  /// Handle activity changes for automatic mode
  void _onActivityChanged(UserActivityType activity, int confidence) {
    final trackingMode = ref.read(trackingModeProvider);

    debugPrint('🎯 [GPS TRACKING] Activity changed: ${_activityService.getActivityName(activity)} ($confidence%)');
    debugPrint('   Current status: ${state.status}');
    debugPrint('   Tracking mode: ${trackingMode.mode}');

    ref.read(debugPanelProvider.notifier).addEvent(
      '${_activityService.getActivityName(activity)} ($confidence%)',
      DebugEventType.activityChange,
    );

    if (!trackingMode.isActivityRecognitionAvailable) {
      debugPrint('⚠️ [GPS TRACKING] Activity recognition not available, skipping');
      ref.read(debugPanelProvider.notifier).addEvent(
        'Activity recognition not available',
        DebugEventType.warning,
      );
      return;
    }

    if (trackingMode.mode != TrackingMode.automatic) {
      debugPrint('⚠️ [GPS TRACKING] Not in automatic mode, skipping');
      return;
    }

    _lastActivity = activity;

    if (activity == UserActivityType.inVehicle) {
      _cancelAutoStop();

      if (state.status == TrackingStatus.idle) {
        debugPrint('🚗 [GPS TRACKING] Vehicle detected, auto-starting tracking...');
        ref.read(debugPanelProvider.notifier).addEvent(
          'IN_VEHICLE detected → Auto-starting tracking',
          DebugEventType.trackingStart,
        );
        startTracking();
      } else {
        debugPrint('🚗 [GPS TRACKING] Vehicle detected, but already tracking');
        ref.read(debugPanelProvider.notifier).addEvent(
          'IN_VEHICLE detected (already tracking)',
          DebugEventType.info,
        );
      }
    } else if (activity == UserActivityType.still || activity == UserActivityType.walking) {
      if (state.status == TrackingStatus.tracking) {
        debugPrint('🧍 [GPS TRACKING] Still/Walking detected, scheduling auto-stop in ${autoStopDelaySeconds}s...');
        ref.read(debugPanelProvider.notifier).addEvent(
          'STILL/WALKING detected → Auto-stop timer: ${autoStopDelaySeconds}s',
          DebugEventType.autoStopScheduled,
        );
        _scheduleAutoStop();
      } else {
        debugPrint('🧍 [GPS TRACKING] Still/Walking detected, but not tracking');
      }
    }

    _updateDebugStatus();
  }

  /// Schedule auto-stop after delay
  void _scheduleAutoStop() {
    _cancelAutoStop();

    debugPrint('⏰ [GPS TRACKING] Auto-stop timer started (${autoStopDelaySeconds}s)');

    _autoStopTimer = Timer(Duration(seconds: autoStopDelaySeconds), () {
      debugPrint('⏰ [GPS TRACKING] Auto-stop timer expired');

      if (_lastActivity == UserActivityType.still || _lastActivity == UserActivityType.walking) {
        debugPrint('🛑 [GPS TRACKING] Auto-stopping tracking with auto-save...');
        stopTracking(autoSave: true);
      } else {
        debugPrint('⚠️ [GPS TRACKING] Activity changed, not auto-stopping');
      }
    });
  }

  /// Cancel auto-stop timer
  void _cancelAutoStop() {
    if (_autoStopTimer != null) {
      debugPrint('⏰ [GPS TRACKING] Auto-stop timer cancelled');
      ref.read(debugPanelProvider.notifier).addEvent(
        'Auto-stop timer cancelled',
        DebugEventType.autoStopCancelled,
      );
      _autoStopTimer?.cancel();
      _autoStopTimer = null;
      _updateDebugStatus();
    }
  }

  /// Auto-save tracking state to prevent data loss
  Future<void> _autoSaveTracking() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (state.status == TrackingStatus.idle) {
        // Clear saved data if idle
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('active_tracking_${user.uid}');
        return;
      }

      final data = {
        'status': state.status.toString().split('.').last,
        'positions': state.positions.map((p) => {
          'latitude': p.latitude,
          'longitude': p.longitude,
          'timestamp': p.timestamp.millisecondsSinceEpoch,
          'accuracy': p.accuracy,
          'altitude': p.altitude,
          'heading': p.heading,
          'speed': p.speed,
          'speedAccuracy': p.speedAccuracy,
          'altitudeAccuracy': p.altitudeAccuracy,
          'headingAccuracy': p.headingAccuracy,
        }).toList(),
        'startTime': state.startTime?.toIso8601String(),
        'totalDistance': state.totalDistance,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_tracking_${user.uid}', jsonEncode(data));
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Check if trip meets minimum requirements
  bool meetsMinimumRequirements() {
    if (state.positions.length < minPositionCount) return false;
    if (state.totalDistance < minTripDistance) return false;
    final duration = state.duration?.inSeconds ?? 0;
    if (duration < minTripDuration) return false;
    return true;
  }

  /// Get requirements check message
  String getRequirementsMessage() {
    final posCount = state.positions.length;
    final distance = state.totalDistance;
    final duration = state.duration?.inSeconds ?? 0;

    if (posCount < minPositionCount) {
      return 'Trip terlalu pendek. Minimal $minPositionCount GPS points diperlukan (saat ini: $posCount)';
    }
    if (distance < minTripDistance) {
      return 'Jarak terlalu pendek. Minimal ${minTripDistance}km diperlukan (saat ini: ${distance.toStringAsFixed(2)}km)';
    }
    if (duration < minTripDuration) {
      final minMinutes = (minTripDuration / 60).floor();
      final currentMinutes = (duration / 60).floor();
      return 'Durasi terlalu singkat. Minimal $minMinutes menit diperlukan (saat ini: $currentMinutes menit)';
    }
    return '';
  }

  /// Start tracking trip
  Future<void> startTracking() async {
    // Check permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Get initial position
    Position initialPosition = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter.toInt(),
      ),
    );

    // Update state
    state = GPSTrackingState(
      status: TrackingStatus.tracking,
      positions: [initialPosition],
      startTime: DateTime.now(),
      totalDistance: 0.0,
    );

    // Start listening to position stream
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter.toInt(),
      ),
    ).listen(
      (Position position) {
        _addPosition(position);
      },
      onError: (error) {
        // Handle error
        stopTracking();
      },
    );

    // Start duration timer for UI updates
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == TrackingStatus.tracking) {
        // Trigger rebuild for duration update
        state = state.copyWith();
      }
    });

    // Start auto-save timer
    _autoSaveTimer = Timer.periodic(
      Duration(seconds: autoSaveIntervalSeconds),
      (timer) => _autoSaveTracking(),
    );

    // Save initial state immediately
    await _autoSaveTracking();

    // Start background service for tracking even when app is closed
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await BackgroundTrackingService.startTracking(user.uid);
      } catch (e) {
        // Background service failed to start, but foreground tracking still works
      }
    }
  }

  /// Add position and calculate distance
  void _addPosition(Position position) {
    if (state.status != TrackingStatus.tracking) return;

    final positions = List<Position>.from(state.positions);
    final lastPosition = positions.last;

    // Calculate distance from last position
    double distance = Geolocator.distanceBetween(
      lastPosition.latitude,
      lastPosition.longitude,
      position.latitude,
      position.longitude,
    );

    // Convert to kilometers
    double distanceInKm = distance / 1000;

    // Add position
    positions.add(position);

    // Update state
    state = state.copyWith(
      positions: positions,
      totalDistance: state.totalDistance + distanceInKm,
    );
  }

  /// Pause tracking
  void pauseTracking() {
    if (state.status != TrackingStatus.tracking) return;

    _positionStreamSubscription?.pause();
    state = state.copyWith(status: TrackingStatus.paused);
  }

  /// Resume tracking
  void resumeTracking() {
    if (state.status != TrackingStatus.paused) return;

    _positionStreamSubscription?.resume();
    state = state.copyWith(status: TrackingStatus.tracking);
  }

  /// Stop tracking
  Future<void> stopTracking({bool autoSave = false}) async {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _cancelAutoStop();

    state = state.copyWith(
      status: TrackingStatus.idle,
      endTime: DateTime.now(),
    );

    // Stop background service
    await BackgroundTrackingService.stopTracking();

    // Auto-save trip for automatic mode
    if (autoSave) {
      await _autoSaveTripToHistory();
    }

    // Clear saved tracking data
    await _autoSaveTracking();
  }

  Future<void> _autoSaveTripToHistory() async {
    try {
      debugPrint('💾 [AUTO-SAVE] Attempting to auto-save trip...');
      ref.read(debugPanelProvider.notifier).addEvent(
        'Attempting to auto-save trip...',
        DebugEventType.autoSave,
      );

      if (!meetsMinimumRequirements()) {
        debugPrint('⚠️ [AUTO-SAVE] Trip does not meet minimum requirements');
        debugPrint('   ${getRequirementsMessage()}');
        ref.read(debugPanelProvider.notifier).addEvent(
          'Trip too short: ${getRequirementsMessage()}',
          DebugEventType.warning,
        );
        return;
      }

      final activeMotor = ref.read(motorListProvider.notifier).getActiveMotor();
      if (activeMotor == null) {
        debugPrint('⚠️ [AUTO-SAVE] No active motor found');
        ref.read(debugPanelProvider.notifier).addEvent(
          'No active motor found',
          DebugEventType.error,
        );
        return;
      }

      debugPrint('✅ [AUTO-SAVE] Active motor: ${activeMotor.model}');

      final trackingSummary = getTrackingSummary();
      final gpsDistance = (trackingSummary['distance'] as double? ?? 0.0);
      final duration = trackingSummary['duration'] as int? ?? 0;
      final startLat = trackingSummary['startLatitude'] as double;
      final startLng = trackingSummary['startLongitude'] as double;
      final endLat = trackingSummary['endLatitude'] as double;
      final endLng = trackingSummary['endLongitude'] as double;
      final routePoints = trackingSummary['positions'] as List<Map<String, dynamic>>;

      final startLocation = await GeocodingService.getAddressFromCoordinates(
        latitude: startLat,
        longitude: startLng,
      );
      final endLocation = await GeocodingService.getAddressFromCoordinates(
        latitude: endLat,
        longitude: endLng,
      );

      final currentOdometer = int.tryParse(activeMotor.odometer) ?? 0;
      final startOdometer = currentOdometer;
      final endOdometer = currentOdometer + gpsDistance.ceil();

      debugPrint('💾 [AUTO-SAVE] Saving trip:');
      debugPrint('   Distance: ${gpsDistance.toStringAsFixed(2)} km');
      debugPrint('   Duration: ${duration}s');
      debugPrint('   Odometer: $startOdometer → $endOdometer km');
      debugPrint('   From: $startLocation');
      debugPrint('   To: $endLocation');

      ref.read(debugPanelProvider.notifier).addEvent(
        'Saving trip: ${gpsDistance.toStringAsFixed(2)} km',
        DebugEventType.autoSave,
      );

      await ref.read(tripHistoryProvider.notifier).addGPSTrip(
        motorId: activeMotor.id,
        motorName: '${activeMotor.model} - ${activeMotor.type}',
        startOdometer: startOdometer,
        endOdometer: endOdometer,
        startLocation: startLocation,
        endLocation: endLocation,
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        routePoints: routePoints,
        duration: duration,
        gpsDistance: gpsDistance,
        date: state.startTime,
      );

      debugPrint('✅ [AUTO-SAVE] Trip saved successfully!');

      ref.read(debugPanelProvider.notifier).addEvent(
        'Trip saved successfully!',
        DebugEventType.success,
      );

      ref.read(debugPanelProvider.notifier).updateLastTripSummary({
        'distance': '${gpsDistance.toStringAsFixed(2)} km',
        'duration': '${(duration / 60).floor()}m ${duration % 60}s',
        'motor': '${activeMotor.model} - ${activeMotor.type}',
        'odometer': '$startOdometer → $endOdometer km',
        'from': startLocation ?? '-',
        'to': endLocation ?? '-',
      });

      await clearSavedTracking();
    } catch (e) {
      debugPrint('❌ [AUTO-SAVE] Failed to save trip: $e');
      ref.read(debugPanelProvider.notifier).addEvent(
        'Failed to save trip: $e',
        DebugEventType.error,
      );
    }
  }

  /// Reset tracking (clear all data)
  Future<void> resetTracking() async {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _cancelAutoStop();

    state = GPSTrackingState(
      status: TrackingStatus.idle,
      positions: [],
      totalDistance: 0.0,
    );

    // Stop background service
    await BackgroundTrackingService.stopTracking();

    // Clear saved tracking data
    await _autoSaveTracking();
  }

  /// Clear saved tracking data (call after successful save)
  Future<void> clearSavedTracking() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_tracking_${user.uid}');
    } catch (e) {
      // Ignore errors
    }
  }

  void _updateDebugStatus() {
    final trackingMode = ref.read(trackingModeProvider);
    String statusText;
    String activityText = _activityService.getActivityName(_lastActivity);

    switch (state.status) {
      case TrackingStatus.idle:
        statusText = '⏸️ IDLE';
        break;
      case TrackingStatus.tracking:
        statusText = '✅ TRACKING';
        break;
      case TrackingStatus.paused:
        statusText = '⏸️ PAUSED';
        break;
    }

    String autoStopStatus = _autoStopTimer != null ? '⏰ Active (2m)' : '⏸️ Standby';

    ref.read(debugPanelProvider.notifier).updateCurrentStatus({
      'mode': trackingMode.mode == TrackingMode.automatic ? '⚙️ OTOMATIS' : '🖐️ MANUAL',
      'tracking': statusText,
      'activity': activityText,
      'distance': state.status == TrackingStatus.tracking
        ? '${state.totalDistance.toStringAsFixed(2)} km'
        : '-',
      'duration': state.status == TrackingStatus.tracking
        ? state.getFormattedDuration()
        : '-',
      'autoStopTimer': autoStopStatus,
    });
  }

  Map<String, dynamic> getTrackingSummary() {
    if (state.positions.length < 2) {
      throw Exception('Not enough data to create trip');
    }

    final startPos = state.startPosition!;
    final endPos = state.currentPosition!;

    return {
      'startLatitude': startPos.latitude,
      'startLongitude': startPos.longitude,
      'endLatitude': endPos.latitude,
      'endLongitude': endPos.longitude,
      'startTime': state.startTime,
      'endTime': state.endTime ?? DateTime.now(),
      'distance': state.totalDistance,
      'duration': state.duration?.inSeconds ?? 0,
      'positions': state.positions.map((p) => {
        'latitude': p.latitude,
        'longitude': p.longitude,
        'timestamp': p.timestamp.millisecondsSinceEpoch,
      }).toList(),
    };
  }
}

/// GPS Tracking Provider
final gpsTrackingProvider = NotifierProvider<GPSTrackingNotifier, GPSTrackingState>(
  () => GPSTrackingNotifier(),
);
