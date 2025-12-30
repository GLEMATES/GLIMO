import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/notification_model.dart';
import '../../infrastructure/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final allNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotificationsStream();
});

final serviceNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final allNotifications = ref.watch(allNotificationsProvider);
  return allNotifications.when(
    data: (notifications) => notifications.where((n) => n.category == 'service').toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final generalNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final allNotifications = ref.watch(allNotificationsProvider);
  return allNotifications.when(
    data: (notifications) => notifications.where((n) => n.category == 'general').toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final totalUnreadCountProvider = Provider<int>((ref) {
  final allNotifications = ref.watch(allNotificationsProvider);
  return allNotifications.when(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final serviceUnreadCountProvider = Provider<int>((ref) {
  final allNotifications = ref.watch(allNotificationsProvider);
  return allNotifications.when(
    data: (notifications) =>
        notifications.where((n) => n.category == 'service' && !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final generalUnreadCountProvider = Provider<int>((ref) {
  final allNotifications = ref.watch(allNotificationsProvider);
  return allNotifications.when(
    data: (notifications) =>
        notifications.where((n) => n.category == 'general' && !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

class NotificationNotifier {
  NotificationNotifier(this.repository);

  final NotificationRepository repository;

  Future<void> addNotification(NotificationModel notification) async {
    await repository.addNotification(notification);
  }

  Future<void> markAsRead(String id) async {
    await repository.markAsRead(id);
  }

  Future<void> markAllAsRead(String category) async {
    await repository.markAllAsRead(category);
  }

  Future<void> deleteNotification(String id) async {
    await repository.deleteNotification(id);
  }

  Future<void> clearAll() async {
    await repository.clearAllNotifications();
  }
}

final notificationNotifierProvider = Provider<NotificationNotifier>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository);
});
