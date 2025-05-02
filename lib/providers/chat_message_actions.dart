import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../models/message.dart';
import '../providers/providers.dart';
import '../utils/logger.dart';

final Logger _logger = Logger('ChatMessageActions');

// Provider for the chat service actions
// We're using a different name to avoid conflict with the existing chatServiceProvider
final chatActionsServiceProvider = Provider<ChatService>((ref) {
  _logger.info("🔄 INIT: Creating chatActionsServiceProvider");
  final chatService = ChatService();

  // Initialize Auth Service immediately
  final authService = ref.read(authServiceProvider);
  chatService.initializeAuthService(authService);
  _logger.info("🔄 INIT: ChatService initialized with AuthService");

  return chatService;
});

// Utility class to handle message actions
class ChatMessageActions {
  // Add a new message (sent by the current user)
  static void addMessage(WidgetRef ref, String conversationId, String text,
      {String? mediaUrl}) {
    _logger
        .info("📤 SEND: Adding message to conversation $conversationId: $text");

    // Check WebSocket connection status
    final chatService = ref.read(chatActionsServiceProvider);
    final isConnected = chatService.isConnected;

    if (!isConnected) {
      _attemptReconnectAndSend(ref, chatService, conversationId, text,
          mediaUrl: mediaUrl);
      return;
    }

    // Send the message via WebSocket
    chatService.sendPrivateMessage(conversationId, text, mediaUrl: mediaUrl);
  }

  // Attempt to reconnect and send message
  static void _attemptReconnectAndSend(WidgetRef ref, ChatService chatService,
      String conversationId, String text,
      {String? mediaUrl}) {
    // Make sure AuthService is properly initialized
    final authService = ref.read(authServiceProvider);
    chatService.initializeAuthService(authService);

    chatService.initSocket().then((_) {
      chatService.connect();

      // Check if connection was successful
      Future.delayed(Duration(seconds: 2), () {
        final isConnected = chatService.isConnected;

        if (isConnected) {
          chatService.sendPrivateMessage(conversationId, text,
              mediaUrl: mediaUrl);
        } else {
          _logger.error(
              "❌ ERROR: Failed to reconnect WebSocket. Message not sent.");
        }
      });
    });
  }

  // Toggle a reaction on a specific message
  static void toggleReaction(
      WidgetRef ref, String conversationId, String messageId, String emoji) {
    _logger.info(
        "👍 REACTION: Toggling reaction $emoji on message $messageId in conversation $conversationId");

    // This functionality would need to be implemented in the ChatService class
    // Currently, there's no direct method for reactions in the existing ChatService
  }

  // Mark messages as read
  static void markMessagesAsRead(WidgetRef ref, String conversationId) {
    // The existing ChatService doesn't have a direct method for this yet,
    // but this would integrate with it once available
  }

  // Send typing indicator
  static void sendTypingIndicator(WidgetRef ref, String conversationId) {
    // Get the chat service from the provider
    final chatService = ref.read(chatActionsServiceProvider);

    // The typing method would need to be implemented or used from ChatService
    chatService.startTyping(conversationId);
  }

  // Stop typing indicator
  static void stopTypingIndicator(WidgetRef ref, String conversationId) {
    // Get the chat service from the provider
    final chatService = ref.read(chatActionsServiceProvider);

    // Stop the typing indicator
    chatService.stopTyping(conversationId);
  }

  // Initialize the chat connection
  static Future<void> initializeChat(WidgetRef ref) async {
    final chatService = ref.read(chatActionsServiceProvider);

    try {
      // Ensure AuthService is initialized
      final authService = ref.read(authServiceProvider);
      chatService.initializeAuthService(authService);

      await chatService.initSocket();

      chatService.connect();

      // Check connection after a delay
      Future.delayed(Duration(seconds: 2), () {
        final isConnected = chatService.isConnected;
        if (isConnected) {
          _logger.info("🔌 INIT: Chat connection established");
        } else {
          _logger.error("❌ ERROR: Failed to connect to chat");
        }
      });
    } catch (e) {
      _logger.error("❌ ERROR: Failed to initialize chat connection: $e");
    }
  }

  // Disconnect from chat
  static void disconnectChat(WidgetRef ref) {
    final chatService = ref.read(chatActionsServiceProvider);
    chatService.disconnect();
  }

  // Get conversation stream for real-time updates
  static Stream<Map<String, dynamic>> getMessageStream(WidgetRef ref) {
    final chatService = ref.read(chatActionsServiceProvider);

    // Add stream transformation for debugging
    return chatService.onNewMessage.map((data) {
      return data;
    });
  }

  // Get typing indicator stream
  static Stream<Map<String, dynamic>> getTypingStream(WidgetRef ref) {
    final chatService = ref.read(chatActionsServiceProvider);

    // Add stream transformation for debugging
    return chatService.onTypingEvent.map((data) {
      return data;
    });
  }

  // Get online status stream
  static Stream<Map<String, dynamic>> getOnlineStatusStream(WidgetRef ref) {
    final chatService = ref.read(chatActionsServiceProvider);

    // Add stream transformation for debugging
    return chatService.onOnlineStatus.map((data) {
      return data;
    });
  }

  // Get error stream
  static Stream<String> getErrorStream(WidgetRef ref) {
    final chatService = ref.read(chatActionsServiceProvider);

    // Add stream transformation for debugging
    return chatService.onError.map((error) {
      return error;
    });
  }

  // Create a Message object from WebSocket data
  static Message createMessageFromData(Map<String, dynamic> data) {
    final message = Message(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: data['conversationId'] ?? data['conversation_id'] ?? '',
      senderId: data['senderId'] ?? data['sender_id'] ?? '',
      text: data['message'] ?? data['text'] ?? data['content'] ?? '',
      timestamp:
          DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      status: MessageStatus.sent,
      reactions: [],
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : DateTime.now(),
    );

    return message;
  }
}
