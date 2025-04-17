import 'dart:io';
import 'package:flutter/foundation.dart'; // For immutable annotation
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // Import XFile
import '../models/profile.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart'; // Assuming you have this for image uploads
import '../providers/providers.dart'; // Import common providers like storageServiceProvider, userEmailProvider
import 'auth_provider.dart'; // For getting user ID

// Existing provider for the service
final profileServiceProvider = Provider<ProfileService>((ref) {
  // Assuming Dio provider setup is done elsewhere and accessible
  final dio = ref.watch(dioProvider);
  // FIX: Pass dio to the constructor
  return ProfileService(dio);
});

// Provider to fetch the current user's profile
final userProfileProvider = FutureProvider<Profile>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) {
    // If no user is logged in, throw an error or return a default/empty profile
    throw Exception("User not logged in");
    // return Profile.empty(); // Or return a default empty profile
  }
  final profileService = ref.watch(profileServiceProvider);
  // FIX: Use the correct method name (assuming getCurrentUserProfile)
  final profile = await profileService.getCurrentUserProfile(); // Adjust if method name is different
  if (profile == null) {
     // Handle case where profile doesn't exist yet (e.g., new user)
     // Maybe return a default profile or throw a specific error
     print("Profile not found for user $userId, returning default.");
     // Return a default Profile object. Ensure Profile model has a constructor for this.
     // FIX: Add required 'age', remove non-existent 'email'
     return Profile(
        id: int.tryParse(userId) ?? 0, // Ensure ID is int if needed by model
        name: "New User", // Default name
        // email: ref.read(userEmailProvider) ?? '', // FIX: Profile model doesn't have email
        age: 18, // FIX: Add required age
        birthDate: DateTime.now().subtract(Duration(days: 365*18)), // Default age
        gender: 'other',
        // Add other default fields as necessary
        interests: [],
        prompts: {}, // <-- Initialize prompts map
        photoUrls: [],
      );
     // throw Exception("Profile not found for user $userId");
  }
  return profile;
});

// --- NEW: Simple class for profile prompts ---
@immutable
class ProfilePrompt {
  final String question;
  final String answer;

  const ProfilePrompt({required this.question, this.answer = ''});

  // Optional: Add copyWith if needed for easier updates
  ProfilePrompt copyWith({
    String? question,
    String? answer,
  }) {
    return ProfilePrompt(
      question: question ?? this.question,
      answer: answer ?? this.answer,
    );
  }

  // Optional: Equality and hashCode for state comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfilePrompt &&
          runtimeType == other.runtimeType &&
          question == other.question &&
          answer == other.answer;

  @override
  int get hashCode => question.hashCode ^ answer.hashCode;

   // Optional: To/From JSON for persistence if storing directly
   Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
      };

   factory ProfilePrompt.fromJson(Map<String, dynamic> json) => ProfilePrompt(
        question: json['question'] as String,
        answer: json['answer'] as String? ?? '',
      );
}
// --- End of ProfilePrompt ---

// --- Profile Edit State Notifier ---

@immutable
class ProfileEditState {
  final Profile? initialProfile; // The profile loaded initially
  final String name;
  final DateTime birthDate;
  final String gender;
  final String bio;
  final String location;
  final String occupation;
  final List<String> interests;
  final List<ProfilePrompt> prompts; // <-- NEW: Add prompts list
  final XFile? pickedImageFile; // For temporary image selection
  final AsyncValue<void> saveState; // State of the save operation

  const ProfileEditState({
    this.initialProfile,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.bio,
    required this.location,
    required this.occupation,
    required this.interests,
    required this.prompts, // <-- Initialize prompts
    this.pickedImageFile,
    this.saveState = const AsyncValue.data(null), // Initial state is success (no operation pending)
  });

