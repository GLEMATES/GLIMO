import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/notification_model.dart';
import '../../infrastructure/repositories/notification_repository.dart';

/// Repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Provider for all notifications (sorted by timestamp, newest first)
final allNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) async* {
  final repository = ref.watch(notificationRepositoryProvider);

  // Initial load
  yield await repository.getAllNotifications();

  // Poll for updates every 5 seconds
  // (In production, consider using a better reactive solution)
  await Future.delayed(const Duration(seconds: 5));

  while (true) {
    yield await repository.getAllNotifications();
    await Future.delayed(const Duration(seconds: 5));
  }
});

/// Provider for service notifications only
final serviceNotificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotificationsByCategory('service');
});

/// Provider for general notifications only
final generalNotificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotificationsByCategory('general');
});

/// Provider for total unread count (for badge on notification icon)
final totalUnreadCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getTotalUnreadCount();
});

/// Provider for service category unread count
final serviceUnreadCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadCount('service');
});

/// Provider for general category unread count
final generalUnreadCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadCount('general');
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
