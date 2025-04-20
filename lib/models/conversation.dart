import 'message.dart';
import '../models/user.dart';

class Conversation {
  final String id;
  final List<User> participants;
  final Message? lastMessage;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int unreadCount;
  final bool isMatched;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.createdAt,
    this.updatedAt,
    this.unreadCount = 0,
    this.isMatched = true,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // Handle participants that might be strings (user IDs) or maps
    List<User> parseParticipants(dynamic participantsData) {
      if (participantsData is List) {
        return participantsData.map((p) {
          if (p is Map<String, dynamic>) {
            return User.fromJson(p);
          } else if (p is String) {
            // If participant is a string (user ID), create a minimal User object
            return User(
              id: p,
              email: '$p@unknown.com', // Placeholder email
              name: 'Unknown User',
              profilePictures: null,
            );
          } else {
            throw FormatException('Invalid participant data format: $p');
          }
        }).toList();
      }
      return [];
    }

    // Handle lastMessage that might be a string or a map
    Message? parseLastMessage(dynamic messageData) {
      if (messageData == null) return null;

      if (messageData is Map<String, dynamic>) {
        return Message.fromJson(
          messageData['id'] as String? ?? 'unknown',
          messageData,
        );
      } else if (messageData is String) {
        // If message is a string, create a simple Message object
        return Message.fromJson(
          'unknown',
          {
            'text': messageData,
            'timestamp': DateTime.now().toIso8601String(),
            'senderId': '',
            'status': 'sent',
          },
        );
      }
      return null;
    }

    return Conversation(
      id: json['id'] as String,
      participants: parseParticipants(json['participants']),
      lastMessage: parseLastMessage(json['lastMessage']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isMatched: json['isMatched'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants.map((p) => p.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'unreadCount': unreadCount,
      'isMatched': isMatched,
    };
  }

  // Get other participant (not the current user)
  User getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (user) => user.id != currentUserId,
      orElse: () => participants.first,
    );
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
