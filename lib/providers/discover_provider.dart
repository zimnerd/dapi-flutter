import 'package:flutter/foundation.dart'; // For immutable annotation
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
// Import the ProfileService class directly
import '../services/profile_service.dart';
// FIX: Import the profile service provider from profile_provider.dart
import 'profile_provider.dart'; // Use profileServiceProvider defined here
import 'subscription_provider.dart'; // For premium check later

// --- State Definition ---
@immutable
class DiscoverState {
  final AsyncValue<List<Profile>> profiles; // Use AsyncValue to handle loading/error
  final Profile? lastRemovedProfile; // Store the profile for undo

  const DiscoverState({
    required this.profiles,
    this.lastRemovedProfile,
  });

  // Initial state
  const DiscoverState.initial()
      : profiles = const AsyncValue.loading(),
        lastRemovedProfile = null;

  // CopyWith method
  DiscoverState copyWith({
    AsyncValue<List<Profile>>? profiles,
    Profile? lastRemovedProfile,
    bool clearLastRemoved = false, // Flag to explicitly clear
  }) {
    return DiscoverState(
      profiles: profiles ?? this.profiles,
      lastRemovedProfile: clearLastRemoved ? null : lastRemovedProfile ?? this.lastRemovedProfile,
    );
  }
}

// --- State Notifier Definition ---
class DiscoverNotifier extends StateNotifier<DiscoverState> {
  final ProfileService _profileService;
  final Ref _ref; // Keep ref for reading other providers

  DiscoverNotifier(this._profileService, this._ref) : super(const DiscoverState.initial()) {
    _fetchProfiles(); // Fetch initial profiles on creation
  }

  // Fetch profiles from the service
  Future<void> _fetchProfiles() async {
    // Don't set loading if profiles already exist (refresh scenario)
    if (state.profiles is! AsyncData) {
       state = state.copyWith(profiles: const AsyncValue.loading());
    }
    try {
      // TODO: Add filter parameters here if needed later
      final profileList = await _profileService.getDiscoverProfiles();
      state = state.copyWith(
          profiles: AsyncValue.data(profileList),
          clearLastRemoved: true // Clear undo state on new fetch/refresh
      );
    } catch (e, stack) {
      state = state.copyWith(profiles: AsyncValue.error(e, stack));
    }
  }

  // Method to refresh profiles
  Future<void> refresh() async {
    // Explicitly set loading state when refresh is called
    state = state.copyWith(profiles: const AsyncValue.loading());
    await _fetchProfiles();
  }

  // --- Placeholder Methods for Swipe Actions (to be implemented) ---

  // Called after a swipe action completes
  void removeFirstProfile() {
     state.profiles.whenData((profileList) {
        if (profileList.isNotEmpty) {
           final removedProfile = profileList.first;
           final updatedList = List<Profile>.from(profileList)..removeAt(0);
           state = state.copyWith(
              profiles: AsyncValue.data(updatedList),
              lastRemovedProfile: removedProfile // Store for undo
           );
        }
     });
  }

  // Undo the last swipe (premium feature)
  Future<bool> undoLastSwipe() async {
     final isPremium = _ref.read(premiumStatusProvider); // Use the correct provider name
     final profileToRestore = state.lastRemovedProfile;

     if (isPremium && profileToRestore != null) {
       // Simulate network delay for effect?
       await Future.delayed(const Duration(milliseconds: 200));

       state.profiles.whenData((profileList) {
          final updatedList = [profileToRestore, ...profileList];
          state = state.copyWith(
             profiles: AsyncValue.data(updatedList),
             clearLastRemoved: true // Clear undo state after restoring
          );
       });
       print("Undo successful for ${profileToRestore.name}");
       return true; // Indicate success
     } else if (!isPremium) {
       print("Undo failed: User is not premium.");
       // TODO: Trigger premium upsell prompt?
       // ref.read(uiStateProvider.notifier).showPremiumUpsell('undo_swipe');
       return false;
     } else {
        print("Undo failed: No profile to restore.");
        return false; // Nothing to undo
     }
  }
}

// --- StateNotifierProvider Definition ---
final discoverProfilesProvider = StateNotifierProvider.autoDispose<DiscoverNotifier, DiscoverState>((ref) {
  // Watch the correctly imported profileServiceProvider
  final profileService = ref.watch(profileServiceProvider);
  return DiscoverNotifier(profileService, ref);
});

// Removed the old FutureProvider
// final discoverProfilesProvider = FutureProvider.autoDispose<List<Profile>>((ref) async { ... });

// TODO: Optionally, create a provider for filters if complex
// final discoverFiltersProvider = StateNotifierProvider<...> ... 