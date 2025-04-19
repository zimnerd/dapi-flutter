import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import '../utils/logger.dart';
import 'providers.dart';

/// Message loading states
enum MessageLoadingState {
  initial,
  loading,
  loaded,
  error,
}

/// Message provider state
class MessagesState {
  final Map<String, List<Message>> conversationMessages;
  final Map<String, MessageLoadingState> loadingStates;
  final Map<String, String> errorMessages;
  final Set<String> pendingMessageIds;

  const MessagesState({
    this.conversationMessages = const {},
    this.loadingStates = const {},
    this.errorMessages = const {},
    this.pendingMessageIds = const {},
  });

  MessagesState copyWith({
    Map<String, List<Message>>? conversationMessages,
    Map<String, MessageLoadingState>? loadingStates,
    Map<String, String>? errorMessages,
    Set<String>? pendingMessageIds,
  }) {
    return MessagesState(
      conversationMessages: conversationMessages ?? this.conversationMessages,
      loadingStates: loadingStates ?? this.loadingStates,
      errorMessages: errorMessages ?? this.errorMessages,
      pendingMessageIds: pendingMessageIds ?? this.pendingMessageIds,
    );
  }
}

/// Provider for managing messages across conversations
final messagesProvider = StateNotifierProvider<MessagesNotifier, MessagesState>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final chatService = ref.watch(chatServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final logger = Logger('MessagesProvider');
  
  return MessagesNotifier(
    socketService: socketService,
    chatService: chatService,
    authService: authService,
    logger: logger,
  );
});

/// Notifier that manages messages for all conversations
class MessagesNotifier extends StateNotifier<MessagesState> {
  final SocketService _socketService;
  final ChatService _chatService;
  final Logger _logger;
  final dynamic _authService;
  String? _currentUserId;
  
  StreamSubscription? _messageSubscription;
  StreamSubscription? _messageReadSubscription;
  
  MessagesNotifier({
    required SocketService socketService,
    required ChatService chatService,
    required dynamic authService,
    required Logger logger,
  }) : _socketService = socketService,
       _chatService = chatService,
       _authService = authService,
       _logger = logger,
       super(const MessagesState()) {
    _initialize();
  }
  
  /// Initialize the provider
  Future<void> _initialize() async {
    try {
      final user = await _authService.getCurrentUser();
      _currentUserId = user.id;
      _subscribeToSocketEvents();
    } catch (e) {
      _logger.error('Failed to initialize messages provider: $e');
    }
  }
  
  /// Subscribe to socket events for new messages and read receipts
  void _subscribeToSocketEvents() {
    // Subscribe to new messages
    _messageSubscription = _socketService.messages.listen((messageData) {
      try {
        final message = Message.fromJson(messageData);
        _logger.debug('⟹ [MessagesProvider] Received message via socket: ${message.id}');
        _addMessage(message);
      } catch (e) {
        _logger.error('Failed to process socket message: $e');
      }
    });
    
    // Subscribe to message read receipts
    _messageReadSubscription = _socketService.messageRead.listen((data) {
      try {
        final conversationId = data['conversation_id'];
        final messageIds = List<String>.from(data['message_ids'] ?? []);
        
        if (conversationId != null && messageIds.isNotEmpty) {
          _updateMessagesReadStatus(conversationId, messageIds);
        }
      } catch (e) {
        _logger.error('Failed to process read receipt: $e');
      }
    });
  }
  
  /// Load messages for a conversation from the API
  Future<void> loadMessages(String conversationId) async {
    // Update loading state
    state = state.copyWith(
      loadingStates: {...state.loadingStates, conversationId: MessageLoadingState.loading},
      errorMessages: {...state.errorMessages}..remove(conversationId),
    );
    
    try {
      final messages = await _chatService.getMessages(conversationId);
      
      // Update state with fetched messages
      state = state.copyWith(
        conversationMessages: {
          ...state.conversationMessages,
          conversationId: messages,
        },
        loadingStates: {
          ...state.loadingStates,
          conversationId: MessageLoadingState.loaded,
        },
      );
      
      // Join socket room for this conversation
      _socketService.joinConversation(conversationId);
      
      // Mark messages as read
      markMessagesAsRead(conversationId);
    } catch (e) {
      _logger.error('Failed to load messages for conversation $conversationId: $e');
      state = state.copyWith(
        loadingStates: {
          ...state.loadingStates,
          conversationId: MessageLoadingState.error,
        },
        errorMessages: {
          ...state.errorMessages,
          conversationId: 'Failed to load messages. Please try again.',
        },
      );
    }
  }
  
  /// Send a new message
  Future<void> sendMessage(String conversationId, String text) async {
    if (_currentUserId == null) {
      _logger.error('Cannot send message: No current user ID');
      return;
    }
    
    // Create a pending message
    final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
    final pendingMessage = Message(
      id: tempId,
      conversationId: conversationId,
      senderId: _currentUserId!,
      messageText: text,
      timestamp: DateTime.now(),
      status: MessageStatus.pending,
    );
    
    // Add pending message to state
    _addMessage(pendingMessage);
    state = state.copyWith(
      pendingMessageIds: {...state.pendingMessageIds, tempId},
    );
    
    try {
      // Try to send via socket first
      if (_socketService.isConnected) {
        _logger.debug('⟹ [MessagesProvider] Sending message via socket: $text');
        await _socketService.sendMessage(
          conversationId: conversationId,
          message: text,
          tempId: tempId,
        );
        // The socket will return the message with a proper ID, which will update this one
      } else {
        // Fall back to API if socket is disconnected
        _logger.debug('⟹ [MessagesProvider] Socket disconnected, sending message via API: $text');
        final sentMessage = await _chatService.sendMessage(
          conversationId: conversationId,
          message: text,
        );
        
        // Replace the pending message with the sent message
        _replaceMessage(tempId, sentMessage);
      }
    } catch (e) {
      _logger.error('Failed to send message: $e');
      // Update message to failed status
      _updateMessageStatus(tempId, MessageStatus.failed);
    }
  }
  
