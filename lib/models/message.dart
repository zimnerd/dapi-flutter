import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

enum MessageStatus { sent, delivered, read, failed, sending }

@immutable
@JsonSerializable()
class Message {
  final String id;
  final String text;
  final String senderId;
  final String conversationId;
  final DateTime timestamp;
  final MessageStatus status;
  final String? mediaUrl;
  final String? mediaType;
  final Map<String, dynamic>? metadata;
  final List<String>? reactions;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.conversationId,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.mediaUrl,
    this.mediaType,
    this.metadata,
    this.reactions,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);

  Message copyWith({
    String? id,
    String? text,
    String? senderId,
    String? conversationId,
    DateTime? timestamp,
    MessageStatus? status,
    String? mediaUrl,
    String? mediaType,
    Map<String, dynamic>? metadata,
    List<String>? reactions,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      conversationId: conversationId ?? this.conversationId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      metadata: metadata ?? this.metadata,
      reactions: reactions ?? this.reactions,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text &&
          senderId == other.senderId &&
          conversationId == other.conversationId &&
          timestamp == other.timestamp &&
          status == other.status &&
          mediaUrl == other.mediaUrl &&
          mediaType == other.mediaType &&
          metadata == other.metadata &&
          listEquals(reactions, other.reactions) &&
          isRead == other.isRead &&
          readAt == other.readAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        text,
        senderId,
        conversationId,
        timestamp,
        status,
        mediaUrl,
        mediaType,
        metadata != null ? Object.hashAll(metadata!.values) : 0,
        reactions != null ? Object.hashAll(reactions!) : 0,
        isRead,
        readAt?.hashCode ?? 0,
        createdAt.hashCode,
        updatedAt.hashCode,
      );

  /// Returns true if this message was sent by the given user ID
  bool isFromCurrentUserId(String currentUserId) => senderId == currentUserId;

  /// Deprecated: Use isFromCurrentUserId(currentUserId) instead
  @Deprecated('Use isFromCurrentUserId(currentUserId) instead')
  bool get isFromCurrentUser => throw UnimplementedError(
      'Use isFromCurrentUserId(currentUserId) instead');
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
