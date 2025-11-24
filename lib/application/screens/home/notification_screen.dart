import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../providers/notification_provider.dart';
import '../../../domain/models/notification_model.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  int _selectedIndex = 0;

  Future<void> _markAllAsRead() async {
    final category = _selectedIndex == 0 ? 'service' : 'general';
    await ref.read(notificationNotifierProvider).markAllAsRead(category);

    // Refresh providers
    ref.invalidate(serviceNotificationsProvider);
    ref.invalidate(generalNotificationsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Semua notifikasi ditandai sudah dibaca.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral0,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.normalHover,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.m),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.m),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    final hasUnread = notifications.any((notif) => !notif.isRead);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terbaru',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              if (hasUnread)
                TextButton(
                  onPressed: _markAllAsRead,
                  child: Text(
                    'Tandai Semua Sudah Dibaca',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.normalHover),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: notifications.isEmpty
              ? Center(
                  child: Text(
                    'Tidak ada notifikasi.',
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.neutral500),
                  ),
                )
              : ListView.builder(
                  itemCount: notifications.length,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return NotificationItem(
                      notification: notification,
                      onTap: () async {
                        if (!mounted) return;

                        final navContext = context;
                        final payload = notification.payload;

                        await ref
                            .read(notificationNotifierProvider)
                            .markAsRead(notification.id);

                        ref.invalidate(serviceNotificationsProvider);
                        ref.invalidate(generalNotificationsProvider);

                        if (!mounted || payload == null) return;

                        switch (payload) {
                          case 'monitoring':
                            // ignore: use_build_context_synchronously
                            navContext.go('/monitoring');
                            break;
                          case 'riwayat':
                            // ignore: use_build_context_synchronously
                            navContext.go('/riwayat');
                            break;
                          default:
                            debugPrint('Unknown payload: $payload');
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the appropriate provider based on selected tab
    final notificationsAsync = _selectedIndex == 0
        ? ref.watch(serviceNotificationsProvider)
        : ref.watch(generalNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.neutral0),
        ),
        backgroundColor: AppColors.normalHover,
        iconTheme: const IconThemeData(color: AppColors.neutral0),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.neutral0,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedIndex == 0 ? AppColors.normal : Colors.transparent,
                            width: 4,
                          ),
                          right: BorderSide(
                            color: AppColors.neutral300,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Text(
                        'Servis',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: _selectedIndex == 0 ? FontWeight.w600 : FontWeight.normal,
                          color: _selectedIndex == 0 ? AppColors.neutral900 : AppColors.neutral500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedIndex == 1 ? AppColors.normal : Colors.transparent,
                            width: 4,
                          ),
                          left: BorderSide(
                            color: AppColors.neutral300,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Text(
                        'Umum',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: _selectedIndex == 1 ? FontWeight.w600 : FontWeight.normal,
                          color: _selectedIndex == 1 ? AppColors.neutral900 : AppColors.neutral500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: notificationsAsync.when(
              data: (notifications) => _buildNotificationList(notifications),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error memuat notifikasi',
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.neutral500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  IconData _getIconForCategory() {
    if (notification.category == 'service') {
      return Icons.notifications_active;
    } else {
      // For trip completion, use motorcycle icon
      if (notification.title.contains('Perjalanan')) {
        return Icons.two_wheeler;
      }
      return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.neutral400,
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s),
              decoration: BoxDecoration(
                color: AppColors.normalHover,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForCategory(),
                color: AppColors.neutral0,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          margin: const EdgeInsets.only(left: AppSpacing.s),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification.description,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification.getTimeAgo(),
                    style: AppTypography.bodySmall.copyWith(color: AppColors.neutral400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}