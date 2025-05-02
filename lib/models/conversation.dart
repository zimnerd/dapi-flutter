import 'package:json_annotation/json_annotation.dart';
import 'message.dart';
import '../models/user.dart';

part 'conversation.g.dart';

@JsonSerializable()
class Conversation {
  final String id;
  final List<User> participants;
  final Message? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isMatched;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
    this.isMatched = true,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  // Get other participant (not the current user)
  User? getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (user) => user.id != currentUserId,
      orElse: () => participants.first,
    );
  }

  bool hasUnreadMessages(String currentUserId) {
    return lastMessage != null &&
        !lastMessage!.isRead &&
        lastMessage!.senderId != currentUserId;
  }

  // Create a copy with updated properties
  Conversation copyWith({
    String? id,
    List<User>? participants,
    Message? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unreadCount,
    bool? isMatched,
  }) {
    return Conversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isMatched: isMatched ?? this.isMatched,
    );
  }

  // Reset unread count
  Conversation markAsRead() {
    return copyWith(unreadCount: 0);
  }

  // Add a message and update lastMessage
  Conversation addMessage(Message message) {
    return copyWith(
      lastMessage: message,
      updatedAt: DateTime.now(),
      unreadCount: 0, // Mark as read when we add our own message
    );
  }

  @override
  String toString() {
    return 'Conversation(id: $id, participants: ${participants.length}, '
        'lastMessage: ${lastMessage?.text ?? 'none'}, '
        'unreadCount: $unreadCount)';
  }
}