  // Initial state factory
  factory ProfileEditState.initial() {
    // Provide sensible defaults, maybe load from a default Profile if needed
    return ProfileEditState(
      name: '',
      birthDate: DateTime.now().subtract(Duration(days: 365 * 18)), // Default to 18 years ago
      gender: 'other',
      bio: '',
      location: '',
      occupation: '',
      interests: [],
      prompts: [], // <-- Initialize empty prompts
    );
  }

  // Create state from an existing profile
  factory ProfileEditState.fromProfile(Profile profile) {
    return ProfileEditState(
      initialProfile: profile,
      name: profile.name,
      birthDate: profile.birthDate,
      gender: profile.gender,
      bio: profile.bio ?? '',
      location: profile.location ?? '',
      occupation: profile.occupation ?? '',
      interests: List<String>.from(profile.interests ?? []),
      // Convert Map<String, String> from Profile model to List<ProfilePrompt>
      prompts: (profile.prompts?.entries ?? [])
          .map((e) => ProfilePrompt(question: e.key, answer: e.value))
          .toList(),
      saveState: const AsyncValue.data(null),
    );
  }

  // CopyWith method for immutability
  ProfileEditState copyWith({
    Profile? initialProfile, // Allow updating initial profile if necessary
    String? name,
    DateTime? birthDate,
    String? gender,
    String? bio,
    String? location,
    String? occupation,
    List<String>? interests,
    List<ProfilePrompt>? prompts, // <-- Add prompts to copyWith
    XFile? pickedImageFile,
    bool clearPickedImage = false, // Flag to explicitly clear the picked image
    AsyncValue<void>? saveState,
  }) {
    return ProfileEditState(
      initialProfile: initialProfile ?? this.initialProfile,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      occupation: occupation ?? this.occupation,
      interests: interests ?? this.interests,
      prompts: prompts ?? this.prompts, // <-- Handle prompts copy
      pickedImageFile: clearPickedImage ? null : pickedImageFile ?? this.pickedImageFile,
      saveState: saveState ?? this.saveState,
    );
  }

  // Helper to check if changes have been made
   bool get hasChanges {
     if (initialProfile == null) return true; // If no initial profile, assume changes

     // Convert current prompts back to Map for comparison
     final currentPromptsMap = { for (var p in prompts) p.question : p.answer };

     return name != initialProfile!.name ||
            birthDate != initialProfile!.birthDate ||
            gender != initialProfile!.gender ||
            bio != (initialProfile!.bio ?? '') ||
            location != (initialProfile!.location ?? '') ||
            occupation != (initialProfile!.occupation ?? '') ||
            !_listEquals(interests, initialProfile!.interests ?? []) ||
            !_mapEquals(currentPromptsMap, initialProfile!.prompts ?? {}) || // <-- Compare prompts map
            pickedImageFile != null;
   }

   // Helper for list equality (consider using collection package for more robust check)
   bool _listEquals(List<String> a, List<String> b) {
      if (a.length != b.length) return false;
      final sortedA = List<String>.from(a)..sort();
      final sortedB = List<String>.from(b)..sort();
      for (int i = 0; i < sortedA.length; i++) {
         if (sortedA[i] != sortedB[i]) return false;
      }
      return true;
   }
    // Helper for map equality
   bool _mapEquals(Map<String, String> a, Map<String, String> b) {
     if (a.length != b.length) return false;
     for (final key in a.keys) {
       if (!b.containsKey(key) || a[key] != b[key]) {
         return false;
       }
     }
     return true;
   }
}

class ProfileEditNotifier extends StateNotifier<ProfileEditState> {
  final ProfileService _profileService;
  final StorageService _storageService;
  final String _userId;
  final Ref _ref; // FIX: Add ref field

  // FIX: Accept Ref in constructor
  ProfileEditNotifier(this._profileService, this._storageService, this._userId, this._ref)
      : super(ProfileEditState.initial());

  // Initialize the state with the user's current profile
  void initialize(Profile profile) {
    state = ProfileEditState.fromProfile(profile);
  }

