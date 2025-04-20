import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
// For user info if needed later
import '../providers/chat_message_actions.dart';
import 'dart:async';

// State managed by the notifier: a list of messages
typedef MessageListState = List<Message>;

// Notifier class
class ChatMessagesNotifier extends StateNotifier<MessageListState> {
  final String
      conversationId; // Identify which conversation this notifier manages
  final StateNotifierProviderRef ref;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _errorSubscription;

  ChatMessagesNotifier(this.ref, this.conversationId) : super([]) {
    print(
        "🔄 CHAT NOTIFIER: Creating chat notifier for conversation $conversationId");
    _loadInitialMessages();
    _listenForMessages();
    _listenForErrors();
  }

  // Load initial messages from server
  Future<void> _loadInitialMessages() async {
    try {
      print(
          "📂 LOAD: Attempting to load initial messages for conversation: $conversationId");
      final chatService = ref.read(chatActionsServiceProvider);
      if (chatService.isConnected) {
        print(
            "📂 LOAD: Chat service connected, will receive messages via stream");
      } else {
        print(
            "⚠️ LOAD WARNING: Chat service not connected. Please check connection.");

        // Try to connect if not connected
        print(
            "🔄 ATTEMPTING CONNECTION: Initializing socket and connecting...");
        await chatService.initSocket();
        chatService.connect();

        // Check connection status after a delay
        Future.delayed(Duration(seconds: 2), () {
          final isConnected = chatService.isConnected;
          print(
              "📡 CONNECTION STATUS AFTER ATTEMPT: ${isConnected ? 'Connected' : 'Failed to Connect'}");
        });
      }
    } catch (e) {
      print("❌ LOAD ERROR: Error loading initial messages: $e");
    }
  }

  // Listen for real-time messages
  void _listenForMessages() {
    try {
      print(
          "👂 LISTEN: Setting up message listener for conversation $conversationId");
      final chatService = ref.read(chatActionsServiceProvider);
      _messageSubscription = chatService.onNewMessage.listen((data) {
        print("📩 RECEIVED: Message via WebSocket: $data");

        // Check if this message belongs to this conversation
        final bool messageForThisConversation =
            data['conversationId'] == conversationId ||
                data['conversation_id'] == conversationId ||
                data['receiverId'] == conversationId ||
                data['receiver_id'] == conversationId;

        if (messageForThisConversation) {
          print("✅ MATCH: Message is for this conversation");
          final message = ChatMessageActions.createMessageFromData(data);
          _addMessageToState(message);
        } else {
          print("❌ MISMATCH: Message is NOT for this conversation");
          print(
              "Expected: $conversationId, Got: ${data['conversationId'] ?? data['conversation_id'] ?? data['receiverId'] ?? data['receiver_id'] ?? 'unknown'}");
        }
      }, onError: (error) {
        print("❌ STREAM ERROR: Error in message stream: $error");
      });

      print("👂 LISTEN: Message listener setup complete");
    } catch (e) {
      print("❌ SETUP ERROR: Error setting up message listener: $e");
    }
  }

  // Listen for WebSocket errors
  void _listenForErrors() {
    try {
      print("👂 LISTEN: Setting up error listener");
      final chatService = ref.read(chatActionsServiceProvider);
      _errorSubscription = chatService.onError.listen((error) {
        print("❌ WEBSOCKET ERROR RECEIVED: $error");
      });
    } catch (e) {
      print("❌ SETUP ERROR: Error setting up error listener: $e");
    }
  }

  // Add a new message to state
  void _addMessageToState(Message message) {
    print("➕ ADD TO STATE: Adding message to state: ${message.id}");

    // Check if message already exists in state to avoid duplicates
    final existingMessage = state.any((m) => m.id == message.id);
    if (existingMessage) {
      print(
          "⚠️ DUPLICATE: Message ${message.id} already exists in state, updating instead");
      state = state.map((m) => m.id == message.id ? message : m).toList();
    } else {
      print("✅ NEW MESSAGE: Adding new message to state");
      state = [...state, message];
    }

    print("🔄 SORT: Sorting messages by timestamp");
    state.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    print("📊 STATE: Current message count: ${state.length}");
  }

  // Add a new message (sent by the current user)
  void addMessage(String text) {
    if (text.trim().isEmpty) {
      print("⚠️ EMPTY: Attempted to send empty message, ignoring");
      return;
    }

    print("📤 UI SEND: Sending message from UI: $text");

    // Send message through WebSocket
    final chatService = ref.read(chatActionsServiceProvider);
    final isConnected = chatService.isConnected;
    print(
        "📡 CONNECTION CHECK: WebSocket ${isConnected ? 'connected' : 'disconnected'}");

    if (isConnected) {
      print("📤 WEBSOCKET SEND: Sending via WebSocket");
      chatService.sendPrivateMessage(conversationId, text);
    } else {
      print(
          "⚠️ CONNECTION WARNING: Not connected, will attempt to connect and send");
      // This will be handled by ChatMessageActions.addMessage
    }

    // Optimistically add to UI (will be confirmed via WebSocket)
    final newMessageId = "temp-${DateTime.now().millisecondsSinceEpoch}";
    print("🆔 TEMP ID: Creating temporary message with ID: $newMessageId");

    final newMessage = Message(
      id: newMessageId,
      conversationId: conversationId,
      senderId: 'currentUserId', // Will need to get from AuthService
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      reactions: [],
    );

    print("💬 OPTIMISTIC: Adding optimistic message to UI");
    _addMessageToState(newMessage);
  }

