import 'package:dating_app/services/api_client.dart';

enum NotificationType {
  MATCH,
  MESSAGE,
  LIKE,
  SYSTEM,
}

class Notification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime updatedAt;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      userId: json['userId'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      title: json['title'],
      message: json['message'],
      isRead: json['isRead'],
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class NotificationsService {
  final ApiClient _apiClient;

  NotificationsService(this._apiClient);

  Future<List<Notification>> getNotifications({
    bool unreadOnly = false,
    int skip = 0,
    int take = 20,
  }) async {
    final response = await _apiClient.get(
      '/notifications',
      queryParameters: {
        'unreadOnly': unreadOnly,
        'skip': skip,
        'take': take,
      },
    );

    return (response.data as List)
        .map((json) => Notification.fromJson(json))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _apiClient.put('/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _apiClient.put('/notifications/read-all');
  }

  Future<void> deleteNotification(String notificationId) async {
    await _apiClient.delete('/notifications/$notificationId');
  }

  Future<void> clearAllNotifications() async {
    await _apiClient.delete('/notifications');
  }
}