  /// Retry sending a failed message
  Future<void> retryMessage(String messageId) async {
    final messages = state.conversationMessages.values
        .expand((messages) => messages)
        .toList();
    
    final failedMessage = messages.firstWhere(
      (m) => m.id == messageId && m.status == MessageStatus.failed,
      orElse: () => null as Message, // This will cause an error if message not found, which is handled below
    );
    
    if (failedMessage == null) {
      _logger.error('Cannot retry: Message not found or not in failed state');
      return;
    }
    
    // Update to pending status
    _updateMessageStatus(messageId, MessageStatus.pending);
    
    // Retry sending
    await sendMessage(failedMessage.conversationId, failedMessage.messageText);
    
    // Remove the original failed message
    _removeMessage(messageId);
  }
  
  /// Mark messages in a conversation as read
  Future<void> markMessagesAsRead(String conversationId) async {
    final messages = state.conversationMessages[conversationId] ?? [];
    
    // Find unread messages not from current user
    final unreadMessageIds = messages
        .where((m) => 
            m.senderId != _currentUserId && 
            m.status != MessageStatus.read)
        .map((m) => m.id)
        .toList();
    
    if (unreadMessageIds.isEmpty) return;
    
    try {
      // Update local state first for immediate feedback
      final updatedMessages = messages.map((message) {
        if (unreadMessageIds.contains(message.id)) {
          return message.markAsRead();
        }
        return message;
      }).toList();
      
      state = state.copyWith(
        conversationMessages: {
          ...state.conversationMessages,
          conversationId: updatedMessages,
        },
      );
      
      // Notify server via socket if connected
      if (_socketService.isConnected) {
        _socketService.markMessagesAsRead(conversationId, unreadMessageIds);
      } else {
        // Fall back to API
        await _chatService.markMessageAsRead(conversationId, unreadMessageIds);
      }
    } catch (e) {
      _logger.error('Failed to mark messages as read: $e');
    }
  }
  
  /// Add a new message to a conversation
  void _addMessage(Message message) {
    final conversationId = message.conversationId;
    final currentMessages = List<Message>.from(
        state.conversationMessages[conversationId] ?? []);
    
    // Check if message already exists to avoid duplicates
    if (!currentMessages.any((m) => m.id == message.id)) {
      currentMessages.add(message);
      
      // Sort messages by timestamp
      currentMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      state = state.copyWith(
        conversationMessages: {
          ...state.conversationMessages,
          conversationId: currentMessages,
        },
      );
      
      // Auto-mark messages as read if they are not from current user
      if (message.senderId != _currentUserId) {
        markMessagesAsRead(conversationId);
      }
    }
  }
  
  /// Replace a pending message with the confirmed message
  void _replaceMessage(String tempId, Message confirmedMessage) {
    // Find the conversation that contains this message
    String? targetConversationId;
    for (final entry in state.conversationMessages.entries) {
      if (entry.value.any((m) => m.id == tempId)) {
        targetConversationId = entry.key;
        break;
      }
    }
    
    if (targetConversationId == null) return;
    
    final updatedMessages = state.conversationMessages[targetConversationId]!
        .map((m) => m.id == tempId ? confirmedMessage : m)
        .toList();
    
    state = state.copyWith(
      conversationMessages: {
        ...state.conversationMessages,
        targetConversationId: updatedMessages,
      },
      pendingMessageIds: state.pendingMessageIds..remove(tempId),
    );
  }
  
  /// Update the status of a message
  void _updateMessageStatus(String messageId, MessageStatus status) {
    // Find the conversation that contains this message
    String? targetConversationId;
    for (final entry in state.conversationMessages.entries) {
      if (entry.value.any((m) => m.id == messageId)) {
        targetConversationId = entry.key;
        break;
      }
    }
    
    if (targetConversationId == null) return;
    
    final updatedMessages = state.conversationMessages[targetConversationId]!
        .map((m) => m.id == messageId ? m.copyWith(status: status) : m)
        .toList();
    
    state = state.copyWith(
      conversationMessages: {
        ...state.conversationMessages,
        targetConversationId: updatedMessages,
      },
    );
  }
  
  /// Remove a message from its conversation
  void _removeMessage(String messageId) {
    // Find the conversation that contains this message
    String? targetConversationId;
    for (final entry in state.conversationMessages.entries) {
      if (entry.value.any((m) => m.id == messageId)) {
        targetConversationId = entry.key;
        break;
      }
    }
    
    if (targetConversationId == null) return;
    
    final updatedMessages = state.conversationMessages[targetConversationId]!
        .where((m) => m.id != messageId)
        .toList();
    
    state = state.copyWith(
      conversationMessages: {
        ...state.conversationMessages,
        targetConversationId: updatedMessages,
      },
      pendingMessageIds: state.pendingMessageIds..remove(messageId),
    );
  }
  
  /// Update read status for multiple messages
  void _updateMessagesReadStatus(String conversationId, List<String> messageIds) {
    final messages = state.conversationMessages[conversationId];
    if (messages == null) return;
    
    final updatedMessages = messages.map((message) {
      if (messageIds.contains(message.id)) {
        return message.markAsRead();
      }
      return message;
    }).toList();
    
    state = state.copyWith(
      conversationMessages: {
        ...state.conversationMessages,
        conversationId: updatedMessages,
      },
    );
  }
  
  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageReadSubscription?.cancel();
    super.dispose();
  }
} 