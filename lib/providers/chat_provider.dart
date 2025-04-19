import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../models/profile.dart'; // For user info if needed later
import '../utils/dummy_data.dart'; // To get initial dummy messages
import 'dart:math'; // For random message generation if needed
import '../services/socket_service.dart';
import '../services/chat_service.dart';
import '../providers/auth_provider.dart';
import '../utils/logger.dart';
import '../utils/connectivity/connectivity_provider.dart';

// State managed by the notifier: a list of messages
typedef MessageListState = List<Message>;

// Notifier class
class ChatMessagesNotifier extends StateNotifier<MessageListState> {
  final String conversationId; // Identify which conversation this notifier manages
  final String currentUserId; // Placeholder - get from auth provider in real app
  final SocketService _socketService;
  final ChatService _chatService;
  final Logger _logger;
  final bool isOnline;
  final OfflineMessageQueueNotifier _offlineQueue;
  final Ref _ref;
  
  StreamSubscription? _messageSubscription;
  StreamSubscription? _networkSubscription;
  Timer? _typingTimer;
  bool _isTyping = false;

  ChatMessagesNotifier({
    required this.conversationId,
    required SocketService socketService,
    required ChatService chatService,
    required this.currentUserId,
    required this.isOnline,
    required OfflineMessageQueueNotifier offlineQueue,
    required Ref ref,
    required Logger logger,
  }) : _socketService = socketService,
       _chatService = chatService,
       _offlineQueue = offlineQueue,
       _ref = ref,
       _logger = logger,
       super([]) {
    _init();
    _monitorNetworkChanges();
  }

  Future<void> _init() async {
    // Join the conversation on socket if online
    if (isOnline && _socketService.isConnected) {
      _socketService.joinConversation(conversationId);
      
      // Subscribe to new messages
      _messageSubscription = _socketService.messageReceived.listen(_handleNewMessage);
    }
    
    // Load message history
    await _loadMessageHistory();
    
    // Process any queued messages if we're back online
    if (isOnline) {
      _processOfflineQueue();
    }
  }

  void _monitorNetworkChanges() {
    // Listen for network status changes
    _networkSubscription = _ref.listen(networkStatusProvider, (previous, next) {
      if (previous == NetworkStatus.offline && next == NetworkStatus.online) {
        _logger.info('Network restored - reconnecting to conversation: $conversationId');
        
        // Rejoin conversation 
        _socketService.joinConversation(conversationId);
        
        // Resubscribe to messages if needed
        if (_messageSubscription == null) {
          _messageSubscription = _socketService.messageReceived.listen(_handleNewMessage);
        }
        
        // Process any queued messages
        _processOfflineQueue();
      }
    });
  }

  void _processOfflineQueue() {
    final queuedMessages = _ref.read(offlineMessageQueueProvider);
    
    for (final message in queuedMessages) {
      // Only process messages for this conversation
      if (message['conversation_id'] == conversationId) {
        _logger.info('Processing queued message: ${message['id']}');
        
        // Send via socket
        _socketService.sendMessage(
          conversationId, 
          message['text'],
          extras: message['extras'],
        );
        
        // Remove from queue
        _offlineQueue.removeFromQueue(message['id']);
      }
    }
  }

  Future<void> _loadMessageHistory() async {
    try {
      _logger.info('Loading message history for conversation: $conversationId');
      
      final messages = await _chatService.getMessages(conversationId);
      
      // Sort messages by timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      state = messages;
      
      // Mark messages as read
      _markMessagesAsRead();
      
    } catch (e) {
      _logger.error('Error loading message history: $e');
      // Don't update state if there's an error, keep existing messages
    }
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    _logger.debug('Received new message: $data');
    
    // Check if message is for this conversation
    if (data['conversation_id'] != conversationId) return;
    
    final message = Message(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: data['conversation_id'],
      senderId: data['sender_id'],
      text: data['message'] ?? '',
      timestamp: data['timestamp'] != null 
        ? DateTime.parse(data['timestamp']) 
        : DateTime.now(),
      status: data['read'] == true 
        ? MessageStatus.read 
        : MessageStatus.delivered,
      reactions: data['reactions'] != null 
        ? List<String>.from(data['reactions']) 
        : [],
    );
    
    // Check if we already have a temporary version of this message
    final tempIndex = state.indexWhere((m) => 
      m.id.startsWith('temp_') && 
      m.text == message.text &&
      (DateTime.now().difference(m.timestamp).inMinutes < 5)
    );
    
    if (tempIndex >= 0) {
      // Replace temp message with real message
      final newList = List<Message>.from(state);
      newList[tempIndex] = message;
      state = newList;
    } else {
      // Add new message to state
      state = [...state, message];
    }
    
    // Mark message as read if it's not from current user
    if (message.senderId != currentUserId) {
      _socketService.markMessageRead(conversationId, message.id);
    }
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    
    _logger.info('Sending message to conversation: $conversationId');
    
    // Generate a unique ID for the message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create a temporary message with sending status
    final tempMessage = Message(
      id: tempId,
      conversationId: conversationId,
      senderId: currentUserId,
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      reactions: [],
    );
    
    // Add temp message to state immediately
    state = [...state, tempMessage];
    
    // Check network status and handle message accordingly
    if (isOnline && _socketService.isConnected) {
      // Send through socket if online
      _socketService.sendMessage(conversationId, text);
    } else {
      // Queue for later if offline
      _logger.info('Device is offline, queueing message for later');
      
      _offlineQueue.addToQueue({
        'id': tempId,
        'conversation_id': conversationId,
        'text': text,
        'sender_id': currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
        'extras': {}
      });
      
      // Update temp message status to reflect waiting
      final updatedState = state.map((message) {
        if (message.id == tempId) {
          return message.copyWith(status: MessageStatus.error);
        }
        return message;
      }).toList();
      
      state = updatedState;
    }
    
    // Stop typing indicator
    stopTyping();
  }

