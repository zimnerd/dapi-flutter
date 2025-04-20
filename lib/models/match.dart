import 'package:flutter/foundation.dart';
import 'profile.dart';

/// Represents a match between two users in the dating app
class Match {
  final String id;
  final Profile matchedUser;
  final DateTime matchedAt;
  final bool isNew;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  Match({
    required this.id,
    required this.matchedUser,
    required this.matchedAt,
    this.isNew = false,
    this.lastMessage,
    this.lastMessageAt,
  });

  /// Create a Match from JSON data
  factory Match.fromJson(Map<String, dynamic> json) {
    // Convert the profile data directly into a Profile object
    final profile = Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      photoUrls: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      interests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      location: json['location'],
      profilePictures: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      isPremium: false, // Default value since not in API response
      lastActive: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );

    return Match(
      id: json['id'] as String,
      matchedUser: profile,
      matchedAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isNew: json['isNew'] as bool? ?? false,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
    );
  }

  /// Convert Match to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchedUser': matchedUser.toJson(),
      'matchedAt': matchedAt.toIso8601String(),
      'isNew': isNew,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
    };
  }

  /// Create a copy of Match with some fields changed
  Match copyWith({
    String? id,
    Profile? matchedUser,
    DateTime? matchedAt,
    bool? isNew,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) {
    return Match(
      id: id ?? this.id,
      matchedUser: matchedUser ?? this.matchedUser,
      matchedAt: matchedAt ?? this.matchedAt,
      isNew: isNew ?? this.isNew,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Match &&
        other.id == id &&
        other.lastMessage == lastMessage &&
        other.lastMessageAt == lastMessageAt;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Match(id: $id, matchedUser: ${matchedUser.name}, matchedAt: $matchedAt, isNew: $isNew, lastMessage: $lastMessage)';
  }
}
