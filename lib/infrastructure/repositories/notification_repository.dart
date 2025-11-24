import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/notification_model.dart';

/// Repository for managing notification persistence
///
/// Stores notifications in SharedPreferences as JSON
/// Max 100 notifications kept (auto-delete oldest when exceeded)
class NotificationRepository {
  static const String _key = 'glimo_notifications';
  static const int _maxNotifications = 100;

  /// Get all notifications (sorted by timestamp, newest first)
  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_key);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      final notifications = jsonList
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by timestamp (newest first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return notifications;
    } catch (e) {
      debugPrint('❌ Error loading notifications: $e');
      return [];
    }
  }

  /// Get notifications by category ("service" or "general")
  Future<List<NotificationModel>> getNotificationsByCategory(String category) async {
    final allNotifications = await getAllNotifications();
    return allNotifications.where((n) => n.category == category).toList();
  }

  /// Add a new notification
  Future<void> addNotification(NotificationModel notification) async {
    try {
      final notifications = await getAllNotifications();

      // Add new notification at the beginning
      notifications.insert(0, notification);

      // Keep only max notifications (delete oldest)
      if (notifications.length > _maxNotifications) {
        notifications.removeRange(_maxNotifications, notifications.length);
      }

      await _saveNotifications(notifications);
      debugPrint('✅ Notification saved: ${notification.title}');
    } catch (e) {
      debugPrint('❌ Error saving notification: $e');
    }
  }

  /// Mark notification as read by ID
  Future<void> markAsRead(String id) async {
    try {
      final notifications = await getAllNotifications();
      final index = notifications.indexWhere((n) => n.id == id);

      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        await _saveNotifications(notifications);
        debugPrint('✅ Marked notification as read: $id');
      }
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications in category as read
  Future<void> markAllAsRead(String category) async {
    try {
      final notifications = await getAllNotifications();
      final updatedNotifications = notifications.map((n) {
        if (n.category == category && !n.isRead) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      await _saveNotifications(updatedNotifications);
      debugPrint('✅ Marked all $category notifications as read');
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
    }
  }

  /// Get unread count for a category
  Future<int> getUnreadCount(String category) async {
    final notifications = await getNotificationsByCategory(category);
    return notifications.where((n) => !n.isRead).length;
  }

  /// Get total unread count (all categories)
  Future<int> getTotalUnreadCount() async {
    final notifications = await getAllNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  /// Delete notification by ID
  Future<void> deleteNotification(String id) async {
    try {
      final notifications = await getAllNotifications();
      notifications.removeWhere((n) => n.id == id);
      await _saveNotifications(notifications);
      debugPrint('✅ Deleted notification: $id');
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      debugPrint('✅ Cleared all notifications');
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
    }
  }

  /// Save notifications to SharedPreferences
  Future<void> _saveNotifications(List<NotificationModel> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = notifications.map((n) => n.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await prefs.setString(_key, jsonString);
  }
}
