import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';
import '../models/message.dart';

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Service to handle local push notifications
class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger('NotificationService');
  
  // Stream controller for handling notification taps
  final StreamController<String> selectNotificationStream = 
      StreamController<String>.broadcast();
  
  // Key for grouping chat notifications
  static const String _chatGroupKey = 'com.datingapp.chat';
  
  NotificationService() {
    _initNotifications();
  }
  
  Future<void> _initNotifications() async {
    try {
      // Initialize notification settings for Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Initialize notification settings for iOS
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            onDidReceiveLocalNotification: (id, title, body, payload) {
              return;
            }
          );
      
      // Initialize settings for both platforms
      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      // Initialize the plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          if (details.payload != null) {
            selectNotificationStream.add(details.payload!);
          }
        },
      );
      
      _logger.info('Local notifications initialized');
      
      // Request notification permissions for iOS
      if (Platform.isIOS) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        _logger.info('iOS notification permissions requested');
      }
    } catch (e) {
      _logger.error('Error initializing notifications: $e');
    }
  }
  
  /// Show a new message notification
  Future<void> showMessageNotification(Message message, String senderName) async {
    try {
      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'messages_channel',
        'Messages',
        channelDescription: 'Notifications for new messages',
        importance: Importance.high,
        priority: Priority.high,
        groupKey: _chatGroupKey,
        color: Colors.blue,
        icon: '@mipmap/ic_launcher',
      );
      
      final iOSPlatformChannelSpecifics = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      
      // Show the notification
      await _flutterLocalNotificationsPlugin.show(
        message.hashCode, // Use message hash as ID to avoid duplicates
        senderName,
        message.content,
        platformChannelSpecifics,
        payload: 'conversation:${message.conversationId}', // Payload for navigation
      );
      
      _logger.info('Showed notification for message from $senderName');
    } catch (e) {
      _logger.error('Error showing message notification: $e');
    }
  }
  
  /// Cancel notifications for a specific conversation
  Future<void> cancelConversationNotifications(String conversationId) async {
    // Since we can't query by payload in Flutter Local Notifications,
    // we would need to store notification IDs for each conversation.
    // For simplicity, we're cancelling all here.
    await _flutterLocalNotificationsPlugin.cancelAll();
    _logger.info('Cancelled notifications for conversation $conversationId');
  }
  
  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    _logger.info('Cancelled all notifications');
  }
  
  void dispose() {
    selectNotificationStream.close();
  }
} 