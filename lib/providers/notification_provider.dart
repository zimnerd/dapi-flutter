import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../services/socket_service.dart';
import './providers.dart';

/// Provider that sets up notifications for the app
final notificationManagerProvider = Provider<NotificationManager>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final socketService = ref.watch(socketServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final profileService = ref.watch(profileServiceProvider);
  
  return NotificationManager(
    notificationService: notificationService,
    socketService: socketService,
    authService: authService,
    profileService: profileService,
    ref: ref,
  );
});

/// Manager class that configures notifications and listens for events
class NotificationManager {
  final NotificationService _notificationService;
  final SocketService _socketService;
  final AuthService _authService;
  final ProfileService _profileService;
  final Ref _ref;
  
  NotificationManager({
    required NotificationService notificationService,
    required SocketService socketService,
    required AuthService authService,
    required ProfileService profileService,
    required Ref ref,
  }) : _notificationService = notificationService,
       _socketService = socketService,
       _authService = authService,
       _profileService = profileService,
       _ref = ref {
    _init();
  }
  
  void _init() {
    // Listen for socket connection changes
    _socketService.onConnectionStatusChanged((isConnected) {
      if (isConnected) {
        _setupMessageListeners();
      }
    });
    
    // Setup listeners if already connected
    if (_socketService.isConnected) {
      _setupMessageListeners();
    }
    
    // Handle notification taps
    _notificationService.selectNotificationStream.stream.listen((payload) {
      _handleNotificationTap(payload);
    });
  }
  
  void _setupMessageListeners() {
    // Listen for new messages via socket
    _socketService.onMessageReceived((data) async {
      if (data == null) return;
      
      final userId = _authService.getUserId();
      final senderId = data['senderId'] as String?;
      
      // Only show notifications for messages from others
      if (senderId != null && senderId != userId) {
        final message = Message.fromJson(data);
        
        // Get sender name from profile or use fallback
        String senderName = data['senderName'] as String? ?? 'Someone';
        
        // Try to get profile details if not already provided
        if (senderName == 'Someone') {
          try {
            final profile = await _profileService.getProfile(senderId);
            if (profile != null) {
              senderName = profile.name;
            }
          } catch (e) {
            print('⟹ [NotificationManager] Error fetching sender profile: $e');
          }
        }
        
        // Show notification
        _notificationService.showMessageNotification(message, senderName);
      }
    });
  }
  
  void _handleNotificationTap(String payload) {
    // Extract conversation ID from payload
    if (payload.startsWith('conversation:')) {
      final conversationId = payload.substring('conversation:'.length);
      
      // Navigate to conversation screen (would be handled by router)
      print('⟹ [NotificationManager] Navigate to conversation: $conversationId');
      
      // Here we would typically use a navigation service
      // NavigationService.navigateToConversation(conversationId);
    }
  }
  
  // Cancel notifications for a specific conversation 
  // (Call this when entering a conversation)
  void cancelConversationNotifications(String conversationId) {
    _notificationService.cancelConversationNotifications(conversationId);
  }
} 