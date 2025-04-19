import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_provider.dart';
import '../utils/logger.dart';

// Utility class to handle message actions
class ChatMessageActions {
  static final _logger = Logger('ChatActions');

  // Add a new message (sent by the current user)
  static void addMessage(WidgetRef ref, String conversationId, String text) {
    _logger.info("Adding message to conversation $conversationId");
    
    try {
      // Get the chat messages notifier and send message
      final chatNotifier = ref.read(chatMessagesProvider(conversationId).notifier);
      chatNotifier.sendMessage(text);
    } catch (e) {
      _logger.error("Error sending message: $e");
    }
  }
  
  // Notify that user is typing
  static void handleTyping(WidgetRef ref, String conversationId) {
    try {
      // Get the chat messages notifier and update typing status
      final chatNotifier = ref.read(chatMessagesProvider(conversationId).notifier);
      chatNotifier.handleTyping();
    } catch (e) {
      _logger.error("Error updating typing status: $e");
    }
  }
  
  // Stop typing notification
  static void stopTyping(WidgetRef ref, String conversationId) {
    try {
      // Get the chat messages notifier and update typing status
      final chatNotifier = ref.read(chatMessagesProvider(conversationId).notifier);
      chatNotifier.stopTyping();
    } catch (e) {
      _logger.error("Error stopping typing status: $e");
    }
  }
  
  // Mark messages as read
  static void markMessagesAsRead(WidgetRef ref, String conversationId) {
    _logger.info("Marking messages as read in conversation $conversationId");
    
    // This now happens automatically when messages are received
    // through the socket and in the _markMessagesAsRead method in the ChatMessagesNotifier
  }
} 