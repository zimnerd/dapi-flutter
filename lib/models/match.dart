import 'profile.dart';

/// Represents a match between two users in the dating app
class Match {
  final String id;
  final Profile matchedProfile;
  final DateTime matchedAt;
  final bool isRead;
  final bool isSupermatch;

  Match({
    required this.id,
    required this.matchedProfile,
    required this.matchedAt,
    this.isRead = false,
    this.isSupermatch = false,
  });

  /// Create a Match from JSON data
  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      matchedProfile: Profile.fromJson(json['matchedProfile']),
      matchedAt: DateTime.parse(json['matchedAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      isSupermatch: json['isSupermatch'] as bool? ?? false,
    );
  }

  /// Convert Match to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchedProfile': matchedProfile.toJson(),
      'matchedAt': matchedAt.toIso8601String(),
      'isRead': isRead,
      'isSupermatch': isSupermatch,
    };
  }

  /// Create a copy of Match with some fields changed
  Match copyWith({
    String? id,
    Profile? matchedProfile,
    DateTime? matchedAt,
    bool? isRead,
    bool? isSupermatch,
  }) {
    return Match(
      id: id ?? this.id,
      matchedProfile: matchedProfile ?? this.matchedProfile,
      matchedAt: matchedAt ?? this.matchedAt,
      isRead: isRead ?? this.isRead,
      isSupermatch: isSupermatch ?? this.isSupermatch,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Match &&
        other.id == id &&
        other.matchedProfile == matchedProfile &&
        other.matchedAt == matchedAt &&
        other.isRead == isRead &&
        other.isSupermatch == isSupermatch;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        matchedProfile.hashCode ^
        matchedAt.hashCode ^
        isRead.hashCode ^
        isSupermatch.hashCode;
  }

  @override
  String toString() {
    return 'Match(id: $id, matchedProfile: ${matchedProfile.name}, matchedAt: $matchedAt, isRead: $isRead, isSupermatch: $isSupermatch)';
  }
}
