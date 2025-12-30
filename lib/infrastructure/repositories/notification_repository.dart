import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/notification_model.dart';

class NotificationRepository {
  static const String _key = 'glimo_notifications';
  static const int _maxNotifications = 100;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      await _migrateFromLocalToFirestore();

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(_maxNotifications)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationModel(
          id: doc.id,
          category: data['category'] ?? '',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] ?? false,
          payload: data['payload'],
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error loading notifications: $e');
      return [];
    }
  }

  Stream<List<NotificationModel>> getNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(_maxNotifications)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationModel(
          id: doc.id,
          category: data['category'] ?? '',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] ?? false,
          payload: data['payload'],
        );
      }).toList();
    });
  }

  Future<List<NotificationModel>> getNotificationsByCategory(String category) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('category', isEqualTo: category)
          .orderBy('timestamp', descending: true)
          .limit(_maxNotifications)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationModel(
          id: doc.id,
          category: data['category'] ?? '',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] ?? false,
          payload: data['payload'],
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error loading notifications by category: $e');
      return [];
    }
  }

  Future<void> addNotification(NotificationModel notification) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notification.id)
          .set({
        'category': notification.category,
        'title': notification.title,
        'description': notification.description,
        'timestamp': Timestamp.fromDate(notification.timestamp),
        'isRead': notification.isRead,
        'payload': notification.payload,
      });

      await _cleanupOldNotifications();
      debugPrint('✅ Notification saved: ${notification.title}');
    } catch (e) {
      debugPrint('❌ Error saving notification: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(id)
          .update({'isRead': true});

      debugPrint('✅ Marked notification as read: $id');
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String category) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('category', isEqualTo: category)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      debugPrint('✅ Marked all $category notifications as read');
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
    }
  }

  Future<int> getUnreadCount(String category) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('category', isEqualTo: category)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      return 0;
    }
  }

  Future<int> getTotalUnreadCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Error getting total unread count: $e');
      return 0;
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(id)
          .delete();

      debugPrint('✅ Deleted notification: $id');
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('✅ Cleared all notifications');
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
    }
  }

  Future<void> _migrateFromLocalToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(jsonString);
        final localNotifications = jsonList
            .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
            .toList();

        if (localNotifications.isEmpty) {
          await prefs.remove(_key);
          return;
        }

        final batch = _firestore.batch();
        for (var notification in localNotifications) {
          final docRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .doc(notification.id);

          batch.set(docRef, {
            'category': notification.category,
            'title': notification.title,
            'description': notification.description,
            'timestamp': Timestamp.fromDate(notification.timestamp),
            'isRead': notification.isRead,
            'payload': notification.payload,
          });
        }

        await batch.commit();
        await prefs.remove(_key);
        debugPrint('✅ Migrated ${localNotifications.length} notifications to Firestore');
      }
    } catch (e) {
      debugPrint('❌ Error migrating notifications: $e');
    }
  }

  Future<void> _cleanupOldNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.length > _maxNotifications) {
        final batch = _firestore.batch();
        for (var i = _maxNotifications; i < snapshot.docs.length; i++) {
          batch.delete(snapshot.docs[i].reference);
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up notifications: $e');
    }
  }
}
