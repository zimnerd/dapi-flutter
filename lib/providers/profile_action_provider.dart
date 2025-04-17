import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';
import '../services/dio_provider.dart';

// Enum for action status
enum ProfileActionStatus { idle, loading, error, success }

// State class for profile actions
class ProfileActionState {
  final ProfileActionStatus status;
  final String? errorMessage;

  ProfileActionState({this.status = ProfileActionStatus.idle, this.errorMessage});

  ProfileActionState copyWith({
    ProfileActionStatus? status,
    String? errorMessage,
  }) {
    return ProfileActionState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// StateNotifier for Profile Actions
class ProfileActionNotifier extends StateNotifier<ProfileActionState> {
  final Ref _ref;

  ProfileActionNotifier(this._ref) : super(ProfileActionState());

  Future<bool> _performAction(Future<bool> Function() action) async {
    state = state.copyWith(status: ProfileActionStatus.loading, errorMessage: null);
    try {
      final result = await action();
      state = state.copyWith(status: ProfileActionStatus.success);
      return result;
    } catch (e) {
      state = state.copyWith(status: ProfileActionStatus.error, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> likeProfile(int profileId) async {
    return _performAction(() async {
      try {
        final dio = _ref.read(dioProvider);
        final response = await dio.post('/profiles/$profileId/like');
        return response.statusCode == 200;
      } catch (e) {
        print('Error liking profile: $e');
        throw Exception('Failed to like profile');
      }
    });
  }

  Future<bool> dislikeProfile(int profileId) async {
    return _performAction(() async {
      try {
        final dio = _ref.read(dioProvider);
        final response = await dio.post('/profiles/$profileId/dislike');
        return response.statusCode == 200;
      } catch (e) {
        print('Error disliking profile: $e');
        throw Exception('Failed to dislike profile');
      }
    });
  }

  Future<bool> superlikeProfile(int profileId) async {
    return _performAction(() async {
      try {
        final dio = _ref.read(dioProvider);
        final response = await dio.post('/profiles/$profileId/superlike');
        return response.statusCode == 200;
      } catch (e) {
        print('Error superliking profile: $e');
        throw Exception('Failed to superlike profile');
      }
    });
  }
}

// Provider for ProfileActionNotifier
final profileActionProvider = StateNotifierProvider<ProfileActionNotifier, ProfileActionState>((ref) {
  return ProfileActionNotifier(ref);
}); 