  // Toggle a reaction on a specific message
  void toggleReaction(String messageId, String emoji) {
    print("👍 REACTION UI: Toggling reaction $emoji on message $messageId");

    // This functionality would need to be implemented in the server
    // For now, just update the UI optimistically
    state = state.map((message) {
      if (message.id == messageId) {
        final currentReactions = List<String>.from(message.reactions ?? []);
        if (currentReactions.contains(emoji)) {
          print("➖ REMOVE REACTION: Removing $emoji from message $messageId");
          currentReactions.remove(emoji);
        } else {
          print("➕ ADD REACTION: Adding $emoji to message $messageId");
          currentReactions.add(emoji);
        }
        return message.copyWith(reactions: currentReactions);
      } else {
        return message;
      }
    }).toList();
  }

  // Mark messages as read
  void markMessagesAsRead() {
    print(
        "👁️ READ UI: Marking messages as read in conversation $conversationId");

    // Mark as read on server
    final chatService = ref.read(chatActionsServiceProvider);
    print(
        "📡 READ CHECK: WebSocket ${chatService.isConnected ? 'connected' : 'disconnected'}");

    // Since we need message IDs for the real implementation and don't have them yet
    // Just update UI optimistically for now
    print("👁️ READ OPTIMISTIC: Updating message status in UI");
    state = state.map((message) {
      if (!message.isFromCurrentUser && message.status != MessageStatus.read) {
        print("👁️ READ UPDATE: Marking message ${message.id} as read");
        return message.copyWith(status: MessageStatus.read);
      }
      return message;
    }).toList();
  }

  // Send typing indicator
  void sendTypingIndicator(bool isTyping) {
    print(
        "⌨️ TYPING UI: ${isTyping ? 'Started' : 'Stopped'} typing in conversation $conversationId");

    final chatService = ref.read(chatActionsServiceProvider);
    print(
        "📡 TYPING CHECK: WebSocket ${chatService.isConnected ? 'connected' : 'disconnected'}");

    if (chatService.isConnected) {
      if (isTyping) {
        print("⌨️ TYPING SEND: Sending typing indicator");
        chatService.startTyping(conversationId);
      } else {
        print("⌨️ TYPING STOP: Sending stop typing indicator");
        chatService.stopTyping(conversationId);
      }
    } else {
      print(
          "⚠️ TYPING WARNING: WebSocket not connected, typing indicator not sent");
    }
  }

  @override
  void dispose() {
    print(
        "🧹 CLEANUP: Disposing chat notifier for conversation $conversationId");
    _messageSubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }
}

// Provider for message notifier
final chatMessagesNotifierProvider = StateNotifierProvider.family<
    ChatMessagesNotifier, MessageListState, String>((ref, conversationId) {
  print(
      "🔄 PROVIDER: Creating chat messages notifier provider for $conversationId");
  return ChatMessagesNotifier(ref, conversationId);
});

// Define the provider that returns a stream of messages
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<Message>, String>((ref, conversationId) {
  print(
      "🔄 STREAM PROVIDER: Creating real-time message stream for $conversationId");

  // Initialize chat connection if not already connected
  final chatService = ref.read(chatActionsServiceProvider);

  print(
      "📡 INIT CHECK: WebSocket ${chatService.isConnected ? 'already connected' : 'not connected'}");
  if (!chatService.isConnected) {
    print("🔌 AUTO-CONNECT: Initializing connection from provider");
    chatService.initSocket().then((_) {
      print("🔌 SOCKET INIT: Socket initialized, connecting...");
      chatService.connect();

      // Check connection status after a delay
      Future.delayed(Duration(seconds: 2), () {
        final isConnected = chatService.isConnected;
        print(
            "📡 AUTO-CONNECT STATUS: ${isConnected ? 'Connected' : 'Failed to Connect'}");
      });
    }).catchError((error) {
      print("❌ AUTO-CONNECT ERROR: Failed to initialize connection: $error");
    });
  }

  // Use the state notifier to manage messages
  final messagesStream =
      ref.watch(chatMessagesNotifierProvider(conversationId).notifier).stream;
  print("🔄 STREAM SETUP: Returning message stream");
  return messagesStream;
});
