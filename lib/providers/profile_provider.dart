import 'package:flutter/foundation.dart'; // For immutable annotation
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // Import XFile
import '../models/profile.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart'; // For image uploads
// For getting user ID
import 'profile_service_provider.dart'; // Import the canonical profileServiceProvider
import 'providers.dart' show storageServiceProvider, userIdProvider;

// User profile provider
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<Profile?>>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  return UserProfileNotifier(profileService);
});

class UserProfileNotifier extends StateNotifier<AsyncValue<Profile?>> {
  final ProfileService _profileService;

  UserProfileNotifier(this._profileService)
      : super(const AsyncValue.loading()) {
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
      final updatedProfile =
          await _profileService.updateProfile(currentProfile.id, data);
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
  final Profile? initialProfile;
  final String name;
  final DateTime birthDate;
  final String gender;
  final String bio;
  final String location;
  final String occupation;
  final String? education;
  final List<String> interests;
  final List<String> photoUrls;
  final List<ProfilePrompt> prompts;
  final XFile? pickedImageFile;
  final bool isVerified;
  final int? minAgePreference;
  final int? maxAgePreference;
  final int? maxDistance;
  final String? genderPreference;
  final AsyncValue<void> saveState;

  const ProfileEditState({
    this.initialProfile,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.bio,
    this.location = '',
    this.occupation = '',
    this.education,
    required this.interests,
    required this.photoUrls,
    required this.prompts,
    this.pickedImageFile,
    this.isVerified = false,
    this.minAgePreference,
    this.maxAgePreference,
    this.maxDistance,
    this.genderPreference,
    this.saveState = const AsyncValue.data(null),
  });

  factory ProfileEditState.initial() {
    return ProfileEditState(
      name: '',
      birthDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      gender: 'other',
      bio: '',
      location: '',
      occupation: '',
      education: null,
      interests: [],
      photoUrls: [],
      prompts: [],
      isVerified: false,
      minAgePreference: null,
      maxAgePreference: null,
      maxDistance: null,
      genderPreference: null,
    );
  }

  ProfileEditState copyWith({
    Profile? initialProfile,
    String? name,
    DateTime? birthDate,
    String? gender,
    String? bio,
    String? location,
    String? occupation,
    String? education,
    List<String>? interests,
    List<String>? photoUrls,
    List<ProfilePrompt>? prompts,
    XFile? pickedImageFile,
    bool? isVerified,
    int? minAgePreference,
    int? maxAgePreference,
    int? maxDistance,
    String? genderPreference,
    bool clearPickedImage = false,
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
      education: education ?? this.education,
      interests: interests ?? this.interests,
      photoUrls: photoUrls ?? this.photoUrls,
      prompts: prompts ?? this.prompts,
      pickedImageFile:
          clearPickedImage ? null : pickedImageFile ?? this.pickedImageFile,
      isVerified: isVerified ?? this.isVerified,
      minAgePreference: minAgePreference ?? this.minAgePreference,
      maxAgePreference: maxAgePreference ?? this.maxAgePreference,
      maxDistance: maxDistance ?? this.maxDistance,
      genderPreference: genderPreference ?? this.genderPreference,
      saveState: saveState ?? this.saveState,
    );
  }
}

class ProfileEditNotifier extends StateNotifier<ProfileEditState> {
  final ProfileService _profileService;
  final StorageService _storageService;
  final String _userId;
  final Ref _ref;

  ProfileEditNotifier(
      this._profileService, this._storageService, this._userId, this._ref)
      : super(ProfileEditState.initial());

  // Initialize the state with the user's current profile
  Future<void> initialize() async {
    try {
      final profile = await _profileService.getCurrentUserProfile();
      if (profile != null) {
        _updateFromProfile(profile);
      }
    } catch (e) {
      print('Error initializing profile: $e');
    }
  }

  void _updateFromProfile(Profile profile) {
    String locationStr = '';
    if (profile.location != null) {
      locationStr = profile.location.toString();
    }

    List<ProfilePrompt> promptsList = [];
    if (profile.prompts.isNotEmpty) {
      promptsList = profile.prompts
          .map((promptMap) => ProfilePrompt(
                question: promptMap['question'] ?? '',
                answer: promptMap['answer'] ?? '',
              ))
          .toList();
    }

    state = state.copyWith(
      initialProfile: profile,
      name: profile.name,
      birthDate: profile.birthDate ?? state.birthDate,
      gender: profile.gender ?? state.gender,
      bio: profile.bio ?? state.bio,
      location: locationStr,
      occupation: profile.occupation ?? state.occupation,
      education: profile.education,
      interests: List<String>.from(profile.interests),
      photoUrls: List<String>.from(profile.photoUrls),
      prompts: promptsList,
      isVerified: profile.isVerified,
      minAgePreference: profile.minAgePreference,
      maxAgePreference: profile.maxAgePreference,
      maxDistance: profile.maxDistance,
      genderPreference: profile.genderPreference,
    );
  }

