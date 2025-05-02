import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
// For user info if needed later
import '../providers/chat_message_actions.dart';
import 'dart:async';
import '../utils/logger.dart';

final Logger _logger = Logger('ChatProvider');

// State managed by the notifier: a list of messages
typedef MessageListState = List<Message>;

// Notifier class
class ChatMessagesNotifier extends StateNotifier<MessageListState> {
  final String
      conversationId; // Identify which conversation this notifier manages
  final Ref ref;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _errorSubscription;

  ChatMessagesNotifier(this.ref, this.conversationId) : super([]) {
    _logger.info(
        "🔄 CHAT NOTIFIER: Creating chat notifier for conversation $conversationId");
    _loadInitialMessages();
    _listenForMessages();
    _listenForErrors();
  }

  // Load initial messages from server
  Future<void> _loadInitialMessages() async {
    try {
      _logger.info(
          "📂 LOAD: Attempting to load initial messages for conversation: $conversationId");
      final chatService = ref.read(chatActionsServiceProvider);
      if (chatService.isConnected) {
        _logger.info(
            "📂 LOAD: Chat service connected, will receive messages via stream");
      } else {
        _logger.warning(
            "⚠️ LOAD WARNING: Chat service not connected. Please check connection.");

        // Try to connect if not connected
        _logger.info(
            "🔄 ATTEMPTING CONNECTION: Initializing socket and connecting...");
        await chatService.initSocket();
        chatService.connect();

        // Check connection status after a delay
        Future.delayed(Duration(seconds: 2), () {
          final isConnected = chatService.isConnected;
          _logger.info(
              "📡 CONNECTION STATUS AFTER ATTEMPT: ${isConnected ? 'Connected' : 'Failed to Connect'}");
        });
      }
    } catch (e) {
      _logger.error("❌ LOAD ERROR: Error loading initial messages: $e");
    }
  }

  // Listen for real-time messages
  void _listenForMessages() {
    try {
      _logger.info(
          "👂 LISTEN: Setting up message listener for conversation $conversationId");
      final chatService = ref.read(chatActionsServiceProvider);
      _messageSubscription = chatService.onNewMessage.listen((data) {
        _logger.info("📩 RECEIVED: Message via WebSocket: $data");

        // Check if this message belongs to this conversation
        final bool messageForThisConversation =
            data['conversationId'] == conversationId ||
                data['conversation_id'] == conversationId ||
                data['receiverId'] == conversationId ||
                data['receiver_id'] == conversationId;

        if (messageForThisConversation) {
          _logger.info("✅ MATCH: Message is for this conversation");
          final message = ChatMessageActions.createMessageFromData(data);
          _addMessageToState(message);
        } else {
          _logger.info("❌ MISMATCH: Message is NOT for this conversation");
          _logger.info(
              "Expected: $conversationId, Got: ${data['conversationId'] ?? data['conversation_id'] ?? data['receiverId'] ?? data['receiver_id'] ?? 'unknown'}");
        }
      }, onError: (error) {
        _logger.error("❌ STREAM ERROR: Error in message stream: $error");
      });

      _logger.info("👂 LISTEN: Message listener setup complete");
    } catch (e) {
      _logger.error("❌ SETUP ERROR: Error setting up message listener: $e");
    }
  }

  // Listen for WebSocket errors
  void _listenForErrors() {
    try {
      _logger.info("👂 LISTEN: Setting up error listener");
      final chatService = ref.read(chatActionsServiceProvider);
      _errorSubscription = chatService.onError.listen((error) {
        _logger.error("❌ WEBSOCKET ERROR RECEIVED: $error");
      });
    } catch (e) {
      _logger.error("❌ SETUP ERROR: Error setting up error listener: $e");
    }
  }

  // Add a new message to state
  void _addMessageToState(Message message) {
    _logger.info("➕ ADD TO STATE: Adding message to state: ${message.id}");

    // Check if message already exists in state to avoid duplicates
    final existingMessage = state.any((m) => m.id == message.id);
    if (existingMessage) {
      _logger.info(
          "⚠️ DUPLICATE: Message ${message.id} already exists in state, updating instead");
      state = state.map((m) => m.id == message.id ? message : m).toList();
    } else {
      _logger.info("✅ NEW MESSAGE: Adding new message to state");
      state = [...state, message];
    }

    _logger.info("🔄 SORT: Sorting messages by timestamp");
    state.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _logger.info("📊 STATE: Current message count: ${state.length}");
  }

