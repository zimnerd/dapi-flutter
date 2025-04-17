import 'dart:convert';
import 'message.dart';
import 'profile.dart';
import 'package:flutter/material.dart';
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
    return Conversation(
      id: json['id'] as String,
      participants: (json['participants'] as List)
          .map((p) => User.fromJson(p as Map<String, dynamic>))
          .toList(),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(
              (json['lastMessage'] as Map<String, dynamic>)['id'] as String? ?? 'unknown', 
              json['lastMessage'] as Map<String, dynamic>
            )
          : null,
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