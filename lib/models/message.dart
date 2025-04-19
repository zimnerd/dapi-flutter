import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

@immutable
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String messageText;
  final DateTime timestamp;
  final MessageStatus status;
  final Map<String, String>? reactions;
  bool get isFromCurrentUser => senderId == 'currentUserId'; // In real app, replace with actual currentUser check

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageText,
    required this.timestamp,
    this.senderName = '',
    this.status = MessageStatus.sent,
    this.reactions,
  });

  String get content => messageText;
  
  // Added for backward compatibility with code using message.text
  String get text => messageText;

  String get formattedTime {
    return DateFormat('h:mm a').format(timestamp);
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
        timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? messageText,
    DateTime? timestamp,
    MessageStatus? status,
    Map<String, String>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      messageText: messageText ?? this.messageText,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      reactions: reactions ?? this.reactions,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    final String id = json['id'] ?? json['_id'] ?? json['messageId'] ?? '';
    final String conversationId = json['conversationId'] ?? 
                                  json['conversation_id'] ?? '';
    final String senderId = json['senderId'] ?? 
                            json['sender_id'] ?? 
                            json['userId'] ?? '';
    final String senderName = json['senderName'] ?? 
                              json['sender_name'] ?? 
                              json['userName'] ?? '';
    
    final String content = json['content'] ?? 
                           json['message'] ?? 
                           json['text'] ?? 
                           json['messageText'] ?? '';
    
    DateTime timestamp;
    try {
      if (json['timestamp'] is String) {
        timestamp = DateTime.parse(json['timestamp']);
      } else if (json['timestamp'] is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp']);
      } else if (json['created_at'] is String) {
        timestamp = DateTime.parse(json['created_at']);
      } else if (json['createdAt'] is String) {
        timestamp = DateTime.parse(json['createdAt']);
      } else {
        timestamp = DateTime.now();
      }
    } catch (e) {
      timestamp = DateTime.now();
    }
    
    MessageStatus status;
    if (json['status'] == 'pending') {
      status = MessageStatus.pending;
    } else if (json['status'] == 'sent') {
      status = MessageStatus.sent;
    } else if (json['status'] == 'delivered') {
      status = MessageStatus.delivered;
    } else if (json['status'] == 'read') {
      status = MessageStatus.read;
    } else if (json['status'] == 'failed') {
      status = MessageStatus.failed;
    } else {
      status = MessageStatus.sent;
    }
    
    Map<String, String>? reactions;
    if (json['reactions'] != null) {
      reactions = Map<String, String>.from(json['reactions']);
    }
    
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      messageText: content,
      timestamp: timestamp,
      status: status,
      reactions: reactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId, 
      'senderName': senderName,
      'content': messageText,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'reactions': reactions,
    };
  }

  Message markAsRead() {
    return copyWith(status: MessageStatus.read);
  }

  @override
  String toString() {
    return 'Message(id: $id, conversationId: $conversationId, senderId: $senderId, text: $messageText, timestamp: $timestamp, status: $status, reactions: $reactions)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          conversationId == other.conversationId &&
          senderId == other.senderId &&
          messageText == other.messageText &&
          timestamp == other.timestamp &&
          status == other.status &&
          mapEquals(reactions, other.reactions);

  @override
  int get hashCode => Object.hash(
        id,
        conversationId,
        senderId,
        messageText,
        timestamp,
        status,
        Object.hashAll(reactions?.values.toList() ?? []),
      );
}

enum MessageStatus {
  pending,
  sent,
  delivered,
  read,
  failed
}

extension MessageStatusExtension on MessageStatus {
  static MessageStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return MessageStatus.pending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }
} 