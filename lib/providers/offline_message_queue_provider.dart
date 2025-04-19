import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../providers/network_status_provider.dart';
import '../providers/providers.dart';
import '../services/socket_service.dart';
import '../utils/logger.dart';

/// Message queue state
class OfflineMessageQueueState {
  final List<Map<String, dynamic>> pendingMessages;
  final bool isSyncing;

  const OfflineMessageQueueState({
    this.pendingMessages = const [],
    this.isSyncing = false,
  });

  OfflineMessageQueueState copyWith({
    List<Map<String, dynamic>>? pendingMessages,
    bool? isSyncing,
  }) {
    return OfflineMessageQueueState(
      pendingMessages: pendingMessages ?? this.pendingMessages,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

/// Provider for managing offline message queue
final offlineMessageQueueProvider = StateNotifierProvider<OfflineMessageQueueNotifier, OfflineMessageQueueState>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  final networkStatus = ref.watch(networkStatusProvider);
  final logger = Logger('OfflineMessageQueue');
  
  return OfflineMessageQueueNotifier(
    socketService: socketService,
    sharedPreferences: sharedPrefs,
    isOnline: networkStatus == NetworkStatus.online,
    logger: logger,
    ref: ref,
  );
});

/// Notifier that manages the offline message queue
class OfflineMessageQueueNotifier extends StateNotifier<OfflineMessageQueueState> {
  final SocketService _socketService;
  final SharedPreferences _sharedPreferences;
  final Logger _logger;
  final Ref _ref;
  
  static const String _storageKey = 'offline_message_queue';
  Timer? _syncTimer;
  bool _isOnline;
  
  OfflineMessageQueueNotifier({
    required SocketService socketService,
    required SharedPreferences sharedPreferences,
    required bool isOnline,
    required Logger logger,
    required Ref ref,
  }) : _socketService = socketService,
       _sharedPreferences = sharedPreferences,
       _isOnline = isOnline,
       _logger = logger,
       _ref = ref,
       super(const OfflineMessageQueueState()) {
    _loadQueueFromStorage();
    _setupNetworkListener();
  }
  
  /// Load queued messages from persistent storage
  Future<void> _loadQueueFromStorage() async {
    try {
      final queueJson = _sharedPreferences.getString(_storageKey);
      if (queueJson != null) {
        final List<dynamic> decoded = jsonDecode(queueJson);
        final pendingMessages = decoded.cast<Map<String, dynamic>>();
        
        state = state.copyWith(pendingMessages: pendingMessages);
        _logger.debug('⟹ [OfflineMessageQueue] Loaded ${pendingMessages.length} queued messages from storage');
        
        // Try to sync messages if we're online
        if (_isOnline) {
          _syncQueuedMessages();
        }
      }
    } catch (e) {
      _logger.error('Failed to load offline message queue: $e');
    }
  }
  
  /// Save queue to persistent storage
  Future<void> _saveQueueToStorage() async {
    try {
      await _sharedPreferences.setString(
        _storageKey, 
        jsonEncode(state.pendingMessages),
      );
    } catch (e) {
      _logger.error('Failed to save offline message queue: $e');
    }
  }
  
  /// Listen for network status changes
  void _setupNetworkListener() {
    _ref.listen<NetworkStatus>(
      networkStatusProvider,
      (previous, current) {
        final wasOffline = previous == NetworkStatus.offline;
        final isNowOnline = current == NetworkStatus.online;
        
        _isOnline = isNowOnline;
        
        // If we just came back online, try to sync messages
        if (wasOffline && isNowOnline) {
          _syncQueuedMessages();
        }
      },
    );
  }
  
  /// Add a Message object to the queue to be sent when back online
  Future<void> addMessage(Message message) async {
    final messageData = {
      'id': message.id,
      'conversation_id': message.conversationId,
      'message': message.messageText,
      'sender_id': message.senderId,
      'sender_name': message.senderName,
      'timestamp': message.timestamp.toIso8601String(),
    };
    
    // Add to queue
    final updatedQueue = [...state.pendingMessages, messageData];
    state = state.copyWith(pendingMessages: updatedQueue);
    
    // Save to storage
    await _saveQueueToStorage();
    
    _logger.debug('⟹ [OfflineMessageQueue] Message queued for conversation ${message.conversationId}');
    
    // Try to sync immediately if online
    if (_isOnline) {
      _syncQueuedMessages();
    }
  }
  
  /// Get messages for a specific conversation
  List<Message> getMessagesForConversation(String conversationId) {
    return state.pendingMessages
        .where((m) => m['conversation_id'] == conversationId)
        .map((m) => Message(
              id: m['id'] ?? '',
              conversationId: m['conversation_id'] ?? '',
              senderId: m['sender_id'] ?? '',
              messageText: m['message'] ?? '',
              timestamp: DateTime.parse(m['timestamp'] ?? DateTime.now().toIso8601String()),
              senderName: m['sender_name'] ?? '',
              status: MessageStatus.pending,
            ))
        .toList();
  }
  
  /// Remove a message from the queue
  Future<void> removeMessage(String messageId) async {
    final updatedQueue = state.pendingMessages
        .where((m) => m['id'] != messageId)
        .toList();
    
    state = state.copyWith(pendingMessages: updatedQueue);
    await _saveQueueToStorage();
  }
  
  /// Try to send all queued messages
  Future<void> _syncQueuedMessages() async {
    // If already syncing or no messages to sync, exit
    if (state.isSyncing || state.pendingMessages.isEmpty) return;
    
    // If socket is not connected, wait for it
    if (!_socketService.isConnected) {
      _logger.debug('⟹ [OfflineMessageQueue] Socket not connected, will try sync later');
      return;
    }
    
    _logger.debug('⟹ [OfflineMessageQueue] Syncing ${state.pendingMessages.length} offline messages');
    
    // Mark as syncing
    state = state.copyWith(isSyncing: true);
    
    try {
      // Make a copy to avoid modifying during iteration
      final messagesToSync = List<Map<String, dynamic>>.from(state.pendingMessages);
      final successfulIds = <String>[];
      
      // Send each message
      for (final messageData in messagesToSync) {
        try {
          final conversationId = messageData['conversation_id'] as String;
          final text = messageData['message'] as String;
          final id = messageData['id'] as String;
          final senderId = messageData['sender_id'] as String? ?? '';
          
          await _socketService.sendMessageWithParams(
            conversationId: conversationId,
            content: text,
            senderId: senderId,
          );
          
          successfulIds.add(id);
          _logger.debug('⟹ [OfflineMessageQueue] Successfully sent queued message $id');
        } catch (e) {
          _logger.error('Failed to send queued message: $e');
          // Continue with next message
        }
      }
      
      // Remove successful messages from queue
      if (successfulIds.isNotEmpty) {
        final remainingMessages = state.pendingMessages
            .where((m) => !successfulIds.contains(m['id']))
            .toList();
        
        state = state.copyWith(
          pendingMessages: remainingMessages,
          isSyncing: false,
        );
        
        // Save updated queue
        await _saveQueueToStorage();
      } else {
        state = state.copyWith(isSyncing: false);
      }
    } catch (e) {
      _logger.error('Error during queue sync: $e');
      state = state.copyWith(isSyncing: false);
    }
  }
  
  /// Try to sync queued messages now (can be called manually)
  Future<void> syncNow() async {
    if (_isOnline) {
      await _syncQueuedMessages();
    }
  }
  
  /// Get queue length
  int get queueLength => state.pendingMessages.length;
  
  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
} 