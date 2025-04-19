import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../utils/logger.dart';
import 'providers.dart';

/// Provider for the offline message queue
final offlineMessageQueueProvider = StateNotifierProvider<OfflineMessageQueueNotifier, List<Message>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OfflineMessageQueueNotifier(prefs);
});

/// Manages messages that are sent while the user is offline
class OfflineMessageQueueNotifier extends StateNotifier<List<Message>> {
  final SharedPreferences _prefs;
  final Logger _logger = Logger('OfflineMessageQueue');
  static const String _queueKey = 'offline_message_queue';

  OfflineMessageQueueNotifier(this._prefs) : super([]) {
    _loadQueue();
  }

  /// Load any queued messages from persistent storage
  void _loadQueue() {
    try {
      final queueJson = _prefs.getString(_queueKey);
      if (queueJson != null) {
        final List<dynamic> decodedList = jsonDecode(queueJson);
        state = decodedList.map((item) => Message.fromJson(item)).toList();
        _logger.info('Loaded ${state.length} messages from offline queue');
      }
    } catch (e) {
      _logger.error('Error loading offline message queue: $e');
      // Reset the queue if there's an error loading it
      _prefs.remove(_queueKey);
      state = [];
    }
  }

  /// Save the current queue to persistent storage
  void _saveQueue() {
    try {
      final queueJson = jsonEncode(state.map((message) => message.toJson()).toList());
      _prefs.setString(_queueKey, queueJson);
    } catch (e) {
      _logger.error('Error saving offline message queue: $e');
    }
  }

  /// Add a message to the offline queue
  void addMessage(Message message) {
    _logger.info('Adding message to offline queue: ${message.id}');
    state = [...state, message];
    _saveQueue();
  }

  /// Remove a message from the offline queue
  void removeMessage(String messageId) {
    _logger.info('Removing message from offline queue: $messageId');
    state = state.where((message) => message.id != messageId).toList();
    _saveQueue();
  }

  /// Get all queued messages for a specific conversation
  List<Message> getMessagesForConversation(String conversationId) {
    return state.where((message) => message.conversationId == conversationId).toList();
  }

  /// Get all queued messages
  List<Message> getAllMessages() {
    return state;
  }

  /// Clear all messages from the queue
  void clearQueue() {
    _logger.info('Clearing offline message queue');
    state = [];
    _prefs.remove(_queueKey);
  }
} 