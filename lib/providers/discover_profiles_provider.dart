import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';
import '../utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:shared_preferences/shared_preferences.dart';
import 'providers.dart';

// Remove redundant providers since they're already defined in providers.dart
// final profileServiceProvider = Provider<ProfileService>((ref) {
//   final dio = ref.watch(dioProvider);
//   return ProfileService(dio);
// });

// final dioProvider = Provider<Dio>((ref) {
//   return Dio();
// });

@immutable
class DiscoverProfilesState {
  final AsyncValue<List<Profile>> profiles;

  const DiscoverProfilesState({
    required this.profiles,
  });

  DiscoverProfilesState copyWith({
    AsyncValue<List<Profile>>? profiles,
  }) {
    return DiscoverProfilesState(
      profiles: profiles ?? this.profiles,
    );
  }
}

// Add SwipeDirection enum at the top of the file
enum SwipeDirection { like, dislike, superLike }

// StateNotifier for managing discover profiles
class DiscoverProfilesNotifier extends StateNotifier<DiscoverProfilesState> {
  final ProfileService _profileService;
  final Ref _ref;
  Profile? _lastRemovedProfile;
  SwipeDirection? _lastSwipeDirection;
  
  DiscoverProfilesNotifier(this._ref)
      : _profileService = _ref.read(profileServiceProvider),
        super(const DiscoverProfilesState(profiles: AsyncValue.loading()));

  // Provider definition
  static final provider = StateNotifierProvider<DiscoverProfilesNotifier, DiscoverProfilesState>((ref) {
    return DiscoverProfilesNotifier(ref);
  });

  Future<void> loadProfiles() async {
    try {
      print('⟹ [DiscoverProfilesNotifier] Loading profiles...');
      state = const DiscoverProfilesState(profiles: AsyncValue.loading());
      
      final profiles = await _profileService.getDiscoverProfiles();
      
      print('⟹ [DiscoverProfilesNotifier] Loaded ${profiles.length} profiles');
      state = DiscoverProfilesState(profiles: AsyncValue.data(profiles));
    } on DioException catch (e) {
      print('⟹ [DiscoverProfilesNotifier] Failed to load profiles: ${e.message}');
      state = DiscoverProfilesState(profiles: AsyncValue.error(e, StackTrace.current));
    } catch (e, stack) {
      print('⟹ [DiscoverProfilesNotifier] Error loading profiles: $e');
      state = DiscoverProfilesState(profiles: AsyncValue.error(e, stack));
    }
  }

  // Add refreshProfiles method
  Future<void> refreshProfiles() async {
    _lastRemovedProfile = null;
    _lastSwipeDirection = null;
    await loadProfiles();
  }

  Future<void> likeProfile(String profileId) async {
    try {
      if (state.profiles is! AsyncData<List<Profile>>) return;
      final currentProfiles = (state.profiles as AsyncData<List<Profile>>).value;
      final likedProfile = currentProfiles.firstWhere((p) => p.id == profileId);
      
      print('⟹ [DiscoverProfilesNotifier] Liking profile: $profileId');
      await _profileService.likeProfile(profileId);
      
      // Store last action before updating state
      _lastRemovedProfile = likedProfile;
      _lastSwipeDirection = SwipeDirection.like;
      
      state = DiscoverProfilesState(
        profiles: AsyncValue.data(currentProfiles.where((p) => p.id != profileId).toList()),
      );
    } catch (e) {
      print('⟹ [DiscoverProfilesNotifier] Error liking profile: $e');
    }
  }

