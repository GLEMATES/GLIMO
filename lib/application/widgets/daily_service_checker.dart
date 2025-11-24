import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/motor_list_provider.dart';
import '../providers/servis_schedule_provider.dart';
import '../services/notification_service.dart';
import '../utils/service_rules_dss.dart';

/// Widget that checks service status daily and sends notifications
///
/// This widget should be placed in BerandaScreen to trigger
/// daily service notifications (max once per day)
class DailyServiceChecker extends ConsumerStatefulWidget {
  const DailyServiceChecker({super.key});

  @override
  ConsumerState<DailyServiceChecker> createState() => _DailyServiceCheckerState();

  /// Public static method to force daily check (for testing/debugging)
  /// Pass WidgetRef to access providers
  static Future<void> forcePerformDailyCheck(WidgetRef ref, {bool bypassThrottle = false}) async {
    return _DailyServiceCheckerState._performDailyCheckStatic(ref, bypassThrottle: bypassThrottle);
  }
}

class _DailyServiceCheckerState extends ConsumerState<DailyServiceChecker> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🟢 [DSC] DailyServiceChecker widget initialized');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🟢 [DSC] PostFrameCallback triggered, starting daily check...');
      _performDailyCheck();
    });
  }

  Future<void> _performDailyCheck() async {
    if (_hasChecked) {
      debugPrint('⚠️ [DSC] Daily check already performed in this widget instance');
      return;
    }
    _hasChecked = true;

    // Wait a bit for motorListProvider to finish loading
    debugPrint('⏳ [DSC] Waiting for motors to load...');
    await Future.delayed(const Duration(seconds: 1));

    debugPrint('🟢 [DSC] Calling _performDailyCheckStatic...');
    return _performDailyCheckStatic(ref, bypassThrottle: false);
  }

  static Future<void> _performDailyCheckStatic(WidgetRef ref, {required bool bypassThrottle}) async {
    try {
      // No more daily throttle - check every time app opens
      // Anti-spam is handled by "unread notification" check
      debugPrint('🔍 [DSC] Starting service check...');

      debugPrint('🔍 [DSC] ========================================');
      debugPrint('🔍 [DSC] PERFORMING DAILY SERVICE CHECK');
      debugPrint('🔍 [DSC] ========================================');

      // Get active motor (or first motor if no active motor)
      final motors = ref.read(motorListProvider);
      debugPrint('📋 [DSC] Total motors found: ${motors.length}');
      final Motor? activeMotor = motors.where((m) => m.isActive).firstOrNull ?? motors.firstOrNull;

      if (activeMotor == null) {
        debugPrint('❌ [DSC] No motor found in list - ABORTING');
        return;
      }

      debugPrint('🏍️ [DSC] Active motor: ${activeMotor.model}');
      debugPrint('🏍️ [DSC] Current odometer: ${activeMotor.odometer} km');

      // Get current odometer
      int currentOdometer = 0;
      try {
        currentOdometer = int.parse(activeMotor.odometer);
        debugPrint('✅ [DSC] Current odometer parsed: $currentOdometer km');
      } catch (e) {
        debugPrint('❌ [DSC] Invalid odometer value: ${activeMotor.odometer} - ABORTING');
        return;
      }

      int initialOdometer = 0;
      try {
        initialOdometer = int.parse(activeMotor.odometerAwal);
        debugPrint('✅ [DSC] Initial odometer parsed: $initialOdometer km');
      } catch (e) {
        initialOdometer = 0;
        debugPrint('⚠️ [DSC] Invalid initial odometer, using 0');
      }

      // Get service schedule and wait for it to load
      debugPrint('🔍 [DSC] Getting service schedule for: ${activeMotor.model}');

      try {
        // Get the async value
        final scheduleAsync = ref.read(servisScheduleProvider(activeMotor.model));

        // Check if already loaded
        final schedule = scheduleAsync.when(
          data: (data) => data,
          loading: () => null,
          error: (_, __) => null,
        );

        // If still loading, wait for it with timeout
        if (schedule == null) {
          debugPrint('⏳ [DSC] Schedule not loaded yet, waiting...');

          try {
            // Wait for future to complete with 15 second timeout
            final futureSchedule = await ref.read(servisScheduleProvider(activeMotor.model).future)
                .timeout(const Duration(seconds: 15));

            if (futureSchedule == null || futureSchedule.services.isEmpty) {
              debugPrint('❌ [DSC] No service schedule found for ${activeMotor.model}');
              return;
            }

            debugPrint('📋 [DSC] Service schedule loaded: ${futureSchedule.services.length} components');
            debugPrint('📋 [DSC] ========================================');

            await _processServiceSchedule(
              futureSchedule,
              currentOdometer,
              initialOdometer,
              activeMotor,
            );
          } catch (e) {
            debugPrint('⏱️ [DSC] Timeout or error loading schedule: $e');
            return;
          }
        } else {
          // Already loaded
          debugPrint('📋 [DSC] Service schedule loaded: ${schedule.services.length} components');
          debugPrint('📋 [DSC] ========================================');

          await _processServiceSchedule(
            schedule,
            currentOdometer,
            initialOdometer,
            activeMotor,
          );
        }
      } catch (e) {
        debugPrint('❌ [DSC] Exception in service schedule loading: $e');
      }
    } catch (e, stack) {
      debugPrint('❌ [DSC] Error in daily service check: $e');
      debugPrint('❌ [DSC] Stack trace: $stack');
    }
  }

  static Future<void> _processServiceSchedule(
    MotorServiceSchedule schedule,
    int currentOdometer,
    int initialOdometer,
    Motor activeMotor,
  ) async {
    try {
      // Check each service component
      int notificationsSent = 0;
      for (final service in schedule.services) {
        debugPrint('');
        debugPrint('🔧 [DSC] Checking component: ${service.component}');

        final nextServiceInfo = ServiceProgressCalculator.calculateNextService(
          serviceItem: service,
          currentOdometer: currentOdometer,
          initialOdometer: initialOdometer,
          motorPurchaseDate: activeMotor.tanggalBeli,
          lastServiceDate: activeMotor.tanggalServisTerakhir,
          lastServiceOdometer: activeMotor.odometerServisTerakhir,
        );

        if (nextServiceInfo == null) {
          debugPrint('⚠️ [DSC] ${service.component} - No next service info, skipping');
          continue;
        }

        // Calculate progress percentage
        final progress = nextServiceInfo.kmProgress * 100;
        final kmRemaining = nextServiceInfo.nextService.km -
            (currentOdometer - initialOdometer);

        debugPrint('📊 [DSC] ${service.component} - Progress: ${progress.toStringAsFixed(1)}%');
        debugPrint('📊 [DSC] ${service.component} - Remaining: $kmRemaining km');

        final urgencyInfo = ServiceRulesDSS.calculateUrgency(
          progressPercentage: progress,
          kmRemaining: kmRemaining,
          componentName: service.component,
          action: nextServiceInfo.nextService.action,
        );

        debugPrint('🎯 [DSC] ${service.component} - Urgency: ${urgencyInfo.urgency.name} ${urgencyInfo.emoji}');

        // Send notification if urgent/critical/warning AND no unread notification exists
        if (urgencyInfo.urgency == ServiceUrgency.critical ||
            urgencyInfo.urgency == ServiceUrgency.urgent ||
            urgencyInfo.urgency == ServiceUrgency.warning) {

          debugPrint('${urgencyInfo.emoji} [DSC] ${service.component} - ${urgencyInfo.urgency.name.toUpperCase()}!');
          debugPrint('🔍 [DSC] Checking if notification should be sent...');

          // Check if notification should be sent (no unread notification exists)
          final shouldSend = await NotificationService()
              .shouldSendServiceNotification(service.component);

          if (shouldSend) {
            debugPrint('✅ [DSC] ${service.component} - Sending ${urgencyInfo.urgency.name.toUpperCase()} notification...');
            await NotificationService().showServiceNotification(
              id: service.component.hashCode,
              componentName: service.component,
              urgencyInfo: urgencyInfo,
            );
            notificationsSent++;
            debugPrint('🎉 [DSC] ${service.component} - Notification SENT!');
          } else {
            debugPrint('⏭️ [DSC] ${service.component} - Skipped (unread notification exists)');
          }
        } else {
          debugPrint('🟢 [DSC] ${service.component} - SAFE, no notification needed');
        }
      }

      debugPrint('');
      debugPrint('========================================');
      if (notificationsSent > 0) {
        debugPrint('✅ [DSC] DAILY CHECK COMPLETE: $notificationsSent notifications SENT! 🎉');
      } else {
        debugPrint('✅ [DSC] DAILY CHECK COMPLETE: All components SAFE 🟢');
      }
      debugPrint('========================================');
    } catch (e) {
      debugPrint('❌ [DSC] Error processing service schedule: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // This widget doesn't render anything visible
    return const SizedBox.shrink();
  }
}
