import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionStatus {
  final bool isActive;
  final DateTime? expiryDate;
  final String plan;
  final bool isTrial;
  final bool hasUsedTrial;
  final String? productId;
  final DateTime? purchaseDate;

  SubscriptionStatus({
    required this.isActive,
    this.expiryDate,
    this.plan = 'Free',
    this.isTrial = false,
    this.hasUsedTrial = false,
    this.productId,
    this.purchaseDate,
  });

  bool get isPremium => isActive && !isTrial;
  bool get isFree => !isActive;
  bool get isMonthly => plan == 'Monthly Premium';
  bool get isYearly => plan == 'Yearly Premium';

  SubscriptionStatus copyWith({
    bool? isActive,
    DateTime? expiryDate,
    String? plan,
    bool? isTrial,
    bool? hasUsedTrial,
    String? productId,
    DateTime? purchaseDate,
  }) {
    return SubscriptionStatus(
      isActive: isActive ?? this.isActive,
      expiryDate: expiryDate ?? this.expiryDate,
      plan: plan ?? this.plan,
      isTrial: isTrial ?? this.isTrial,
      hasUsedTrial: hasUsedTrial ?? this.hasUsedTrial,
      productId: productId ?? this.productId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
    );
  }
}

class SubscriptionStatusNotifier extends Notifier<SubscriptionStatus> {
  @override
  SubscriptionStatus build() {
    return SubscriptionStatus(isActive: false);
  }

  Future<void> loadSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool('subscription_active') ?? false;
    final expiryTimestamp = prefs.getInt('subscription_expiry');
    final plan = prefs.getString('subscription_plan') ?? 'Free';
    final isTrial = prefs.getBool('subscription_is_trial') ?? false;
    final hasUsedTrial = prefs.getBool('subscription_has_used_trial') ?? false;
    final productId = prefs.getString('subscription_product_id');
    final purchaseTimestamp = prefs.getInt('subscription_purchase_date');

    state = SubscriptionStatus(
      isActive: isActive,
      expiryDate: expiryTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(expiryTimestamp)
          : null,
      plan: plan,
      isTrial: isTrial,
      hasUsedTrial: hasUsedTrial,
      productId: productId,
      purchaseDate: purchaseTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(purchaseTimestamp)
          : null,
    );
  }

  Future<void> activateTrial() async {
    final now = DateTime.now();
    final expiryDate = now.add(const Duration(days: 14));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('subscription_active', true);
    await prefs.setInt('subscription_expiry', expiryDate.millisecondsSinceEpoch);
    await prefs.setString('subscription_plan', 'Trial 14 Hari');
    await prefs.setBool('subscription_is_trial', true);
    await prefs.setBool('subscription_has_used_trial', true);
    await prefs.setInt('subscription_purchase_date', now.millisecondsSinceEpoch);

    state = SubscriptionStatus(
      isActive: true,
      expiryDate: expiryDate,
      plan: 'Trial 14 Hari',
      isTrial: true,
      hasUsedTrial: true,
      purchaseDate: now,
    );
  }

  Future<void> activateSubscription({
    required String plan,
    required int durationMonths,
    String? productId,
  }) async {
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: durationMonths * 30));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('subscription_active', true);
    await prefs.setInt('subscription_expiry', expiryDate.millisecondsSinceEpoch);
    await prefs.setString('subscription_plan', plan);
    await prefs.setBool('subscription_is_trial', false);
    await prefs.setInt('subscription_purchase_date', now.millisecondsSinceEpoch);
    if (productId != null) {
      await prefs.setString('subscription_product_id', productId);
    }

    state = SubscriptionStatus(
      isActive: true,
      expiryDate: expiryDate,
      plan: plan,
      isTrial: false,
      hasUsedTrial: state.hasUsedTrial,
      productId: productId,
      purchaseDate: now,
    );
  }

  Future<void> cancelTrial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('subscription_active', false);
    await prefs.remove('subscription_expiry');
    await prefs.setString('subscription_plan', 'Free');
    await prefs.setBool('subscription_is_trial', false);

    state = SubscriptionStatus(
      isActive: false,
      expiryDate: null,
      plan: 'Free',
      isTrial: false,
      hasUsedTrial: true,
    );
  }

  Future<void> cancelSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('subscription_active', false);
    await prefs.remove('subscription_expiry');
    await prefs.setString('subscription_plan', 'Free');
    await prefs.setBool('subscription_is_trial', false);

    state = SubscriptionStatus(
      isActive: false,
      expiryDate: null,
      plan: 'Free',
      isTrial: false,
      hasUsedTrial: state.hasUsedTrial,
    );
  }

  bool isSubscriptionExpired() {
    if (!state.isActive || state.expiryDate == null) return true;
    return DateTime.now().isAfter(state.expiryDate!);
  }

  String getRemainingDays() {
    if (!state.isActive || state.expiryDate == null) return '0';
    final remaining = state.expiryDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining.toString() : '0';
  }

  bool canActivateTrial() {
    return !state.hasUsedTrial && !state.isActive;
  }

  String getSubscriptionType() {
    if (!state.isActive) return 'Free';
    if (state.isTrial) return 'Trial';
    return 'Premium';
  }
}

final subscriptionStatusProvider = NotifierProvider<SubscriptionStatusNotifier, SubscriptionStatus>(
  () => SubscriptionStatusNotifier(),
);