  Future<void> dislikeProfile(String profileId) async {
    try {
      if (state.profiles is! AsyncData<List<Profile>>) return;
      final currentProfiles = (state.profiles as AsyncData<List<Profile>>).value;
      final dislikedProfile = currentProfiles.firstWhere((p) => p.id == profileId);
      
      print('⟹ [DiscoverProfilesNotifier] Disliking profile: $profileId');
      await _profileService.dislikeProfile(profileId);
      
      // Store last action before updating state
      _lastRemovedProfile = dislikedProfile;
      _lastSwipeDirection = SwipeDirection.dislike;
      
      state = DiscoverProfilesState(
        profiles: AsyncValue.data(currentProfiles.where((p) => p.id != profileId).toList()),
      );
    } catch (e) {
      print('⟹ [DiscoverProfilesNotifier] Error disliking profile: $e');
    }
  }

  Future<void> superlikeProfile(String profileId) async {
    try {
      if (state.profiles is! AsyncData<List<Profile>>) return;
      final currentProfiles = (state.profiles as AsyncData<List<Profile>>).value;
      final superlikedProfile = currentProfiles.firstWhere((p) => p.id == profileId);
      
      print('⟹ [DiscoverProfilesNotifier] Superliking profile: $profileId');
      await _profileService.superlikeProfile(profileId);
      
      // Store last action before updating state
      _lastRemovedProfile = superlikedProfile;
      _lastSwipeDirection = SwipeDirection.superLike;
      
      state = DiscoverProfilesState(
        profiles: AsyncValue.data(currentProfiles.where((p) => p.id != profileId).toList()),
      );
    } catch (e) {
      print('⟹ [DiscoverProfilesNotifier] Error superliking profile: $e');
    }
  }

  // Add undoLastAction method
  Future<bool> undoLastAction() async {
    if (_lastRemovedProfile == null || _lastSwipeDirection == null) {
      print('⟹ [DiscoverProfilesNotifier] No action to undo');
      return false;
    }

    try {
      if (state.profiles is! AsyncData<List<Profile>>) return false;
      final currentProfiles = (state.profiles as AsyncData<List<Profile>>).value;
      
      // Undo the action on the backend
      switch (_lastSwipeDirection!) {
        case SwipeDirection.like:
          await _undoLike(_lastRemovedProfile!.id);
          break;
        case SwipeDirection.dislike:
          await _undoDislike(_lastRemovedProfile!.id);
          break;
        case SwipeDirection.superLike:
          await _undoSuperLike(_lastRemovedProfile!.id);
          break;
      }
      
      // Add the profile back to the list
      final updatedProfiles = List<Profile>.from(currentProfiles)
        ..insert(0, _lastRemovedProfile!);
      
      state = DiscoverProfilesState(
        profiles: AsyncValue.data(updatedProfiles),
      );
      
      // Clear the last action
      _lastRemovedProfile = null;
      _lastSwipeDirection = null;
      
      return true;
    } catch (e) {
      print('⟹ [DiscoverProfilesNotifier] Error undoing last action: $e');
      return false;
    }
  }
  
  // Helper methods for undoing actions
  Future<void> _undoLike(String profileId) async {
    try {
      print('⟹ [DiscoverProfilesNotifier] Undoing like for profile: $profileId');
      // Ideally this would call an API endpoint, but for now, we'll just log it
      // In production, implement ProfileService.undoLike
    } catch (e) {
      print('⟹ [DiscoverProfilesNotifier] Error undoing like: $e');
    }
  }
  
  Future<void> _undoDislike(String profileId) async {
    try {
      print('⟹ [DiscoverProfilesNotifier] Undoing dislike for profile: $profileId');
      // Ideally this would call an API endpoint, but for now, we'll just log it
      // In production, implement ProfileService.undoDislike
    } catch (e) {
      print('⟹ [DiscoverProfilesNotifier] Error undoing dislike: $e');
    }
  }
  
  Future<void> _undoSuperLike(String profileId) async {
    try {
      print('⟹ [DiscoverProfilesNotifier] Undoing superlike for profile: $profileId');
      // Ideally this would call an API endpoint, but for now, we'll just log it
      // In production, implement ProfileService.undoSuperLike
    } catch (e) {
      print('⟹ [DiscoverProfilesNotifier] Error undoing superlike: $e');
    }
  }
} 