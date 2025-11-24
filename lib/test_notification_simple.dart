import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/widgets/daily_service_checker.dart';
import 'application/services/notification_service.dart';

class SimpleNotificationTest extends ConsumerStatefulWidget {
  const SimpleNotificationTest({super.key});

  @override
  ConsumerState<SimpleNotificationTest> createState() => _SimpleNotificationTestState();
}

class _SimpleNotificationTestState extends ConsumerState<SimpleNotificationTest> {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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

    await _notifications.initialize(initSettings);

    final granted = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    debugPrint('Permission granted: $granted');
    setState(() {
      _initialized = true;
    });
  }

  Future<void> _sendSimpleNotification() async {
    if (!_initialized) {
      await _initNotifications();
    }

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timestamp = DateTime.now().toString().substring(11, 19);

    try {
      await _notifications.show(
        id,
        'Test Notif $id',
        'Waktu: $timestamp',
        platformDetails,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification sent with ID: $id')),
        );
      }

      debugPrint('✅ Sent notification ID: $id at $timestamp');
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _forceDailyServiceCheck() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔍 Running daily service check...')),
      );
    }

    debugPrint('🧪 [TEST] Force triggering daily service check...');

    try {
      // Clear throttle and force trigger DSS
      await NotificationService().clearDailyCheckThrottle();
      await DailyServiceChecker.forcePerformDailyCheck(ref, bypassThrottle: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Daily service check completed! Check logs and notifications.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error in force daily check: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Notification Test')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_initialized ? 'Initialized ✅' : 'Not initialized'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initNotifications,
                child: const Text('Init Notifications'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sendSimpleNotification,
                child: const Text('Send Test Notification'),
              ),
              const SizedBox(height: 20),
              const Divider(thickness: 2),
              const SizedBox(height: 20),
              const Text(
                'Daily Service Check Test',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _forceDailyServiceCheck,
                icon: const Icon(Icons.notifications_active),
                label: const Text('Force Daily Service Check'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Instructions:\n'
                '1. Tap "Init Notifications"\n'
                '2. Tap "Send Test Notification" (basic test)\n'
                '3. Tap "Force Daily Service Check" to test DSS\n'
                '4. MINIMIZE app immediately\n'
                '5. Check notification center for service alerts',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
