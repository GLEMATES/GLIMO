import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Background GPS Tracking Service
/// This service runs in the background even when app is closed
@pragma('vm:entry-point')
class BackgroundTrackingService {
  static const String _notificationChannelId = 'gps_tracking_channel';
  static const String _notificationChannelName = 'GPS Tracking';
  static const int _notificationId = 888;

  /// Initialize the background service
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: 'Channel untuk tracking GPS perjalanan',
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Configure the background service
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'GLIMO Tracking',
        initialNotificationContent: 'Sedang melacak perjalanan Anda...',
        foregroundServiceNotificationId: _notificationId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Start the background tracking service
  static Future<void> startTracking(String userId) async {
    final service = FlutterBackgroundService();

    // Save userId for background use
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tracking_user_id', userId);

    await service.startService();
  }

  /// Stop the background tracking service
  static Future<void> stopTracking() async {
    final service = FlutterBackgroundService();
    service.invoke('stop');
  }

  /// Check if service is running
  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return service.isRunning();
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// Main service handler
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stop').listen((event) {
      service.invoke('stopService');
      service.stopSelf();
    });

    // Start GPS tracking
    await _startGPSTracking(service);
  }

  /// GPS Tracking logic
  static Future<void> _startGPSTracking(ServiceInstance service) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('tracking_user_id');

    if (userId == null) {
      service.stopSelf();
      return;
    }

    // Load existing tracking data
    List<Position> positions = [];
    double totalDistance = 0.0;
    DateTime? startTime;

    final savedData = prefs.getString('active_tracking_$userId');
    if (savedData != null) {
      try {
        final data = jsonDecode(savedData);
        positions = (data['positions'] as List)
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
        totalDistance = data['totalDistance']?.toDouble() ?? 0.0;
        startTime = DateTime.parse(data['startTime']);
      } catch (e) {
        // Error loading, start fresh
      }
    }

    startTime ??= DateTime.now();

    // Flag to control notification updates
    bool isServiceRunning = true;

    // Listen for service stop
    service.on('stopService').listen((event) {
      isServiceRunning = false;
    });

    // Timer for updating notification
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!isServiceRunning) {
        timer.cancel();
        return;
      }

      final duration = DateTime.now().difference(startTime!);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);

      final durationStr =
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      // Update notification
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'GLIMO Tracking Aktif',
          content:
              '📍 ${totalDistance.toStringAsFixed(2)} km • ⏱️ $durationStr\nJumlah GPS points: ${positions.length}',
        );
      }
    });

    // Listen to position stream
    StreamSubscription<Position>? positionSubscription;

    try {
      positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(
        (Position position) async {
          // Add position
          if (positions.isNotEmpty) {
            final lastPosition = positions.last;
            double distance = Geolocator.distanceBetween(
              lastPosition.latitude,
              lastPosition.longitude,
              position.latitude,
              position.longitude,
            );
            totalDistance += distance / 1000; // Convert to km
          }

          positions.add(position);

          // Auto-save every 30 seconds (only save when needed)
          if (positions.length % 3 == 0) {
            final data = {
              'status': 'tracking',
              'positions': positions
                  .map((p) => {
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
                      })
                  .toList(),
              'startTime': startTime!.toIso8601String(),
              'totalDistance': totalDistance,
            };

            await prefs.setString('active_tracking_$userId', jsonEncode(data));
          }
        },
        onError: (error) {
          // Handle error
          positionSubscription?.cancel();
          isServiceRunning = false;
          service.stopSelf();
        },
      );

      // Wait until service is stopped
      while (isServiceRunning) {
        await Future.delayed(const Duration(seconds: 1));
      }

      positionSubscription.cancel();
    } catch (e) {
      positionSubscription?.cancel();
      isServiceRunning = false;
      service.stopSelf();
    }
  }
}
