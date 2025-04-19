import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Web-specific notification service stub

/// Stub class for flutter_local_notifications to avoid web compilation issues
class FlutterLocalNotificationsPlugin {
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    SelectNotificationCallback? onSelectNotification,
  }) async {
    debugPrint('⟹ [Notification Web Stub] initialize called');
    return true;
  }

  Future<void> show(
    int id,
    String? title,
    String? body, {
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    debugPrint('⟹ [Notification Web Stub] show notification: $title - $body');
  }

  Future<void> cancelAll() async {
    debugPrint('⟹ [Notification Web Stub] cancelAll called');
  }

  dynamic resolvePlatformSpecificImplementation<T>() {
    // Return null to indicate not supported
    return null;
  }
}

/// Stub class for Android notification details
class AndroidNotificationDetails {
  final String channelId;
  final String channelName;
  final String channelDescription;
  final int importance;
  final int priority;
  final bool playSound;
  final bool enableVibration;
  final String icon;

  const AndroidNotificationDetails(
    this.channelId,
    this.channelName,
    this.channelDescription, {
    this.importance = 4,
    this.priority = 1,
    this.playSound = true,
    this.enableVibration = true,
    this.icon = '@mipmap/ic_launcher',
  });
}

/// Stub class for iOS notification details
class IOSNotificationDetails {
  final bool presentAlert;
  final bool presentBadge;
  final bool presentSound;

  const IOSNotificationDetails({
    this.presentAlert = true,
    this.presentBadge = true,
    this.presentSound = true,
  });
}

/// Stub class for notification details
class NotificationDetails {
  final AndroidNotificationDetails? android;
  final IOSNotificationDetails? iOS;

  const NotificationDetails({
    this.android,
    this.iOS,
  });
}

/// Stub class for notification settings
class InitializationSettings {
  final AndroidInitializationSettings? android;
  final IOSInitializationSettings? iOS;

  const InitializationSettings({
    this.android,
    this.iOS,
  });
}

/// Stub class for Android initialization settings
class AndroidInitializationSettings {
  final String defaultIcon;

  const AndroidInitializationSettings(this.defaultIcon);
}

/// Stub class for iOS initialization settings
class IOSInitializationSettings {
  final bool requestAlertPermission;
  final bool requestBadgePermission;
  final bool requestSoundPermission;

  const IOSInitializationSettings({
    this.requestAlertPermission = true,
    this.requestBadgePermission = true,
    this.requestSoundPermission = true,
  });
}

/// Stub class for iOS specific implementation
class IOSFlutterLocalNotificationsPlugin {
  Future<bool?> requestPermissions({
    bool? alert,
    bool? badge,
    bool? sound,
  }) async {
    // Return false to indicate not supported on web
    return false;
  }
}

/// Stub class for notification response
class NotificationResponse {
  final String? payload;
  
  const NotificationResponse({this.payload});
}

/// Stub class for color
class Color {
  final int value;
  
  const Color(this.value);
}

/// Stub values for priorities and importance
class Importance {
  static const dynamic high = 'high';
  static const dynamic max = 'max';
  static const dynamic low = 'low';
  static const dynamic defaultImportance = 'default';
}

class Priority {
  static const dynamic high = 'high';
  static const dynamic max = 'max';
  static const dynamic low = 'low';
  static const dynamic defaultPriority = 'default';
}

// Stub implementation for notification callbacks
typedef SelectNotificationCallback = Future<dynamic> Function(String? payload);

// Web implementation of NotificationService
class NotificationService {
  final Ref _ref;
  
  NotificationService(this._ref) {
    debugPrint('⟹ [Notification Web Stub] NotificationService initialized');
  }

  Future<void> initialize() async {
    debugPrint('⟹ [Notification Web Stub] initialization skipped for web');
  }

  void subscribeToSocketEvents(dynamic socketService) {
    debugPrint('⟹ [Notification Web Stub] subscribeToSocketEvents called');
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('⟹ [Notification Web Stub] showNotification: $title - $body');
    // In a real implementation, we could use browser notifications API
    // but for this stub we'll just log
  }
}

// Provider for Web NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

// Provider for notification plugin
final localNotificationsPluginProvider = Provider<FlutterLocalNotificationsPlugin>((ref) {
  return FlutterLocalNotificationsPlugin();
}); 