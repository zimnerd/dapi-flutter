import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../models/profile.dart'; // For user info if needed later
import '../utils/dummy_data.dart'; // To get initial dummy messages
import 'dart:math'; // For random message generation if needed

// State managed by the notifier: a list of messages
typedef MessageListState = List<Message>;

// Notifier class
class ChatMessagesNotifier extends StateNotifier<MessageListState> {
  final String conversationId; // Identify which conversation this notifier manages
  final String currentUserId = 'currentUserId'; // Placeholder - get from auth provider in real app

  ChatMessagesNotifier(this.conversationId) : super([]) {
    _loadInitialMessages();
  }

  // Load initial dummy messages (replace with API call later)
  void _loadInitialMessages() {
    // Use existing dummy data function
    state = DummyData.getMessages(conversationId);
    // Ensure messages are sorted by timestamp initially
    state.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // Add a new message (sent by the current user)
  void addMessage(String text) {
    if (text.trim().isEmpty) return;

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      senderId: currentUserId,
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sent, // Assume sent immediately in dummy mode
      reactions: [],
    );

    state = [...state, newMessage];
    // TODO: Simulate receiving a reply after a delay?
  }

  // Toggle a reaction on a specific message
  void toggleReaction(String messageId, String emoji) {
    state = state.map((message) {
      if (message.id == messageId) {
        final currentReactions = List<String>.from(message.reactions ?? []);
        if (currentReactions.contains(emoji)) {
          currentReactions.remove(emoji);
        } else {
          // Optional: Limit number of reactions or unique reactions per user later
          currentReactions.add(emoji);
        }
        return message.copyWith(reactions: currentReactions);
      } else {
        return message;
      }
    }).toList();
  }

  // Simulate marking messages as read (optional, for dummy testing)
  void markMessagesAsRead() {
     state = state.map((message) {
       if (!message.isFromCurrentUser && message.status != MessageStatus.read) {
          return message.copyWith(status: MessageStatus.read);
       }
       return message;
     }).toList();
  }
}

// Define the provider that returns a stream of messages
final chatMessagesProvider = StreamProvider.autoDispose.family<List<Message>, String>((ref, conversationId) {
  print("Creating dummy message stream for $conversationId");
  // In a real app, this would connect to a real-time service like Firebase
  // For now, just return the dummy messages once
  return Stream.value(DummyData.getMessages(conversationId));
}); 