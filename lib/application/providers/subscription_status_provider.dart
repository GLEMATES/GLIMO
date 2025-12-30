import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;

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
    if (Platform.isIOS) {
      return SubscriptionStatus(
        isActive: true,
        plan: 'iOS Unlimited',
        isTrial: false,
        hasUsedTrial: false,
      );
    }
    return SubscriptionStatus(isActive: false);
  }

  // Helper: Get current user ID
  String? _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  // Save subscription to Firestore (server-side storage)
  Future<void> _saveToFirestore() async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      if (kDebugMode) debugPrint('⚠️ [Subscription] Cannot save to Firestore: No user logged in');
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      final data = {
        'isActive': state.isActive,
        'plan': state.plan,
        'expiryDate': state.expiryDate?.millisecondsSinceEpoch,
        'startDate': state.purchaseDate?.millisecondsSinceEpoch,
        'isTrial': state.isTrial,
        'hasUsedTrial': state.hasUsedTrial,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'productId': state.productId,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('current')
          .set(data);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [Subscription] Error saving to Firestore: $e');
        debugPrint('   Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  // Load subscription from Firestore (server-side is source of truth)
  Future<void> loadSubscriptionStatus() async {
    if (Platform.isIOS) {
      state = SubscriptionStatus(
        isActive: true,
        plan: 'iOS Unlimited',
        isTrial: false,
        hasUsedTrial: false,
      );
      return;
    }

    final userId = _getCurrentUserId();
    if (userId == null) {
      await _loadFromSharedPreferences();
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('current')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        state = SubscriptionStatus(
          isActive: data['isActive'] ?? false,
          expiryDate: data['expiryDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['expiryDate'])
              : null,
          plan: data['plan'] ?? 'Free',
          isTrial: data['isTrial'] ?? false,
          hasUsedTrial: data['hasUsedTrial'] ?? false,
          productId: data['productId'],
          purchaseDate: data['startDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['startDate'])
              : null,
        );

        await _saveToSharedPreferences();
      } else {
        await _loadFromSharedPreferences();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading from Firestore: $e');
      await _loadFromSharedPreferences();
    }
  }

  // Load from SharedPreferences (local cache / offline mode)
  Future<void> _loadFromSharedPreferences() async {
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

  // Save to SharedPreferences (local cache)
  Future<void> _saveToSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('subscription_active', state.isActive);
    if (state.expiryDate != null) {
      await prefs.setInt('subscription_expiry', state.expiryDate!.millisecondsSinceEpoch);
    }
    await prefs.setString('subscription_plan', state.plan);
    await prefs.setBool('subscription_is_trial', state.isTrial);
    await prefs.setBool('subscription_has_used_trial', state.hasUsedTrial);
    if (state.productId != null) {
      await prefs.setString('subscription_product_id', state.productId!);
    }
    if (state.purchaseDate != null) {
      await prefs.setInt('subscription_purchase_date', state.purchaseDate!.millisecondsSinceEpoch);
    }
  }

  Future<void> activateTrial() async {
    final now = DateTime.now();
    final expiryDate = now.add(const Duration(days: 14));

    state = SubscriptionStatus(
      isActive: true,
      expiryDate: expiryDate,
      plan: 'Trial 14 Hari',
      isTrial: true,
      hasUsedTrial: true,
      purchaseDate: now,
    );

    // Save to both Firestore (server-side) and local cache
    await _saveToFirestore();
    await _saveToSharedPreferences();
  }

  Future<void> activateSubscription({
    required String plan,
    required int durationMonths,
    String? productId,
  }) async {
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: durationMonths * 30));

    state = SubscriptionStatus(
      isActive: true,
      expiryDate: expiryDate,
      plan: plan,
      isTrial: false,
      hasUsedTrial: state.hasUsedTrial,
      productId: productId,
      purchaseDate: now,
    );

    // Save to both Firestore (server-side) and local cache
    await _saveToFirestore();
    await _saveToSharedPreferences();
  }

  // Custom activate with specific expiry date (for manual recovery)
  Future<void> activateSubscriptionUntil({
    required String plan,
    required DateTime expiryDate,
    String? productId,
  }) async {
    final now = DateTime.now();

    state = SubscriptionStatus(
      isActive: true,
      expiryDate: expiryDate,
      plan: plan,
      isTrial: false,
      hasUsedTrial: state.hasUsedTrial,
      productId: productId,
      purchaseDate: now,
    );

    // Save to both Firestore (server-side) and local cache
    await _saveToFirestore();
    await _saveToSharedPreferences();
  }

  Future<void> cancelTrial() async {
    state = SubscriptionStatus(
      isActive: false,
      expiryDate: null,
      plan: 'Free',
      isTrial: false,
      hasUsedTrial: true,
    );

    // Save to both Firestore (server-side) and local cache
    await _saveToFirestore();
    await _saveToSharedPreferences();
  }

  Future<void> cancelSubscription() async {
    state = SubscriptionStatus(
      isActive: false,
      expiryDate: null,
      plan: 'Free',
      isTrial: false,
      hasUsedTrial: state.hasUsedTrial,
    );

    // Save to both Firestore (server-side) and local cache
    await _saveToFirestore();
    await _saveToSharedPreferences();
  }

  // Check and handle expiry (call this on app launch)
  Future<void> checkAndHandleExpiry() async {
    if (state.isActive && state.expiryDate != null) {
      if (DateTime.now().isAfter(state.expiryDate!)) {
        await cancelSubscription();
        if (kDebugMode) debugPrint('⚠️ Subscription expired, downgraded to Free tier');
      }
    }
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