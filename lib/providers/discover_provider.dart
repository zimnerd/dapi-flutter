// For immutable annotation
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../services/profile_service.dart'; // Import ProfileService
// Import providers from central providers file
import 'providers.dart' show profileServiceProvider, premiumProvider;

// Define state class with immutable properties
class DiscoverState {
  final AsyncValue<List<Profile>> profiles;
  final Profile? lastRemovedProfile; // For premium undo feature

  const DiscoverState({
    required this.profiles,
    this.lastRemovedProfile,
  });

  // Initial state constructor
  factory DiscoverState.initial() {
    return const DiscoverState(
      profiles: AsyncValue.loading(),
      lastRemovedProfile: null,
    );
  }

  // CopyWith for immutable state updates
  DiscoverState copyWith({
    AsyncValue<List<Profile>>? profiles,
    Profile? lastRemovedProfile,
    bool clearLastRemoved = false, // Flag to clear lastRemovedProfile
  }) {
    return DiscoverState(
      profiles: profiles ?? this.profiles,
      lastRemovedProfile: clearLastRemoved
          ? null
          : lastRemovedProfile ?? this.lastRemovedProfile,
    );
  }
}

class DiscoverNotifier extends StateNotifier<DiscoverState> {
  final ProfileService _profileService;
  final Ref _ref;

  DiscoverNotifier(this._profileService, this._ref)
      : super(DiscoverState.initial()) {
    _fetchProfiles(); // Fetch profiles when created
  }

  // Method to fetch profiles from the service
  Future<void> _fetchProfiles() async {
    // Don't set loading if profiles already exist (refresh scenario)
    if (state.profiles is! AsyncData) {
      state = state.copyWith(profiles: const AsyncValue.loading());
    }
    try {
      // Get filters from provider if needed
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
    // Check premium status
    final isPremium = await _ref.read(premiumProvider.future);
    final profileToRestore = state.lastRemovedProfile;

    if (!isPremium) {
      print('Premium required for undo feature');
      return false;
    }

    if (profileToRestore == null) {
      print('No profile to restore');
      return false;
    }

    // Get current profiles and add the last removed one back to the front
    state.profiles.whenData((currentProfiles) {
      final updatedProfiles = [profileToRestore, ...currentProfiles];
      state = state.copyWith(
          profiles: AsyncValue.data(updatedProfiles), lastRemovedProfile: null);
    });

    return true;
  }
}

// StateNotifierProvider for discover profiles
final discoverProfilesProvider =
    StateNotifierProvider.autoDispose<DiscoverNotifier, DiscoverState>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  return DiscoverNotifier(profileService, ref);
});

// Convenience provider for direct ProfileService access
final discoverServiceProvider = Provider<ProfileService>((ref) {
  return ref.watch(profileServiceProvider);
});

// Removed the old FutureProvider
// final discoverProfilesProvider = FutureProvider.autoDispose<List<Profile>>((ref) async { ... });

// TODO: Optionally, create a provider for filters if complex
// final discoverFiltersProvider = StateNotifierProvider<...> ...

final discoverProvider = Provider<ProfileService>((ref) {
  final profileService = ref.watch(profileServiceProvider); // Updated reference
  return profileService;
});
