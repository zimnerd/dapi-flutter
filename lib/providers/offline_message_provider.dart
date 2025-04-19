import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';
import 'providers.dart';
import '../models/message.dart';
import '../utils/connectivity/network_manager.dart';

/// Provider for offline message queue
final offlineMessageQueueProvider = StateNotifierProvider<OfflineMessageQueueNotifier, List<Map<String, dynamic>>>((ref) {
  final logger = Logger('OfflineQueue');
  return OfflineMessageQueueNotifier(logger, ref);
});

/// Manages queued messages for sending when coming back online
class OfflineMessageQueueNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Logger _logger;
  final Ref _ref;
  StreamSubscription? _networkSubscription;

  OfflineMessageQueueNotifier(this._logger, this._ref) : super([]) {
    _monitorNetworkChanges();
  }

  /// Add a message to the queue
  void addToQueue(Map<String, dynamic> message) {
    _logger.info('Adding message to offline queue: ${message['text']}');
    state = [...state, message];
  }

  /// Remove message from queue by ID
  void removeFromQueue(String messageId) {
    _logger.info('Removing message from queue: $messageId');
    state = state.where((message) => message['id'] != messageId).toList();
  }

  /// Clear all messages for a specific conversation
  void clearConversationQueue(String conversationId) {
    _logger.info('Clearing queue for conversation: $conversationId');
    state = state.where((message) => message['conversation_id'] != conversationId).toList();
  }
  
  /// Clear the entire queue
  void clearQueue() {
    _logger.info('Clearing entire message queue');
    state = [];
  }

  /// Get queued messages for a specific conversation
  List<Map<String, dynamic>> getQueuedMessagesForConversation(String conversationId) {
    return state.where((message) => message['conversation_id'] == conversationId).toList();
  }

  /// Monitor network changes to process queue when coming back online
  void _monitorNetworkChanges() {
    _networkSubscription = _ref.listen(networkStatusProvider, (previous, next) {
      if (previous == NetworkStatus.offline && next == NetworkStatus.online) {
        _logger.info('Network restored - processing offline message queue (${state.length} messages)');
        _processQueue();
      }
    });
  }

  /// Process all queued messages when coming back online
  void _processQueue() {
    if (state.isEmpty) return;

    final socketService = _ref.read(socketServiceProvider);
    
    // Verify that socket is connected before attempting to send
    if (!socketService.isConnected) {
      _logger.warn('Socket not connected, cannot process queue');
      return;
    }

    // Group messages by conversation
    final groupedMessages = <String, List<Map<String, dynamic>>>{};
    
    for (final message in state) {
      final conversationId = message['conversation_id'] as String;
      groupedMessages.putIfAbsent(conversationId, () => []);
      groupedMessages[conversationId]!.add(message);
    }

    // Process each conversation's messages
    groupedMessages.forEach((conversationId, messages) {
      _logger.info('Processing ${messages.length} queued messages for conversation: $conversationId');
      
      // Join the conversation room first
      socketService.joinConversation(conversationId);
      
      // Send each message
      for (final message in messages) {
        _logger.info('Sending queued message: ${message['id']}');
        socketService.sendMessage(
          conversationId,
          message['text'] as String,
          extras: (message['extras'] as Map<String, dynamic>?) ?? {},
        );
        
        // Remove from queue after sending
        removeFromQueue(message['id'] as String);
      }
    });
  }

  /// Get a message from the queue by ID
  Map<String, dynamic>? getMessageById(String messageId) {
    try {
      return state.firstWhere((message) => message['id'] == messageId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    super.dispose();
  }
} 