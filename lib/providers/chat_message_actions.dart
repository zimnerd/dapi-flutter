import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../models/message.dart';
import '../providers/providers.dart';

// Provider for the chat service actions
// We're using a different name to avoid conflict with the existing chatServiceProvider
final chatActionsServiceProvider = Provider<ChatService>((ref) {
  print("🔄 INIT: Creating chatActionsServiceProvider");
  final chatService = ChatService();

  // Initialize Auth Service immediately
  final authService = ref.read(authServiceProvider);
  chatService.initializeAuthService(authService);
  print("🔄 INIT: ChatService initialized with AuthService");

  return chatService;
});

// Utility class to handle message actions
class ChatMessageActions {
  // Add a new message (sent by the current user)
  static void addMessage(WidgetRef ref, String conversationId, String text,
      {String? mediaUrl}) {
    print("📤 SEND: Adding message to conversation $conversationId: $text");

    // Check WebSocket connection status
    final chatService = ref.read(chatActionsServiceProvider);
    final isConnected = chatService.isConnected;
    print("📡 WEBSOCKET STATUS: ${isConnected ? 'Connected' : 'Disconnected'}");

    if (!isConnected) {
      print(
          "⚠️ WARNING: WebSocket not connected! Attempting to connect and send...");
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
        print(
            "📡 WEBSOCKET RECONNECT STATUS: ${isConnected ? 'Connected' : 'Still Disconnected'}");

        if (isConnected) {
          print("📤 RESEND: Sending message after reconnection");
          chatService.sendPrivateMessage(conversationId, text,
              mediaUrl: mediaUrl);
        } else {
          print("❌ ERROR: Failed to reconnect WebSocket. Message not sent.");
        }
      });
    });
  }

  // Toggle a reaction on a specific message
  static void toggleReaction(
      WidgetRef ref, String conversationId, String messageId, String emoji) {
    print(
        "👍 REACTION: Toggling reaction $emoji on message $messageId in conversation $conversationId");

    // This functionality would need to be implemented in the ChatService class
    // Currently, there's no direct method for reactions in the existing ChatService
  }

  // Mark messages as read
  static void markMessagesAsRead(WidgetRef ref, String conversationId) {
    print("👁️ READ: Marking messages as read in conversation $conversationId");

    // The existing ChatService doesn't have a direct method for this yet,
    // but this would integrate with it once available
  }

  // Send typing indicator
  static void sendTypingIndicator(WidgetRef ref, String conversationId) {
    print(
        "⌨️ TYPING: Sending typing indicator for conversation $conversationId");

    // Get the chat service from the provider
    final chatService = ref.read(chatActionsServiceProvider);

    // The typing method would need to be implemented or used from ChatService
    chatService.startTyping(conversationId);
  }

  // Stop typing indicator
  static void stopTypingIndicator(WidgetRef ref, String conversationId) {
    print(
        "⌨️ STOPPED TYPING: Stopping typing indicator for conversation $conversationId");

    // Get the chat service from the provider
    final chatService = ref.read(chatActionsServiceProvider);

    // Stop the typing indicator
    chatService.stopTyping(conversationId);
  }

  // Initialize the chat connection
  static Future<void> initializeChat(WidgetRef ref) async {
    print("🔌 INIT: Initializing chat connection");
    final chatService = ref.read(chatActionsServiceProvider);

    try {
      // Ensure AuthService is initialized
      final authService = ref.read(authServiceProvider);
      chatService.initializeAuthService(authService);
      print("🔌 INIT: Auth service initialized");

      await chatService.initSocket();
      print("🔌 INIT: Chat socket initialized");

      chatService.connect();
      print("🔌 INIT: Chat connection requested");

      // Check connection after a delay
      Future.delayed(Duration(seconds: 2), () {
        final isConnected = chatService.isConnected;
        print(
            "📡 WEBSOCKET INIT STATUS: ${isConnected ? 'Connected' : 'Failed to Connect'}");
      });
    } catch (e) {
      print("❌ ERROR: Failed to initialize chat connection: $e");
    }
  }

  // Disconnect from chat
  static void disconnectChat(WidgetRef ref) {
    print("🔌 DISCONNECT: Disconnecting from chat");
    final chatService = ref.read(chatActionsServiceProvider);
    chatService.disconnect();
  }

  // Get conversation stream for real-time updates
  static Stream<Map<String, dynamic>> getMessageStream(WidgetRef ref) {
    print("📡 STREAM: Setting up message stream");
    final chatService = ref.read(chatActionsServiceProvider);

    // Add stream transformation for debugging
    return chatService.onNewMessage.map((data) {
      print("📩 RECEIVED MESSAGE: $data");
      return data;
    });
  }

  // Get typing indicator stream
  static Stream<Map<String, dynamic>> getTypingStream(WidgetRef ref) {
    print("📡 STREAM: Setting up typing indicator stream");
    final chatService = ref.read(chatActionsServiceProvider);

    // Add stream transformation for debugging
    return chatService.onTypingEvent.map((data) {
      print("⌨️ TYPING EVENT: $data");
      return data;
    });
  }

  // Get online status stream
  static Stream<Map<String, dynamic>> getOnlineStatusStream(WidgetRef ref) {
    print("📡 STREAM: Setting up online status stream");
    final chatService = ref.read(chatActionsServiceProvider);

    // Add stream transformation for debugging
    return chatService.onOnlineStatus.map((data) {
      print("🟢 ONLINE STATUS: $data");
      return data;
    });
  }

  // Get error stream
  static Stream<String> getErrorStream(WidgetRef ref) {
    print("📡 STREAM: Setting up error stream");
    final chatService = ref.read(chatActionsServiceProvider);

    // Add stream transformation for debugging
    return chatService.onError.map((error) {
      print("❌ WEBSOCKET ERROR: $error");
      return error;
    });
  }

  // Create a Message object from WebSocket data
  static Message createMessageFromData(Map<String, dynamic> data) {
    print("📝 PARSING MESSAGE: $data");

    final message = Message(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: data['conversationId'] ?? data['conversation_id'] ?? '',
      senderId: data['senderId'] ?? data['sender_id'] ?? '',
      text: data['message'] ?? data['text'] ?? data['content'] ?? '',
      timestamp:
          DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      status: MessageStatus.sent,
      reactions: [],
    );

    print("📝 CREATED MESSAGE: $message");
    return message;
  }
}