  // Update methods for each field
  void updateName(String name) => state = state.copyWith(name: name);
  void updateBirthDate(DateTime birthDate) => state = state.copyWith(birthDate: birthDate);
  void updateGender(String gender) => state = state.copyWith(gender: gender);
  void updateBio(String bio) => state = state.copyWith(bio: bio);
  void updateLocation(String location) => state = state.copyWith(location: location);
  void updateOccupation(String occupation) => state = state.copyWith(occupation: occupation);

  void addInterest(String interest) {
    if (interest.trim().isNotEmpty && !state.interests.contains(interest.trim())) {
      state = state.copyWith(interests: [...state.interests, interest.trim()]);
    }
  }

  void removeInterest(String interest) {
    state = state.copyWith(interests: state.interests.where((i) => i != interest).toList());
  }

  // --- NEW: Methods for managing prompts ---
  void addPrompt(ProfilePrompt prompt) {
     // Prevent adding duplicate questions or exceeding a limit (e.g., 3)
     if (state.prompts.length < 3 && !state.prompts.any((p) => p.question == prompt.question)) {
       state = state.copyWith(prompts: [...state.prompts, prompt]);
     }
     // Optionally show feedback if limit reached or question exists
  }

  void updatePromptAnswer(int index, String answer) {
    if (index >= 0 && index < state.prompts.length) {
      final updatedPrompts = List<ProfilePrompt>.from(state.prompts);
      updatedPrompts[index] = updatedPrompts[index].copyWith(answer: answer);
      state = state.copyWith(prompts: updatedPrompts);
    }
  }

   void updatePromptAnswerByQuestion(String question, String answer) {
     final index = state.prompts.indexWhere((p) => p.question == question);
     if (index != -1) {
        updatePromptAnswer(index, answer);
     }
   }

  void removePrompt(int index) {
    if (index >= 0 && index < state.prompts.length) {
      final updatedPrompts = List<ProfilePrompt>.from(state.prompts);
      updatedPrompts.removeAt(index);
      state = state.copyWith(prompts: updatedPrompts);
    }
  }
   void removePromptByQuestion(String question) {
     final index = state.prompts.indexWhere((p) => p.question == question);
     if (index != -1) {
       removePrompt(index);
     }
   }
  // --- End of Prompt Methods ---

  void setPickedImage(XFile? imageFile) {
    state = state.copyWith(pickedImageFile: imageFile);
  }

  // Method to save the profile (uploads image if changed)
  Future<void> saveProfile() async {
    if (!state.hasChanges) {
      print("No changes detected, skipping save.");
      state = state.copyWith(saveState: AsyncValue.data(null)); // Reset save state
      return;
    }

    state = state.copyWith(saveState: AsyncValue.loading());

    try {
      String? imageUrl = state.initialProfile?.photoUrls?.isNotEmpty == true
                         ? state.initialProfile!.photoUrls!.first
                         : null;

      // Upload new image if one was picked
      if (state.pickedImageFile != null) {
        imageUrl = await _storageService.uploadProfileImage(state.pickedImageFile!, _userId);
      }

       // Convert List<ProfilePrompt> back to Map<String, String> for the Profile model
      final promptsMap = { for (var p in state.prompts) p.question : p.answer };

      // Prepare profile data for update
      final updatedProfileData = {
        'name': state.name,
        'birthDate': state.birthDate.toIso8601String(),
        'gender': state.gender,
        'bio': state.bio,
        'location': state.location,
        'occupation': state.occupation,
        'interests': state.interests,
        'prompts': promptsMap, // Save the map
        'photoUrls': imageUrl != null ? [imageUrl] : [], // Save as list
        // Add other fields that might be editable
      };

      // Call the service to update the profile in the backend
      // Assuming profileService has an update method
      // await _profileService.updateUserProfile(_userId, updatedProfileData);
      print("[ProfileEditNotifier] Simulating profile update...");
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      print("[ProfileEditNotifier] Profile update simulation complete.");

      // Update successful
      // Create a new Profile object reflecting the saved state to update initialProfile
      // This prevents the `hasChanges` getter from being true immediately after saving.
      // FIX: Add required 'age'
      final newInitialProfile = Profile(
         id: int.tryParse(_userId) ?? 0, // Ensure ID matches model type if needed
         name: state.name,
         age: Profile.calculateAge(state.birthDate), // FIX: Calculate and add age
         birthDate: state.birthDate,
         gender: state.gender,
         bio: state.bio,
         location: state.location,
         occupation: state.occupation,
         interests: state.interests,
         prompts: promptsMap,
         photoUrls: imageUrl != null ? [imageUrl] : [],
         isVerified: state.initialProfile?.isVerified ?? false, // Preserve verification status
      );
      state = state.copyWith(
         initialProfile: newInitialProfile,
         pickedImageFile: null, // Clear picked image after successful save
         clearPickedImage: true,
         saveState: AsyncValue.data(null)
      );
      // Also refresh the main user profile provider to reflect changes globally
      // FIX: Use the stored _ref
      _ref.invalidate(userProfileProvider);

    } catch (e, stackTrace) {
      print('Failed to save profile: $e\n$stackTrace'); // Combine error and stacktrace
      state = state.copyWith(saveState: AsyncValue.error(e, stackTrace));
    }
  }
}