  void handleTyping() {
    if (!_isTyping && isOnline && _socketService.isConnected) {
      _isTyping = true;
      _socketService.sendTypingStart(conversationId);
    }
    
    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), stopTyping);
  }

  void stopTyping() {
    if (_isTyping && isOnline && _socketService.isConnected) {
      _isTyping = false;
      _socketService.sendTypingStop(conversationId);
      _typingTimer?.cancel();
    }
  }

  void _markMessagesAsRead() {
    // Only mark messages as read if we're online
    if (!isOnline || !_socketService.isConnected) return;
    
    // Get unread messages not from current user
    final unreadMessages = state.where(
      (message) => message.senderId != currentUserId && message.status != MessageStatus.read
    ).toList();
    
    // Mark each unread message as read on the server
    for (final message in unreadMessages) {
      _socketService.markMessageRead(conversationId, message.id);
    }
    
    // Update local state
    if (unreadMessages.isNotEmpty) {
      state = state.map((message) {
        if (message.senderId != currentUserId) {
          return message.copyWith(status: MessageStatus.read);
        }
        return message;
      }).toList();
    }
  }

  void resendMessage(String messageId) {
    // Find the message in the state
    final messageIndex = state.indexWhere((m) => m.id == messageId);
    if (messageIndex < 0) return;
    
    final message = state[messageIndex];
    
    // Only resend if it's our message and had an error
    if (message.senderId != currentUserId || message.status != MessageStatus.error) return;
    
    _logger.info('Resending message: $messageId');
    
    // Update status to sending
    final updatedState = List<Message>.from(state);
    updatedState[messageIndex] = message.copyWith(status: MessageStatus.sending);
    state = updatedState;
    
    // Try to send via socket if online
    if (isOnline && _socketService.isConnected) {
      _socketService.sendMessage(conversationId, message.text);
    } else {
      // Make sure it's in the offline queue
      _offlineQueue.addToQueue({
        'id': messageId,
        'conversation_id': conversationId,
        'text': message.text,
        'sender_id': currentUserId,
        'timestamp': message.timestamp.toIso8601String(),
        'extras': {}
      });
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _networkSubscription?.cancel();
    _typingTimer?.cancel();
    
    // Leave conversation if online
    if (isOnline && _socketService.isConnected) {
      _socketService.leaveConversation(conversationId);
    }
    
    super.dispose();
  }
}

// Define the provider that returns a stream of messages
final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier, List<Message>, String>(
  (ref, conversationId) {
    final socketService = ref.watch(socketServiceProvider);
    final chatService = ref.watch(chatServiceProvider);
    final userId = ref.watch(userIdProvider) ?? '';
    final networkStatus = ref.watch(networkStatusProvider);
    final logger = Logger('ChatMessages');
    
    return ChatMessagesNotifier(
      conversationId: conversationId,
      socketService: socketService,
      chatService: chatService,
      currentUserId: userId,
      isOnline: networkStatus == NetworkStatus.online,
      offlineQueue: ref.read(offlineMessageQueueProvider.notifier),
      ref: ref,
      logger: logger,
    );
  },
);

// Track if we are currently sending a message
final messageSendingProvider = StateProvider.family<bool, String>((ref, conversationId) => false);

// Track if we are currently loading message history
final messageHistoryLoadingProvider = StateProvider.family<bool, String>((ref, conversationId) => false); 