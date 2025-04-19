import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';
import '../models/message.dart' as app_message;
import '../utils/platform/platform_checker.dart';
import 'package:dating_app/models/conversation.dart';
import 'package:dating_app/providers/navigator_key_provider.dart';
import 'package:dating_app/screens/conversation_screen.dart';
// Alias the import from flutter_local_notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

/// Service to handle local push notifications
class NotificationService {
  final Logger _logger = Logger('NotificationService');
  
  // Stream controller for handling notification taps
  final StreamController<String> selectNotificationStream = 
      StreamController<String>.broadcast();
  
  // Optional platform-specific implementation
  fln.FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  
  // Flag to track initialization
  bool _isInitialized = false;
  
  final Ref _ref;
  
  NotificationService(this._ref) {
    // Only initialize if not on web
    if (!PlatformChecker.isWeb) {
      _initNotifications();
    } else {
      _logger.info('Running on web platform, using web notifications');
      _isInitialized = true;
    }
  }
  
  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (!PlatformChecker.isWeb) {
      await _initNotifications();
    } else {
      _logger.info('Running on web platform, notifications limited');
    }
    
    _isInitialized = true;
  }
  
  Future<void> _initNotifications() async {
    if (PlatformChecker.isWeb) {
      _logger.info('Cannot initialize local notifications on web');
      return;
    }
    
    try {
      _flutterLocalNotificationsPlugin = fln.FlutterLocalNotificationsPlugin();
      
      // Initialize notification settings for Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Initialize notification settings for iOS (if on mobile)
      final DarwinInitializationSettings? initializationSettingsIOS = 
          PlatformChecker.isIOS ? 
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          ) : null;
      
      // Initialize settings for both platforms
      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      // Initialize the plugin
      await _flutterLocalNotificationsPlugin?.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          if (details.payload != null) {
            selectNotificationStream.add(details.payload!);
          }
        },
      );
      
      _logger.info('Local notifications initialized');
      
      // Request permissions on iOS (if on mobile)
      if (PlatformChecker.isIOS) {
        await _flutterLocalNotificationsPlugin
            ?.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        _logger.info('iOS notification permissions requested');
      }
      
      _isInitialized = true;
    } catch (e) {
      _logger.error('Error initializing notifications: $e');
    }
  }
  
  /// Show a new message notification
  Future<void> showMessageNotification(app_message.Message message, String senderName) async {
    // Skip on web
    if (PlatformChecker.isWeb) {
      _logger.info('Notifications not fully supported on web');
      return;
    }
    
    if (!_isInitialized || _flutterLocalNotificationsPlugin == null) {
      _logger.warn('Notification service not initialized');
      return;
    }
    
    try {
      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'messages_channel',
        'Messages',
        channelDescription: 'Notifications for new messages',
        importance: Importance.high,
        priority: Priority.high,
        groupKey: 'com.datingapp.chat',
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
      await _flutterLocalNotificationsPlugin?.show(
        message.hashCode, // Use message hash as ID to avoid duplicates
        senderName,
        message.messageText,
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
    if (PlatformChecker.isWeb || !_isInitialized || _flutterLocalNotificationsPlugin == null) {
      return;
    }
    
    // Since we can't query by payload in Flutter Local Notifications,
    // we would need to store notification IDs for each conversation.
    // For simplicity, we're cancelling all here.
    await _flutterLocalNotificationsPlugin?.cancelAll();
    _logger.info('Cancelled notifications for conversation $conversationId');
  }
  
  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (PlatformChecker.isWeb || !_isInitialized || _flutterLocalNotificationsPlugin == null) {
      return;
    }
    
    await _flutterLocalNotificationsPlugin?.cancelAll();
    _logger.info('Cancelled all notifications');
  }
  
  void dispose() {
    selectNotificationStream.close();
  }

  Future<void> showNotification(app_message.Message message, Conversation conversation) async {
    print('⟹ [NotificationService] Showing notification for message: ${message.id}');
    final String largeIconPath = await _downloadAndSaveFile(message.sender?.profile?.imageUrls?.first ?? '', 'largeIcon');
    final fln.Person person = fln.Person(
      name: message.sender?.name ?? 'Unknown Sender',
      icon: fln.FilePathAndroidIcon(largeIconPath),
      key: message.senderId,
    );

    final fln.MessagingStyleInformation messagingStyle = fln.MessagingStyleInformation(
      person,
      messages: [
        fln.Message( // Use aliased Message here
          message.content, // Assuming message.content holds the text
          message.timestamp,
          person,
        ),
      ],
      groupConversation: conversation.participants.length > 2,
      conversationTitle: conversation.name ?? 'Chat',
    );

    final fln.NotificationDetails notificationDetails = fln.NotificationDetails(
      android: AndroidNotificationDetails(
        'messages_channel',
        'Messages',
        channelDescription: 'Notifications for new messages',
        importance: Importance.high,
        priority: Priority.high,
        groupKey: 'com.datingapp.chat',
        color: Colors.blue,
        icon: '@mipmap/ic_launcher',
        styleInformation: messagingStyle,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        styleInformation: messagingStyle,
      ),
    );

    await _flutterLocalNotificationsPlugin?.show(
      message.hashCode,
      message.sender?.name ?? 'Unknown Sender',
      message.messageText,
      notificationDetails,
      payload: 'conversation:${message.conversationId}',
    );

    _logger.info('Showed notification for message from ${message.sender?.name}');
  }

  Future<void> _configureLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        _handleNotificationResponse(notificationResponse.payload);
      },
      // Add onDidReceiveBackgroundNotificationResponse if needed for background handling
    );
  }

  // Callback for iOS foreground notifications
  Future<dynamic> onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // Handle foreground notification display or navigation for iOS
    print('Foreground notification received on iOS: $payload');
     _handleNotificationResponse(payload); // Example: Navigate based on payload
  }

  void _handleNotificationResponse(String? payload) {
    if (payload != null) {
       print('Notification payload: $payload');
       try {
         final data = jsonDecode(payload);
         final String? conversationId = data['conversationId'];
         final String? conversationName = data['conversationName']; // Optional: pass name if needed

         if (conversationId != null) {
            print('Navigating to conversation: $conversationId');
           // Use the global navigator key provider
           final navigatorKey = _ref.read(navigatorKeyProvider);
            if (navigatorKey.currentState != null) {
                 navigatorKey.currentState!.pushNamed(
                   ConversationScreen.routeName,
                   arguments: {
                     'conversationId': conversationId,
                     'conversationName': conversationName ?? 'Chat', // Pass name or default
                     // Pass other necessary arguments if ConversationScreen requires them
                   },
                 );
               } else {
                print('Error: Navigator key current state is null.');
               }
         } else {
            print('Error: Conversation ID is null in payload.');
         }
       } catch (e) {
         print('Error decoding or handling notification payload: $e');
       }
     } else {
        print('Notification payload is null.');
     }
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    if (url.isEmpty) {
      // Return a default path or handle the empty URL case appropriately
      // For now, let's return an empty string, but you might need a placeholder image path
       print('Warning: Empty URL provided for download.');
      return '';
    }
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName.png'; // Assuming png, adjust if needed
    try {
      final http.Response response = await http.get(Uri.parse(url));
       if (response.statusCode == 200) {
         final File file = File(filePath);
         await file.writeAsBytes(response.bodyBytes);
         return filePath;
       } else {
          print('Error downloading file: ${response.statusCode} for URL $url');
          return ''; // Return empty or default path on error
       }
    } catch (e) {
      print('Error downloading or saving file: $e for URL $url');
      return ''; // Return empty or default path on error
    }
  }
} 