// Provider for the edit state notifier
// We need the initial profile data to create the notifier.
// This setup assumes ProfileScreen will read userProfileProvider first
// and then create/watch this provider, passing the initial data.
// This is a bit tricky. A family provider might be better if multiple
// profiles could be edited, but for the current user's profile, this is common.
//
// Alternative: Use a family provider based on user ID.
// final profileEditProvider = StateNotifierProvider.family<ProfileEditNotifier, ProfileEditState, String>((ref, userId) {
//   final profileService = ref.watch(profileServiceProvider);
//   // How to get initial profile here? Maybe another provider?
//   // This highlights complexity in initializing StateNotifiers with async data.
// });
//
// Simpler approach for now: Assume the UI fetches the profile first via userProfileProvider
// and then passes it to this provider when needed. This often involves creating the
// provider *inside* the widget build when the data is available, which is less common
// but works for screen-specific state.
//
// Let's refine this: Create the provider globally, but initialize the state later.
final profileEditProvider = StateNotifierProvider<ProfileEditNotifier, ProfileEditState>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  final storageService = ref.watch(storageServiceProvider); // Assuming you have this provider
  final userId = ref.watch(userIdProvider); // Get current user ID

  if (userId == null) {
    // Handle case where user is not logged in - maybe throw an error or return a dummy notifier
    throw Exception("User not logged in, cannot edit profile.");
  }
  // FIX: Pass ref to the notifier
  return ProfileEditNotifier(profileService, storageService, userId, ref);
});

// ---- Old Example Commented Out ----
// You might also want providers for updating the profile, etc.
// Example:
// final profileUpdateNotifierProvider = StateNotifierProvider<ProfileUpdateNotifier, AsyncValue<void>>((ref) {
//   return ProfileUpdateNotifier(ref.watch(profileServiceProvider));
// });

// class ProfileUpdateNotifier extends StateNotifier<AsyncValue<void>> {
//   final ProfileService _profileService;
//   ProfileUpdateNotifier(this._profileService) : super(const AsyncValue.data(null));

//   Future<void> updateProfile(Profile profile) async {
//     state = const AsyncValue.loading();
//     try {
//       await _profileService.updateProfile(profile);
//       state = const AsyncValue.data(null);
//     } catch (e, s) {
//       state = AsyncValue.error(e, s);
//       // Optionally rethrow or handle error further
//     }
//   }
// }

// Mock Storage Service Provider (Replace with your actual implementation)
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(); // Replace with your actual storage service
}); 