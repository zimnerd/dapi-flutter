import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dating_app/services/notifications_service.dart';
import 'package:dating_app/utils/logger.dart';
import 'providers.dart' show apiClientProvider;

final _logger = Logger('NotificationsProvider');

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsService(apiClient);
});

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<Notification>>((ref) {
  final service = ref.watch(notificationsServiceProvider);
  return NotificationsNotifier(service);
});

class NotificationsNotifier extends StateNotifier<List<Notification>> {
  final NotificationsService _service;

  NotificationsNotifier(this._service) : super([]) {
    loadNotifications();
  }

  Future<void> loadNotifications({
    bool unreadOnly = false,
    int skip = 0,
    int take = 20,
  }) async {
    try {
      _logger.debug(
          'Loading notifications: unreadOnly=$unreadOnly, skip=$skip, take=$take');
      final notifications = await _service.getNotifications(
        unreadOnly: unreadOnly,
        skip: skip,
        take: take,
      );
      state = notifications;
      _logger.info('Successfully loaded ${notifications.length} notifications');
    } catch (e) {
      _logger.error('Failed to load notifications: $e');
      // Keep the current state and don't update it on error
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      _logger.debug('Marking notification as read: $notificationId');
      await _service.markAsRead(notificationId);
      state = state.map((notification) {
        if (notification.id == notificationId) {
          return Notification(
            id: notification.id,
            userId: notification.userId,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            isRead: true,
            data: notification.data,
            createdAt: notification.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return notification;
      }).toList();
      _logger.info('Successfully marked notification as read: $notificationId');
    } catch (e) {
      _logger.error('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      _logger.debug('Marking all notifications as read');
      await _service.markAllAsRead();
      state = state
          .map((notification) => Notification(
                id: notification.id,
                userId: notification.userId,
                type: notification.type,
                title: notification.title,
                message: notification.message,
                isRead: true,
                data: notification.data,
                createdAt: notification.createdAt,
                updatedAt: DateTime.now(),
              ))
          .toList();
      _logger.info('Successfully marked all notifications as read');
    } catch (e) {
      _logger.error('Failed to mark all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      _logger.debug('Deleting notification: $notificationId');
      await _service.deleteNotification(notificationId);
      state = state
          .where((notification) => notification.id != notificationId)
          .toList();
      _logger.info('Successfully deleted notification: $notificationId');
    } catch (e) {
      _logger.error('Failed to delete notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      _logger.debug('Clearing all notifications');
      await _service.clearAllNotifications();
      state = [];
      _logger.info('Successfully cleared all notifications');
    } catch (e) {
      _logger.error('Failed to clear notifications: $e');
    }
  }
}