  // Update methods for each field
  void updateName(String name) => state = state.copyWith(name: name);
  void updateBirthDate(DateTime birthDate) =>
      state = state.copyWith(birthDate: birthDate);
  void updateGender(String gender) => state = state.copyWith(gender: gender);
  void updateBio(String bio) => state = state.copyWith(bio: bio);
  void updateLocation(String location) =>
      state = state.copyWith(location: location);
  void updateOccupation(String occupation) =>
      state = state.copyWith(occupation: occupation);
  void updateEducation(String? education) =>
      state = state.copyWith(education: education);

  void addInterest(String interest) {
    if (interest.trim().isNotEmpty &&
        !state.interests.contains(interest.trim())) {
      state = state.copyWith(interests: [...state.interests, interest.trim()]);
    }
  }

  void removeInterest(String interest) {
    state = state.copyWith(
        interests: state.interests.where((i) => i != interest).toList());
  }

  void addPrompt(ProfilePrompt prompt) {
    if (state.prompts.length < 3 &&
        !state.prompts.any((p) => p.question == prompt.question)) {
      state = state.copyWith(prompts: [...state.prompts, prompt]);
    }
  }

  void updatePromptAnswer(int index, String answer) {
    if (index >= 0 && index < state.prompts.length) {
      final updatedPrompts = List<ProfilePrompt>.from(state.prompts);
      updatedPrompts[index] = updatedPrompts[index].copyWith(answer: answer);
      state = state.copyWith(prompts: updatedPrompts);
    }
  }

  void removePrompt(int index) {
    if (index >= 0 && index < state.prompts.length) {
      final updatedPrompts = List<ProfilePrompt>.from(state.prompts);
      updatedPrompts.removeAt(index);
      state = state.copyWith(prompts: updatedPrompts);
    }
  }

  void setPickedImage(XFile? imageFile) {
    state = state.copyWith(pickedImageFile: imageFile);
  }

  Future<void> saveProfile() async {
    try {
      state = state.copyWith(saveState: const AsyncValue.loading());

      // Upload new image if one was picked
      List<String> updatedPhotoUrls = List<String>.from(state.photoUrls);
      if (state.pickedImageFile != null) {
        final imageUrl = await _storageService.uploadProfileImage(
            state.pickedImageFile!, _userId);
        updatedPhotoUrls.insert(0, imageUrl);
      }

      // Convert prompts to the expected format
      final List<Map<String, String>> promptsData = state.prompts
          .map((p) => {'question': p.question, 'answer': p.answer})
          .toList();

      final updatedProfile = await _profileService.updateProfile(_userId, {
        'name': state.name,
        'birth_date': state.birthDate.toIso8601String(),
        'gender': state.gender,
        'photo_urls': updatedPhotoUrls,
        'interests': state.interests,
        'location': state.location,
        'occupation': state.occupation,
        'education': state.education,
        'bio': state.bio,
        'prompts': promptsData,
        'min_age_preference': state.minAgePreference,
        'max_age_preference': state.maxAgePreference,
        'max_distance': state.maxDistance,
        'gender_preference': state.genderPreference,
      });

      if (updatedProfile != null) {
        _updateFromProfile(updatedProfile);
        // Refresh the main user profile provider
        _ref.invalidate(userProfileProvider);
      }
    } catch (e) {
      print('Error saving profile: $e');
      state =
          state.copyWith(saveState: AsyncValue.error(e, StackTrace.current));
      rethrow;
    }
  }
}

// Provider for the edit state notifier
final profileEditProvider =
    StateNotifierProvider<ProfileEditNotifier, ProfileEditState>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  final storageService =
      ref.watch(storageServiceProvider); // Assuming you have this provider
  final userId = ref.watch(userIdProvider); // Get current user ID

  if (userId == null) {
    // Handle case where user is not logged in - maybe throw an error or return a dummy notifier
    throw Exception("User not logged in, cannot edit profile.");
  }
  return ProfileEditNotifier(profileService, storageService, userId, ref);
});
