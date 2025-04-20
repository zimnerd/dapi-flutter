import 'package:flutter/foundation.dart';

@immutable
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final List<String>? reactions;
  bool get isFromCurrentUser =>
      senderId ==
      'currentUserId'; // In real app, replace with actual currentUser check

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.status,
    this.reactions,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? text,
    DateTime? timestamp,
    MessageStatus? status,
    List<String>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      reactions: reactions ?? this.reactions,
    );
  }

  factory Message.fromJson(String id, Map<String, dynamic> json) {
    return Message(
      id: id,
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => MessageStatus.sent,
      ),
      reactions: (json['reactions'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'reactions': reactions,
    };
  }

  // Helper factory for creating pending messages
  factory Message.pending({
    required String text,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: '',
      senderId: 'currentUserId', // In real app, get from auth service
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      reactions: null,
    );
  }

  Message markAsRead() {
    return copyWith(status: MessageStatus.read);
  }

  @override
  String toString() {
    return 'Message(id: $id, conversationId: $conversationId, senderId: $senderId, text: $text, timestamp: $timestamp, status: $status, reactions: $reactions)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          conversationId == other.conversationId &&
          senderId == other.senderId &&
          text == other.text &&
          timestamp == other.timestamp &&
          status == other.status &&
          listEquals(reactions, other.reactions);

  @override
  int get hashCode => Object.hash(
        id,
        conversationId,
        senderId,
        text,
        timestamp,
        status,
        Object.hashAll(reactions ?? []),
      );
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  error,
}

extension MessageStatusExtension on MessageStatus {
  static MessageStatus fromString(String status) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'error':
        return MessageStatus.error;
      case 'sent':
      default:
        return MessageStatus.sent;
    }
  }
}
