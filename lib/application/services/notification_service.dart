import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/service_rules_dss.dart';
import '../utils/navigation_helper.dart';
import '../../domain/models/notification_model.dart';
import '../../infrastructure/repositories/notification_repository.dart';

/// Notification Service for GLIMO
///
/// Handles:
/// - Service maintenance notifications (Servis category)
/// - General notifications like trip completion (Umum category)
/// - iOS and Android platform-specific configuration
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final NotificationRepository _repository = NotificationRepository();

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request iOS permissions explicitly
    await _requestIOSPermissions();

    // Create notification channels for Android
    await _createNotificationChannels();

    _initialized = true;
  }

  /// Request iOS notification permissions
  Future<void> _requestIOSPermissions() async {
    final bool? granted = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    if (granted == true) {
      debugPrint('✅ iOS notification permissions granted');
    } else {
      debugPrint('❌ iOS notification permissions denied');
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    // Channel for Service notifications (high importance)
    const AndroidNotificationChannel serviceChannel =
        AndroidNotificationChannel(
      'service_notifications', // id
      'Notifikasi Servis', // title
      description: 'Pengingat servis motor berkala',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    // Channel for General notifications (default importance)
    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
      'general_notifications', // id
      'Notifikasi Umum', // title
      description: 'Notifikasi informasi umum seperti penyelesaian perjalanan',
      importance: Importance.defaultImportance,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(serviceChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }

  /// Handle notification tap (from lock screen or notification center)
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    // Use a delayed callback to ensure app is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        // Navigate based on payload using NavigationHelper
        switch (payload) {
          case 'monitoring':
            // Navigate to Monitoring screen (service notifications)
            debugPrint('➡️ Navigating to Monitoring screen');
            NavigationHelper.navigateToMonitoring();
            break;
          case 'riwayat':
            // Navigate to Riwayat screen (trip notifications)
            debugPrint('➡️ Navigating to Riwayat screen');
            NavigationHelper.navigateToRiwayat();
            break;
          default:
            debugPrint('⚠️ Unknown payload: $payload');
        }
      } catch (e) {
        debugPrint('❌ Error navigating from notification: $e');
      }
    });
  }

  /// Show service maintenance notification
  Future<void> showServiceNotification({
    required int id,
    required String componentName,
    required ServiceUrgencyInfo urgencyInfo,
  }) async {
    debugPrint('🔔 [NOTIF] ========================================');
    debugPrint('🔔 [NOTIF] showServiceNotification() called');
    debugPrint('🔔 [NOTIF] Component: $componentName');
    debugPrint('🔔 [NOTIF] Urgency: ${urgencyInfo.urgency.name} ${urgencyInfo.emoji}');
    debugPrint('🔔 [NOTIF] Message: ${urgencyInfo.message}');

    if (!_initialized) {
      debugPrint('⚠️ [NOTIF] Not initialized, initializing now...');
      await initialize();
    }

    // Check if service notifications are enabled
    final prefs = await SharedPreferences.getInstance();
    final serviceNotifEnabled =
        prefs.getBool('service_notifications_enabled') ?? true;
    debugPrint('🔔 [NOTIF] Service notifications enabled: $serviceNotifEnabled');

    if (!serviceNotifEnabled) {
      debugPrint('❌ [NOTIF] Service notifications DISABLED - ABORTING');
      debugPrint('🔔 [NOTIF] ========================================');
      return;
    }

    // Get title and body
    final title =
        ServiceRulesDSS.getNotificationTitle(urgencyInfo.urgency, componentName);
    final body = ServiceRulesDSS.getNotificationBody(urgencyInfo);

    debugPrint('🔔 [NOTIF] Title: $title');
    debugPrint('🔔 [NOTIF] Body: $body');
    debugPrint('🔔 [NOTIF] Notification ID: $id');

    // Platform-specific details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'service_notifications',
      'Notifikasi Servis',
      channelDescription: 'Pengingat servis motor berkala',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Pengingat Servis',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    debugPrint('🔔 [NOTIF] Calling _notifications.show()...');
    try {
      await _notifications.show(
        id,
        title,
        body,
        platformDetails,
        payload: 'monitoring',
      );
      debugPrint('✅ [NOTIF] Notification SHOWN successfully!');
    } catch (e) {
      debugPrint('❌ [NOTIF] Error showing notification: $e');
      rethrow;
    }

    // Save to repository for NotificationScreen
    final notification = NotificationModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_service_$componentName',
      category: 'service',
      title: title,
      description: body,
      timestamp: DateTime.now(),
      isRead: false,
      payload: 'monitoring',
    );

    debugPrint('🔔 [NOTIF] Saving to repository...');
    try {
      await _repository.addNotification(notification);
      debugPrint('✅ [NOTIF] Notification saved to storage: $componentName');
    } catch (e) {
      debugPrint('❌ [NOTIF] Error saving to repository: $e');
    }

    debugPrint('🎉 [NOTIF] Service notification COMPLETE!');
    debugPrint('🔔 [NOTIF] ========================================');
  }

  /// Show trip completion notification
  Future<void> showTripCompletionNotification({
    required String motorName,
    required double distance,
    required String duration,
    bool isAutoMode = false,
  }) async {
    if (!_initialized) await initialize();

    // Check if general notifications are enabled
    final prefs = await SharedPreferences.getInstance();
    final generalNotifEnabled =
        prefs.getBool('general_notifications_enabled') ?? true;
    if (!generalNotifEnabled) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'general_notifications',
      'Notifikasi Umum',
      channelDescription: 'Notifikasi informasi umum',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ticker: 'Trip Selesai',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = isAutoMode ? 'Tracking Otomatis Selesai' : 'Perjalanan Selesai';
    final body = isAutoMode
        ? 'Tracking selesai otomatis\n$motorName - ${distance.toStringAsFixed(2)} km, $duration'
        : '$motorName - ${distance.toStringAsFixed(2)} km, $duration';

    debugPrint('🔔 [TRIP NOTIF] Showing ${isAutoMode ? "AUTO" : "MANUAL"} trip completion notification');
    debugPrint('   Title: $title');
    debugPrint('   Body: $body');

    await _notifications.show(
      999, // Fixed ID for trip completion
      title,
      body,
      platformDetails,
      payload: 'riwayat',
    );

    // Save to repository for NotificationScreen
    final notification = NotificationModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_trip',
      category: 'general',
      title: title,
      description: body,
      timestamp: DateTime.now(),
      isRead: false,
      payload: 'riwayat',
    );

    await _repository.addNotification(notification);
    debugPrint('💾 Saved trip notification to storage');
  }

  /// Check if should send notification for this component
  /// Returns TRUE if no unread notification exists for this component
  Future<bool> shouldSendServiceNotification(String componentName) async {
    debugPrint('🔍 [NOTIF] Checking if should send notification for: $componentName');

    // Get all service notifications for this component
    final allNotifications = await _repository.getAllNotifications();
    final serviceNotifications = allNotifications
        .where((n) => n.category == 'service' && n.title.contains(componentName))
        .toList();

    debugPrint('📋 [NOTIF] Found ${serviceNotifications.length} existing notifications for $componentName');

    // Check if there's any unread notification
    final hasUnreadNotification = serviceNotifications.any((n) => !n.isRead);

    if (hasUnreadNotification) {
      debugPrint('⏭️ [NOTIF] Unread notification exists for $componentName - SKIP sending');
      return false;
    } else {
      debugPrint('✅ [NOTIF] No unread notification for $componentName - OK to send');
      return true;
    }
  }

  /// Check if daily service check was already done today
  Future<bool> shouldPerformDailyCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckDate = prefs.getString('last_daily_check_date');
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD

    if (lastCheckDate != today) {
      await prefs.setString('last_daily_check_date', today);
      return true;
    }

    return false;
  }

  /// Clear daily check throttle (for testing/debugging)
  Future<void> clearDailyCheckThrottle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_daily_check_date');
    debugPrint('🧹 Cleared daily check throttle');
  }

  Future<void> showTestNotification() async {
    if (!_initialized) {
      debugPrint('⚠️ NotificationService not initialized, initializing now...');
      await initialize();
    }

    debugPrint('🧪 Sending test notification...');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'service_notifications',
      'Notifikasi Servis',
      channelDescription: 'Test notification',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '🧪 Test Notification GLIMO',
        'Jika kamu lihat ini, notifikasi berhasil! ${DateTime.now().toString().substring(11, 19)}',
        platformDetails,
      );
      debugPrint('✅ Test notification sent successfully!');
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
