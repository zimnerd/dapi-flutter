import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';
import '../utils/logger.dart';

/// Provider for tracking typing status in conversations
final typingUsersProvider = StateNotifierProvider<TypingUsersNotifier, Map<String, Map<String, dynamic>>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final logger = Logger('TypingProvider');
  return TypingUsersNotifier(socketService, logger);
});

/// Notifier that tracks which users are typing in which conversations
class TypingUsersNotifier extends StateNotifier<Map<String, Map<String, dynamic>>> {
  final SocketService _socketService;
  final Logger _logger;
  StreamSubscription? _typingSubscription;
  
  /// Timer map to track when to automatically clear typing status after inactivity
  final Map<String, Timer> _typingTimers = {};
  
  TypingUsersNotifier(this._socketService, this._logger) : super({}) {
    _subscribeToTypingEvents();
  }
  
  /// Subscribe to typing events from the socket
  void _subscribeToTypingEvents() {
    _typingSubscription = _socketService.typingStatus.listen((data) {
      _logger.debug('Typing status update received: $data');
      final userId = data['user_id'];
      final conversationId = data['conversation_id'];
      final isTyping = data['typing'] ?? false;
      
      if (userId != null && conversationId != null) {
        _updateTypingStatus(conversationId, userId, isTyping);
      }
    });
  }
  
  /// Update typing status for a user in a conversation
  void _updateTypingStatus(String conversationId, String userId, bool isTyping) {
    final currentState = Map<String, Map<String, dynamic>>.from(state);
    
    // Create conversation entry if it doesn't exist
    if (!currentState.containsKey(conversationId)) {
      currentState[conversationId] = {};
    }
    
    // Cancel existing timer if any
    _typingTimers[userId]?.cancel();
    
    if (isTyping) {
      // Update typing status
      currentState[conversationId]?[userId] = {
        'isTyping': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch
      };
      
      // Set timer to automatically clear typing status after 10 seconds
      _typingTimers[userId] = Timer(const Duration(seconds: 10), () {
        _updateTypingStatus(conversationId, userId, false);
      });
    } else {
      // Remove typing status
      currentState[conversationId]?.remove(userId);
      
      // Remove empty conversation maps
      if (currentState[conversationId]?.isEmpty ?? false) {
        currentState.remove(conversationId);
      }
    }
    
    state = currentState;
  }
  
  /// Notify server that current user is typing in a conversation
  void sendTypingStart(String conversationId) {
    if (_socketService.isConnected) {
      _logger.debug('Sending typing start for conversation: $conversationId');
      _socketService.sendTypingStart(conversationId);
    }
  }
  
  /// Notify server that current user stopped typing in a conversation
  void sendTypingStop(String conversationId) {
    if (_socketService.isConnected) {
      _logger.debug('Sending typing stop for conversation: $conversationId');
      _socketService.sendTypingStop(conversationId);
    }
  }
  
  /// Check if any user is typing in a conversation
  bool isAnyoneTypingInConversation(String conversationId) {
    return state.containsKey(conversationId) && 
           (state[conversationId]?.isNotEmpty ?? false);
  }
  
  /// Get the first user ID that is typing in a conversation
  String? getFirstTypingUser(String conversationId) {
    if (isAnyoneTypingInConversation(conversationId)) {
      return state[conversationId]?.keys.first;
    }
    return null;
  }
  
  @override
  void dispose() {
    _typingSubscription?.cancel();
    _typingTimers.forEach((_, timer) => timer.cancel());
    _typingTimers.clear();
    super.dispose();
  }
}

/// Extension for backward compatibility
extension TypingMapExtension on Map<String, Map<String, dynamic>> {
  /// Check if user is typing in specific conversation
  bool isUserTypingInConversation(String conversationId) {
    return this.containsKey(conversationId) && 
           (this[conversationId]?.isNotEmpty ?? false);
  }
  
  /// Get name of typing user for display
  String getTypingUserNameForConversation(String conversationId) {
    if (isUserTypingInConversation(conversationId)) {
      final userId = this[conversationId]?.keys.first;
      if (userId != null) {
        // Use generic name if we don't have the real name
        return 'Someone';
      }
    }
    return '';
  }
} 