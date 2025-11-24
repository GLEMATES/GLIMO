import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification Settings Model
class NotificationSettings {
  final bool serviceNotificationsEnabled;
  final bool generalNotificationsEnabled;

  NotificationSettings({
    this.serviceNotificationsEnabled = true,
    this.generalNotificationsEnabled = true,
  });

  NotificationSettings copyWith({
    bool? serviceNotificationsEnabled,
    bool? generalNotificationsEnabled,
  }) {
    return NotificationSettings(
      serviceNotificationsEnabled:
          serviceNotificationsEnabled ?? this.serviceNotificationsEnabled,
      generalNotificationsEnabled:
          generalNotificationsEnabled ?? this.generalNotificationsEnabled,
    );
  }
}

/// Notification Settings Notifier (Riverpod 3.x)
class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    _loadSettings();
    return NotificationSettings();
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final serviceEnabled =
        prefs.getBool('service_notifications_enabled') ?? true;
    final generalEnabled =
        prefs.getBool('general_notifications_enabled') ?? true;

    state = NotificationSettings(
      serviceNotificationsEnabled: serviceEnabled,
      generalNotificationsEnabled: generalEnabled,
    );
  }

  /// Toggle service notifications
  Future<void> toggleServiceNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('service_notifications_enabled', enabled);
    state = state.copyWith(serviceNotificationsEnabled: enabled);
  }

  /// Toggle general notifications
  Future<void> toggleGeneralNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('general_notifications_enabled', enabled);
    state = state.copyWith(generalNotificationsEnabled: enabled);
  }
}

/// Provider for notification settings
final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);
