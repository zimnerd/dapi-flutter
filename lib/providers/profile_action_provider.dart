import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';
import '../utils/logger.dart';
import 'providers.dart' show profileServiceProvider;

// Create logger instance
final logger = Logger('ProfileAction');

enum ProfileAction {
  like,
  dislike,
  superlike,
}

class ProfileActionState {
  final bool isProcessing;
  final String? error;
  final Map<String, ProfileAction> recentActions;

  const ProfileActionState({
    this.isProcessing = false,
    this.error,
    this.recentActions = const {},
  });

  String? get errorMessage => error;

  ProfileActionState copyWith({
    bool? isProcessing,
    String? error,
    Map<String, ProfileAction>? recentActions,
  }) {
    return ProfileActionState(
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      recentActions: recentActions ?? this.recentActions,
    );
  }
}

class ProfileActionNotifier extends StateNotifier<ProfileActionState> {
  final ProfileService _profileService;

  ProfileActionNotifier(this._profileService) : super(const ProfileActionState());

  Future<bool> likeProfile(String profileId) async {
    if (state.isProcessing) return false;
    
    state = state.copyWith(isProcessing: true, error: null);
    
    try {
      await _profileService.likeProfile(profileId);
      final updatedActions = Map<String, ProfileAction>.from(state.recentActions)
        ..['$profileId'] = ProfileAction.like;
      
      state = state.copyWith(
        isProcessing: false,
        recentActions: updatedActions,
      );
      
      logger.info('Successfully liked profile: $profileId');
      return true;
    } catch (e) {
      logger.error('Error liking profile: $e');
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to like profile',
      );
      return false;
    }
  }

  Future<bool> dislikeProfile(String profileId) async {
    if (state.isProcessing) return false;
    
    state = state.copyWith(isProcessing: true, error: null);
    
    try {
      await _profileService.dislikeProfile(profileId);
      final updatedActions = Map<String, ProfileAction>.from(state.recentActions)
        ..['$profileId'] = ProfileAction.dislike;
      
      state = state.copyWith(
        isProcessing: false,
        recentActions: updatedActions,
      );
      
      logger.info('Successfully disliked profile: $profileId');
      return true;
    } catch (e) {
      logger.error('Error disliking profile: $e');
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to dislike profile',
      );
      return false;
    }
  }

  Future<bool> superlikeProfile(String profileId) async {
    if (state.isProcessing) return false;
    
    state = state.copyWith(isProcessing: true, error: null);
    
    try {
      await _profileService.superlikeProfile(profileId);
      final updatedActions = Map<String, ProfileAction>.from(state.recentActions)
        ..['$profileId'] = ProfileAction.superlike;
      
      state = state.copyWith(
        isProcessing: false,
        recentActions: updatedActions,
      );
      
      logger.info('Successfully superliked profile: $profileId');
      return true;
    } catch (e) {
      logger.error('Error superliking profile: $e');
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to superlike profile',
      );
      return false;
    }
  }

  bool hasActedOnProfile(String profileId) {
    return state.recentActions.containsKey(profileId);
  }

  ProfileAction? getProfileAction(String profileId) {
    return state.recentActions['$profileId'];
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final profileActionProvider = StateNotifierProvider<ProfileActionNotifier, ProfileActionState>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  return ProfileActionNotifier(profileService);
}); 