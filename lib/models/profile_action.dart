import '../models/profile.dart';

/// Enum to represent the different swipe directions
enum SwipeDirection {
  like,
  dislike,
  superLike,
}

/// Class to store information about the last swipe action
class LastSwipeInfo {
  final Profile profile;
  final SwipeDirection direction;

  const LastSwipeInfo({required this.profile, required this.direction});
}

/// Class to store profile action data from the API
class ProfileAction {
  final String id;
  final String profileId;
  final String actionType; // 'like', 'dislike', 'superlike'
  final DateTime timestamp;

  ProfileAction({
    required this.id,
    required this.profileId,
    required this.actionType,
    required this.timestamp,
  });

  factory ProfileAction.fromJson(Map<String, dynamic> json) {
    return ProfileAction(
      id: json['id'] ?? '',
      profileId: json['profile_id'] ?? '',
      actionType: json['action_type'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'action_type': actionType,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Convert a SwipeDirection to the corresponding action type string
  static String directionToActionType(SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.like:
        return 'like';
      case SwipeDirection.dislike:
        return 'dislike';
      case SwipeDirection.superLike:
        return 'superlike';
    }
  }

  /// Convert an action type string to the corresponding SwipeDirection
  static SwipeDirection? actionTypeToDirection(String actionType) {
    switch (actionType) {
      case 'like':
        return SwipeDirection.like;
      case 'dislike':
        return SwipeDirection.dislike;
      case 'superlike':
        return SwipeDirection.superLike;
      default:
        return null;
    }
  }
}