  // Add a new message (sent by the current user)
  void addMessage(String text) {
    if (text.trim().isEmpty) {
      _logger.info("⚠️ EMPTY: Attempted to send empty message, ignoring");
      return;
    }

    _logger.info("📤 UI SEND: Sending message from UI: $text");

    // Send message through WebSocket
    final chatService = ref.read(chatActionsServiceProvider);
    final isConnected = chatService.isConnected;
    _logger.info(
        "📡 CONNECTION CHECK: WebSocket ${isConnected ? 'connected' : 'disconnected'}");

    if (isConnected) {
      _logger.info("📤 WEBSOCKET SEND: Sending via WebSocket");
      chatService.sendPrivateMessage(conversationId, text);
    } else {
      _logger.warning(
          "⚠️ CONNECTION WARNING: Not connected, will attempt to connect and send");
      // This will be handled by ChatMessageActions.addMessage
    }

    // Optimistically add to UI (will be confirmed via WebSocket)
    final newMessageId = "temp-${DateTime.now().millisecondsSinceEpoch}";
    _logger
        .info("🆔 TEMP ID: Creating temporary message with ID: $newMessageId");

    final newMessage = Message(
      id: newMessageId,
      conversationId: conversationId,
      senderId: 'currentUserId', // Will need to get from AuthService
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      reactions: [],
      isRead: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _logger.info("💬 OPTIMISTIC: Adding optimistic message to UI");
    _addMessageToState(newMessage);
  }

  // Toggle a reaction on a specific message
  void toggleReaction(String messageId, String emoji) {
    _logger
        .info("👍 REACTION UI: Toggling reaction $emoji on message $messageId");

    // This functionality would need to be implemented in the server
    // For now, just update the UI optimistically
    state = state.map((message) {
      if (message.id == messageId) {
        final currentReactions = List<String>.from(message.reactions ?? []);
        if (currentReactions.contains(emoji)) {
          _logger.info(
              "➖ REMOVE REACTION: Removing $emoji from message $messageId");
          currentReactions.remove(emoji);
        } else {
          _logger.info("➕ ADD REACTION: Adding $emoji to message $messageId");
          currentReactions.add(emoji);
        }
        return message.copyWith(reactions: currentReactions);
      } else {
        return message;
      }
    }).toList();
  }

  // Mark messages as read
  void markMessagesAsRead(String currentUserId) {
    _logger.info(
        "👁️ READ UI: Marking messages as read in conversation $conversationId");

    // Mark as read on server
    final chatService = ref.read(chatActionsServiceProvider);
    _logger.info(
        "📡 READ CHECK: WebSocket ${chatService.isConnected ? 'connected' : 'disconnected'}");

    // Since we need message IDs for the real implementation and don't have them yet
    // Just update UI optimistically for now
    _logger.info("👁️ READ OPTIMISTIC: Updating message status in UI");
    state = state.map((message) {
      if (!message.isFromCurrentUserId(currentUserId) &&
          message.status != MessageStatus.read) {
        _logger.info("👁️ READ UPDATE: Marking message ${message.id} as read");
        return message.copyWith(status: MessageStatus.read);
      }
      return message;
    }).toList();
  }

  // Send typing indicator
  void sendTypingIndicator(bool isTyping) {
    _logger.info(
        "⌨️ TYPING UI: ${isTyping ? 'Started' : 'Stopped'} typing in conversation $conversationId");

    final chatService = ref.read(chatActionsServiceProvider);
    _logger.info(
        "📡 TYPING CHECK: WebSocket ${chatService.isConnected ? 'connected' : 'disconnected'}");

    if (chatService.isConnected) {
      if (isTyping) {
        _logger.info("⌨️ TYPING SEND: Sending typing indicator");
        chatService.startTyping(conversationId);
      } else {
        _logger.info("⌨️ TYPING STOP: Sending stop typing indicator");
        chatService.stopTyping(conversationId);
      }
    } else {
      _logger.warning(
          "⚠️ TYPING WARNING: WebSocket not connected, typing indicator not sent");
    }
  }

  @override
  void dispose() {
    _logger.info(
        "🧹 CLEANUP: Disposing chat notifier for conversation $conversationId");
    _messageSubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }
}

// Provider for message notifier
final chatMessagesNotifierProvider = StateNotifierProvider.family<
    ChatMessagesNotifier, MessageListState, String>((ref, conversationId) {
  _logger.info(
      "🔄 PROVIDER: Creating chat messages notifier provider for $conversationId");
  return ChatMessagesNotifier(ref, conversationId);
});

// Define the provider that returns a stream of messages
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<Message>, String>((ref, conversationId) {
  _logger.info(
      "🔄 STREAM PROVIDER: Creating real-time message stream for $conversationId");

  // Initialize chat connection if not already connected
  final chatService = ref.read(chatActionsServiceProvider);

  _logger.info(
      "📡 INIT CHECK: WebSocket ${chatService.isConnected ? 'already connected' : 'not connected'}");
  if (!chatService.isConnected) {
    _logger.info("🔌 AUTO-CONNECT: Initializing connection from provider");
    chatService.initSocket().then((_) {
      _logger.info("🔌 SOCKET INIT: Socket initialized, connecting...");
      chatService.connect();

      // Check connection status after a delay
      Future.delayed(Duration(seconds: 2), () {
        final isConnected = chatService.isConnected;
        _logger.info(
            "📡 AUTO-CONNECT STATUS: ${isConnected ? 'Connected' : 'Failed to Connect'}");
      });
    }).catchError((error) {
      _logger.error(
          "❌ AUTO-CONNECT ERROR: Failed to initialize connection: $error");
    });
  }

  // Use the state notifier to manage messages
  final messagesStream =
      ref.watch(chatMessagesNotifierProvider(conversationId).notifier).stream;
  _logger.info("🔄 STREAM SETUP: Returning message stream");
  return messagesStream;
});
