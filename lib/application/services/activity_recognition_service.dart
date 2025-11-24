import 'package:flutter/foundation.dart';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

enum UserActivityType {
  inVehicle,
  onBicycle,
  onFoot,
  running,
  still,
  walking,
  unknown,
}

class ActivityRecognitionService {
  static final ActivityRecognitionService _instance = ActivityRecognitionService._internal();
  factory ActivityRecognitionService() => _instance;
  ActivityRecognitionService._internal();

  final ActivityRecognition _activityRecognition = ActivityRecognition();

  UserActivityType _currentActivity = UserActivityType.unknown;
  int _activityConfidence = 0;

  Function(UserActivityType, int)? onActivityChanged;

  UserActivityType get currentActivity => _currentActivity;
  int get activityConfidence => _activityConfidence;

  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.activityRecognition.request();

      debugPrint('🎯 [ACTIVITY] Permission status: $status');

      return status.isGranted;
    }

    return true;
  }

  Future<bool> hasPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await Permission.activityRecognition.isGranted;
    }
    return true;
  }

  Future<void> startListening() async {
    try {
      final hasPermission = await this.hasPermission();

      if (!hasPermission) {
        debugPrint('⚠️ [ACTIVITY] No permission, requesting...');
        final granted = await requestPermission();
        if (!granted) {
          debugPrint('❌ [ACTIVITY] Permission denied');
          return;
        }
      }

      debugPrint('🎯 [ACTIVITY] Starting activity recognition...');

      _activityRecognition.activityStream().listen(
        (ActivityEvent activity) {
          final type = _mapActivityType(activity.type);
          final confidence = activity.confidence;

          if (confidence < 50) {
            debugPrint('⚠️ [ACTIVITY] Low confidence: ${activity.type} ($confidence%)');
            return;
          }

          if (type != _currentActivity) {
            debugPrint('🎯 [ACTIVITY] Activity changed: ${activity.type} ($confidence%)');
            debugPrint('   Previous: $_currentActivity → New: $type');

            _currentActivity = type;
            _activityConfidence = confidence;

            onActivityChanged?.call(type, confidence);
          }
        },
        onError: (error) {
          debugPrint('❌ [ACTIVITY] Error: $error');
        },
      );

      debugPrint('✅ [ACTIVITY] Activity recognition started');
    } catch (e) {
      debugPrint('❌ [ACTIVITY] Failed to start: $e');
    }
  }

  void stopListening() {
    debugPrint('🛑 [ACTIVITY] Stopping activity recognition');
  }

  UserActivityType _mapActivityType(ActivityType type) {
    switch (type) {
      case ActivityType.IN_VEHICLE:
        return UserActivityType.inVehicle;
      case ActivityType.ON_BICYCLE:
        return UserActivityType.onBicycle;
      case ActivityType.ON_FOOT:
        return UserActivityType.onFoot;
      case ActivityType.RUNNING:
        return UserActivityType.running;
      case ActivityType.STILL:
        return UserActivityType.still;
      case ActivityType.WALKING:
        return UserActivityType.walking;
      default:
        return UserActivityType.unknown;
    }
  }

  String getActivityName(UserActivityType type) {
    switch (type) {
      case UserActivityType.inVehicle:
        return 'Berkendara';
      case UserActivityType.onBicycle:
        return 'Bersepeda';
      case UserActivityType.onFoot:
        return 'Berjalan Kaki';
      case UserActivityType.running:
        return 'Berlari';
      case UserActivityType.still:
        return 'Diam';
      case UserActivityType.walking:
        return 'Berjalan';
      case UserActivityType.unknown:
        return 'Tidak Diketahui';
    }
  }

  String getActivityEmoji(UserActivityType type) {
    switch (type) {
      case UserActivityType.inVehicle:
        return '🚗';
      case UserActivityType.onBicycle:
        return '🚴';
      case UserActivityType.onFoot:
        return '🚶';
      case UserActivityType.running:
        return '🏃';
      case UserActivityType.still:
        return '🧍';
      case UserActivityType.walking:
        return '🚶';
      case UserActivityType.unknown:
        return '❓';
    }
  }
}
