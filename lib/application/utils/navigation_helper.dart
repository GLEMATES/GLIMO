import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Global navigation helper for accessing navigation context
/// from anywhere in the app (e.g., from notification callbacks)
class NavigationHelper {
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize with navigator key from main.dart
  static void initialize(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Get current navigation context
  /// Returns null if context is not available
  static BuildContext? get context {
    return _navigatorKey?.currentContext;
  }

  /// Navigate to a route
  static void navigateTo(String route) {
    final ctx = context;
    if (ctx != null) {
      ctx.go(route);
    } else {
      debugPrint('❌ Navigation context not available');
    }
  }

  /// Navigate to monitoring screen
  static void navigateToMonitoring() {
    navigateTo('/monitoring');
  }

  /// Navigate to riwayat screen
  static void navigateToRiwayat() {
    navigateTo('/riwayat');
  }

  /// Navigate to notification screen
  static void navigateToNotifications() {
    navigateTo('/notifikasi');
  }
}
