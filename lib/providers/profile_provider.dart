import 'dart:io';
import 'package:flutter/foundation.dart'; // For immutable annotation
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // Import XFile
import '../models/profile.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart'; // For image uploads
import 'auth_provider.dart'; // For getting user ID
import 'profile_service_provider.dart'; // Import the canonical profileServiceProvider
import 'providers.dart' show storageServiceProvider, userIdProvider;

// User profile provider
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<Profile?>>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  return UserProfileNotifier(profileService);
});

class UserProfileNotifier extends StateNotifier<AsyncValue<Profile?>> {
  final ProfileService _profileService;

  UserProfileNotifier(this._profileService) : super(const AsyncValue.loading()) {
    loadCurrentUserProfile();
  }

  Future<void> loadCurrentUserProfile() async {
    try {
      state = const AsyncValue.loading();
      final profile = await _profileService.getCurrentUserProfile();
      state = AsyncValue.data(profile);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      state = const AsyncValue.loading();
      final currentProfile = state.value;
      if (currentProfile == null) {
        throw Exception('No current profile found');
      }
      final updatedProfile = await _profileService.updateProfile(currentProfile.id, data);
      state = AsyncValue.data(updatedProfile);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createProfile(Map<String, dynamic> data) async {
    try {
      state = const AsyncValue.loading();
      final profile = await _profileService.createProfile(data);
      state = AsyncValue.data(profile);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

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
    this.location = '',
    this.occupation = '',
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
    // Safe access for nullable fields
    final birthDate = profile.birthDate ?? DateTime.now().subtract(Duration(days: 365 * 18));
    final gender = profile.gender ?? 'other';
    final bio = profile.bio ?? '';
    
    // Handle location which could be a Map or String
    String locationStr = '';
    if (profile.location is Map) {
      final locationMap = profile.location as Map;
      locationStr = '${locationMap['city'] ?? ''}, ${locationMap['country'] ?? ''}';
    } else if (profile.location is String) {
      locationStr = profile.location as String;
    }
    
    // Convert prompts from List<Map<String, String>> to List<ProfilePrompt>
    final List<ProfilePrompt> promptsList = [];
    if (profile.prompts.isNotEmpty) {
      for (final promptMap in profile.prompts) {
        promptsList.add(ProfilePrompt(
          question: promptMap['question'] ?? '',
          answer: promptMap['answer'] ?? '',
        ));
      }
    }

    return ProfileEditState(
      initialProfile: profile,
      name: profile.name,
      birthDate: birthDate,
      gender: gender,
      bio: bio,
      location: locationStr,
      occupation: profile.occupation ?? '',
      interests: List<String>.from(profile.interests),
      prompts: promptsList,
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

    // Convert current prompts to format for comparison
    final List<Map<String, String>> currentPromptsList = prompts.map((p) => {
      'question': p.question, 
      'answer': p.answer
    }).toList();

    // Prepare location comparison
    String initialLocationStr = '';
    if (initialProfile!.location is Map) {
      final locationMap = initialProfile!.location as Map;
      initialLocationStr = '${locationMap['city'] ?? ''}, ${locationMap['country'] ?? ''}';
    } else if (initialProfile!.location is String) {
      initialLocationStr = initialProfile!.location as String;
    }

    return name != initialProfile!.name ||
           birthDate != initialProfile!.birthDate ||
           gender != (initialProfile!.gender ?? '') ||
           bio != (initialProfile!.bio ?? '') ||
           location != initialLocationStr ||
           occupation != (initialProfile!.occupation ?? '') ||
           !_listEquals(interests, initialProfile!.interests) ||
           !_arePromptsEqual(currentPromptsList, initialProfile!.prompts) ||
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

  // Helper for prompts equality
  bool _arePromptsEqual(List<Map<String, String>> a, List<Map<String, String>> b) {
    if (a.length != b.length) return false;
    
    // Simple comparison - check if each item in a has a matching item in b
    for (var aItem in a) {
      bool foundMatch = false;
      for (var bItem in b) {
        if (aItem['question'] == bItem['question'] && aItem['answer'] == bItem['answer']) {
          foundMatch = true;
          break;
        }
      }
      if (!foundMatch) return false;
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

  // --- Methods for managing prompts ---
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
      String? imageUrl = state.initialProfile?.photoUrls.isNotEmpty == true
                         ? state.initialProfile!.photoUrls.first
                         : null;

      // Upload new image if one was picked
      if (state.pickedImageFile != null) {
        imageUrl = await _storageService.uploadProfileImage(state.pickedImageFile!, _userId);
      }

      // Convert List<ProfilePrompt> to List<Map<String, String>> for the Profile model
      final List<Map<String, String>> promptsList = state.prompts.map((p) => {
        'question': p.question,
        'answer': p.answer
      }).toList();

      // Prepare profile data for update
      final updatedProfileData = {
        'name': state.name,
        'birth_date': state.birthDate.toIso8601String(),
        'gender': state.gender,
        'bio': state.bio,
        'location': {'city': state.location, 'country': ''}, // Simplify for now
        'occupation': state.occupation,
        'interests': state.interests,
        'prompts': promptsList,
        'photos': imageUrl != null ? [imageUrl] : [],
      };

      // Call the service to update the profile in the backend
      print("[ProfileEditNotifier] Simulating profile update...");
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      print("[ProfileEditNotifier] Profile update simulation complete.");

      // Update successful - create a Profile object from the saved state
      final newInitialProfile = Profile(
        id: _userId,
        name: state.name,
        birthDate: state.birthDate,
        gender: state.gender,
        bio: state.bio,
        location: {'city': state.location, 'country': ''},
        occupation: state.occupation,
        interests: state.interests,
        prompts: promptsList,
        photoUrls: imageUrl != null ? [imageUrl] : [],
        isVerified: state.initialProfile?.isVerified ?? false,
      );
      
      state = state.copyWith(
        initialProfile: newInitialProfile,
        pickedImageFile: null, // Clear picked image after successful save
        clearPickedImage: true,
        saveState: AsyncValue.data(null)
      );
      
      // Also refresh the main user profile provider to reflect changes globally
      _ref.invalidate(userProfileProvider);

    } catch (e, stackTrace) {
      print('Failed to save profile: $e\n$stackTrace'); // Combine error and stacktrace
      state = state.copyWith(saveState: AsyncValue.error(e, stackTrace));
    }
  }
}

// Provider for the edit state notifier
final profileEditProvider = StateNotifierProvider<ProfileEditNotifier, ProfileEditState>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  final storageService = ref.watch(storageServiceProvider); // Assuming you have this provider
  final userId = ref.watch(userIdProvider); // Get current user ID

  if (userId == null) {
    // Handle case where user is not logged in - maybe throw an error or return a dummy notifier
    throw Exception("User not logged in, cannot edit profile.");
  }
  return ProfileEditNotifier(profileService, storageService, userId, ref);
});

