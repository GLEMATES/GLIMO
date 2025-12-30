import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'subscription_status_provider.dart';
import 'motor_list_provider.dart';
import 'trip_history_provider.dart';

class PremiumLimitException implements Exception {
  final String message;
  final String featureName;

  PremiumLimitException(this.message, this.featureName);

  @override
  String toString() => message;
}

class PremiumLimitsNotifier {
  static const int freeMotorLimit = 1;
  static const int freeHistoryDaysLimit = 7;

  final SubscriptionStatus subscriptionStatus;
  final List<Motor> motors;

  PremiumLimitsNotifier({
    required this.subscriptionStatus,
    required this.motors,
  });

  bool get isPremium => Platform.isIOS || subscriptionStatus.isPremium;
  bool get canAddMotor => isPremium || motors.length < freeMotorLimit;
  int get motorLimit => isPremium ? -1 : freeMotorLimit;
  int get historyDaysLimit => isPremium ? -1 : freeHistoryDaysLimit;

  String getMotorLimitText() {
    if (isPremium) return 'Unlimited';
    return '${motors.length}/$freeMotorLimit Motor';
  }

  void checkCanAddMotor() {
    if (!canAddMotor) {
      throw PremiumLimitException(
        'Upgrade ke Premium untuk menambah lebih dari $freeMotorLimit motor',
        'multiple_motors',
      );
    }
  }

  DateTime getHistoryStartDate() {
    if (isPremium) {
      return DateTime(2000);
    }
    return DateTime.now().subtract(Duration(days: freeHistoryDaysLimit));
  }

  bool isHistoryWithinLimit(DateTime date) {
    if (isPremium) return true;
    final limitDate = getHistoryStartDate();
    return date.isAfter(limitDate) || date.isAtSameMomentAs(limitDate);
  }
}

final premiumLimitsProvider = Provider<PremiumLimitsNotifier>((ref) {
  final subscriptionStatus = ref.watch(subscriptionStatusProvider);
  final motors = ref.watch(motorListProvider);

  return PremiumLimitsNotifier(
    subscriptionStatus: subscriptionStatus,
    motors: motors,
  );
});

final filteredTripHistoryProvider = Provider<List<TripHistory>>((ref) {
  final allTrips = ref.watch(tripHistoryProvider);
  final limits = ref.watch(premiumLimitsProvider);
  final motors = ref.watch(motorListProvider);
  final activeMotor = motors.where((m) => m.isActive).firstOrNull;

  if (activeMotor == null) {
    return [];
  }

  final motorTrips = allTrips.where((trip) => trip.motorId == activeMotor.id).toList();

  if (limits.isPremium) {
    return motorTrips;
  }

  final limitDate = limits.getHistoryStartDate();
  return motorTrips.where((trip) {
    return trip.date.isAfter(limitDate) || trip.date.isAtSameMomentAs(limitDate);
  }).toList();
});
