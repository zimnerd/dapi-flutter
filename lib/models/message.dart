import 'package:flutter/foundation.dart';

@immutable
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final String? mediaUrl;
  final Map<String, dynamic>? metadata;
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
    this.mediaUrl,
    this.metadata,
    this.reactions,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? text,
    DateTime? timestamp,
    MessageStatus? status,
    String? mediaUrl,
    Map<String, dynamic>? metadata,
    List<String>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      metadata: metadata ?? this.metadata,
      reactions: reactions ?? this.reactions,
    );
  }

  factory Message.fromJson(String msgId, Map<String, dynamic> json) {
    try {
      // Parse timestamp from string, with fallback
      DateTime parsedTimestamp;
      try {
        final timestamp = json['timestamp'] ??
            json['created_at'] ??
            DateTime.now().toIso8601String();
        parsedTimestamp =
            timestamp is String ? DateTime.parse(timestamp) : DateTime.now();
      } catch (e) {
        // If timestamp parsing fails, use current time
        print('Error parsing timestamp: $e, using current time instead');
        parsedTimestamp = DateTime.now();
      }

      // Parse status with fallback
      MessageStatus parsedStatus;
      try {
        final statusStr = json['status'] as String? ?? 'sent';
        parsedStatus = MessageStatus.values.firstWhere(
          (s) => s.toString() == 'MessageStatus.$statusStr',
          orElse: () => MessageStatus.sent,
        );
      } catch (e) {
        print('Error parsing message status: $e, using "sent" instead');
        parsedStatus = MessageStatus.sent;
      }

      // Extract the conversation ID with fallbacks
      String conversationId = '';
      if (json.containsKey('conversationId')) {
        conversationId = json['conversationId'] as String? ?? '';
      } else if (json.containsKey('conversation_id')) {
        conversationId = json['conversation_id'] as String? ?? '';
      } else if (json.containsKey('matchId')) {
        conversationId = json['matchId'] as String? ?? '';
      } else if (json.containsKey('match_id')) {
        conversationId = json['match_id'] as String? ?? '';
      }

      // Extract text content with fallbacks
      String text = '';
      if (json.containsKey('text')) {
        text = json['text'] as String? ?? '';
      } else if (json.containsKey('content')) {
        text = json['content'] as String? ?? '';
      } else if (json.containsKey('message')) {
        text = json['message'] as String? ?? '';
      }

      // Extract sender ID with fallbacks
      String senderId = '';
      if (json.containsKey('senderId')) {
        senderId = json['senderId'] as String? ?? '';
      } else if (json.containsKey('sender_id')) {
        senderId = json['sender_id'] as String? ?? '';
      } else if (json.containsKey('userId')) {
        senderId = json['userId'] as String? ?? '';
      } else if (json.containsKey('user_id')) {
        senderId = json['user_id'] as String? ?? '';
      }

      // Create and return the Message object
      return Message(
        id: msgId,
        conversationId: conversationId,
        senderId: senderId,
        text: text,
        timestamp: parsedTimestamp,
        status: parsedStatus,
        mediaUrl: json['mediaUrl'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
        reactions: (json['reactions'] as List<dynamic>? ?? []).cast<String>(),
      );
    } catch (e) {
      // Log the error and return a placeholder message
      print('Error creating Message from JSON: $e');
      print('Problematic JSON: $json');

      return Message(
        id: msgId,
        conversationId: 'error',
        senderId: 'error',
        text: 'Error loading message',
        timestamp: DateTime.now(),
        status: MessageStatus.failed,
        mediaUrl: null,
        metadata: null,
        reactions: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'mediaUrl': mediaUrl,
      'metadata': metadata,
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
      mediaUrl: null,
      metadata: null,
      reactions: null,
    );
  }

  Message markAsRead() {
    return copyWith(status: MessageStatus.read);
  }

  @override
  String toString() {
    return 'Message(id: $id, conversationId: $conversationId, senderId: $senderId, text: $text, timestamp: $timestamp, status: $status, mediaUrl: $mediaUrl, metadata: $metadata, reactions: $reactions)';
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
          mediaUrl == other.mediaUrl &&
          metadata == other.metadata &&
          listEquals(reactions, other.reactions);

  @override
  int get hashCode => Object.hash(
        id,
        conversationId,
        senderId,
        text,
        timestamp,
        status,
        mediaUrl,
        metadata != null ? Object.hashAll(metadata!.values) : 0,
        reactions != null ? Object.hashAll(reactions!) : 0,
      );
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
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
      case 'failed':
        return MessageStatus.failed;
      case 'sent':
      default:
        return MessageStatus.sent;
    }
  }
}
