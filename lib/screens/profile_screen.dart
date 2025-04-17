import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';
import '../utils/platform_utils.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_display.dart';
import '../widgets/animated_tap_feedback.dart';
import '../widgets/interest_badge.dart';
import 'safety_center_screen.dart';
import '../providers/ai_suggestions_provider.dart';

// Convert to ConsumerStatefulWidget
class ProfileScreen extends ConsumerStatefulWidget {
  ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

// Create State class
class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Move controllers inside the State class
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _occupationController = TextEditingController();
  final _interestController = TextEditingController();

  // Removed static state variables and _initializeControllers
  // State is now managed by profileEditProvider

  // No longer static, belongs to the State class
  @override
  void initState() {
    super.initState();
    // Initialization logic moved to build method's post frame callback
    // to ensure providers are ready and initial profile data is available.
  }

  // Dispose controllers correctly
  @override
  void dispose() {
     _nameController.dispose();
     _bioController.dispose();
     _locationController.dispose();
     _occupationController.dispose();
     _interestController.dispose();
     super.dispose(); // Call super.dispose at the end
  }

  // Refactored to use profileEditProvider and add cropping
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    try {
      // 1. Pick image
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Increase max size slightly for better crop quality
        maxHeight: 1024,
        imageQuality: 90, // Slightly higher quality
      );

      if (pickedFile == null) return; // User cancelled picker

      // 2. Crop image using platform-safe method
      final SimpleCroppedFile? croppedFile = await PlatformUtils.cropImage(pickedFile);

      if (croppedFile == null) return; // User cancelled cropper

      // 3. Update state with cropped image file
      final XFile croppedXFile = XFile(croppedFile.path);
      ref.read(profileEditProvider.notifier).setPickedImage(croppedXFile);

    } catch (e) {
      print('Failed to pick/crop image: ${e.toString()}');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to process image: $e'), backgroundColor: Colors.red)
         );
       }
    }
  }

  // Refactored to use profileEditProvider
  void _addInterest() {
    final interest = _interestController.text;
    if (interest.trim().isNotEmpty) {
      // Use ref from State class
      ref.read(profileEditProvider.notifier).addInterest(interest);
      _interestController.clear();
    }
  }

  // Refactored to use profileEditProvider
  void _removeInterest(String interest) {
    // Use ref from State class
    ref.read(profileEditProvider.notifier).removeInterest(interest);
  }

  // Logout remains mostly the same, uses authServiceProvider
  Future<void> _logout() async {
    try {
      // Use ref from State class
      await ref.read(authStateProvider.notifier).logout();
      if (mounted) { // Check mounted status in State class
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      print('Failed to logout: ${e.toString()}');
      if (mounted) { // Check mounted status
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  // --- NEW: Helper to calculate profile completeness ---
  double _calculateProfileCompleteness(ProfileEditState editState) {
    // Assign weights to different profile sections
    const double photoWeight = 0.25; // Having at least one photo
    const double bioWeight = 0.15;
    const double basicInfoWeight = 0.20; // Name, Age, Gender
    const double detailsWeight = 0.10; // Location, Occupation
    const double interestsWeight = 0.15; // Having at least 3 interests
    const double promptsWeight = 0.15; // Having at least 1 prompt answered

    double completeness = 0.0;

    // Check photo (use initial profile photos OR picked image)
    bool hasPhoto = (editState.initialProfile?.photoUrls?.isNotEmpty ?? false) || editState.pickedImageFile != null;
    if (hasPhoto) completeness += photoWeight;

    // Check bio
    if (editState.bio.trim().isNotEmpty) completeness += bioWeight;

    // Check basic info (name is always required for saving, gender has default)
    // We assume birthDate is always present from the state
    if (editState.name.trim().isNotEmpty && editState.gender.isNotEmpty) completeness += basicInfoWeight;

    // Check details
    if (editState.location.trim().isNotEmpty && editState.occupation.trim().isNotEmpty) completeness += detailsWeight;

    // Check interests
    if (editState.interests.length >= 3) completeness += interestsWeight;

    // Check prompts (at least one answered)
    if (editState.prompts.any((p) => p.answer.trim().isNotEmpty)) completeness += promptsWeight;

    // Clamp value between 0.0 and 1.0
    return completeness.clamp(0.0, 1.0);
  }
  // --- End of Completeness Calculation ---

  @override
  Widget build(BuildContext context) {
    // ref is available directly in ConsumerState
    final profileAsyncValue = ref.watch(userProfileProvider);
    final editState = ref.watch(profileEditProvider);
    final editNotifier = ref.read(profileEditProvider.notifier);

    // Listen for save state changes to show SnackBars
    ref.listen<AsyncValue<void>>(profileEditProvider.select((state) => state.saveState), (_, state) {
      state.whenOrNull(
        data: (_) {
          if (mounted) { // Check mounted
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profile saved successfully!'), backgroundColor: Colors.green)
              );
          }
        },
        error: (error, _) {
           if (mounted) { // Check mounted
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save profile: ${error.toString()}'), backgroundColor: Colors.red)
                );
           }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
        ),
        actions: [
          // --- NEW: Safety Center Button ---
          IconButton(
            icon: const Icon(Icons.shield_outlined), // Or Icons.health_and_safety
            tooltip: 'Safety Center',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SafetyCenterScreen()),
              );
            },
          ),
          // --- End Safety Center Button ---

          // Logout button
          IconButton(
            icon: Icon(Icons.logout, color: AppColors.primary),
            onPressed: _logout, // Call method from State class
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.surface,
            ],
            stops: [0.0, 0.6],
          ),
        ),
        // Handle the initial loading of the profile
        child: profileAsyncValue.when(
          data: (profile) {
            // Initialize the notifier state when the profile data is first loaded
            // Use addPostFrameCallback to avoid calling during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return; // Check mounted before accessing state/notifier
                // Check if the notifier's initialProfile ID is different from the loaded profile ID
                // This prevents re-initialization on every rebuild if the profile hasn't changed.
                if (ref.read(profileEditProvider).initialProfile?.id != profile.id) {
                    // Read notifier again inside callback if needed
                    ref.read(profileEditProvider.notifier).initialize(profile);
                }

                // Update TextEditingControllers only if their text doesn't match the current edit state
                // This prevents cursor jumping during typing.
                 final currentEditState = ref.read(profileEditProvider); // Read latest state
                if (_nameController.text != currentEditState.name) _nameController.text = currentEditState.name;
                if (_bioController.text != currentEditState.bio) _bioController.text = currentEditState.bio;
                if (_locationController.text != currentEditState.location) _locationController.text = currentEditState.location;
                if (_occupationController.text != currentEditState.occupation) _occupationController.text = currentEditState.occupation;
            });

            final isSaving = editState.saveState is AsyncLoading;
            // --- NEW: Calculate completeness ---
            final double completeness = _calculateProfileCompleteness(editState);
            // --- End of completeness calculation ---

            // Build the main UI using the editState
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0), // Adjust padding if needed with Cards
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- NEW: Completeness Indicator ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0, left: 8.0, right: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Completeness: ${(completeness * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.8)
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: completeness,
                              backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // --- End Completeness Indicator ---

                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          // Wrap avatar in GestureDetector for tap-to-view
                          GestureDetector(
                            onTap: () {
                              // Get the image provider based on current state
                              ImageProvider? imageProvider;
                              if (editState.pickedImageFile != null) {
                                imageProvider = FileImage(File(editState.pickedImageFile!.path));
                              } else if (profile.photoUrls != null && profile.photoUrls!.isNotEmpty) {
                                imageProvider = NetworkImage(profile.photoUrls!.first);
                              }

                              if (imageProvider != null) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      backgroundColor: Colors.transparent,
                                      insetPadding: EdgeInsets.all(10),
                                      child: InteractiveViewer( // Allows zoom/pan
                                        panEnabled: true, 
                                        minScale: 0.5,
                                        maxScale: 4.0, 
                                        child: AspectRatio(
                                          aspectRatio: 1, // Assuming square aspect ratio for simplicity
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(16),
                                              image: DecorationImage(
                                                image: imageProvider!,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                            },
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: AppColors.primaryLight.withOpacity(0.5),
                              backgroundImage: editState.pickedImageFile != null
                                  ? FileImage(File(editState.pickedImageFile!.path)) as ImageProvider // Show picked image
                                  : (profile.photoUrls != null && profile.photoUrls!.isNotEmpty // Fallback to profile URL
                                      ? NetworkImage(profile.photoUrls!.first)
                                      : AssetImage('assets/images/placeholder_avatar.png')) as ImageProvider, // Fallback to placeholder
                            ),
                          ),
                          // Edit button (already wrapped with AnimatedTapFeedback)
                          AnimatedTapFeedback(
                            onTap: _pickImage,
                            child: Material(
                              color: AppColors.primary,
                              shape: CircleBorder(),
                              elevation: 2.0,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                          // --- NEW: Verify Profile Button (Conditional) ---
                          if (!(editState.initialProfile?.isVerified ?? false))
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Center(
                                child: OutlinedButton.icon(
                                  icon: Icon(Icons.verified_user_outlined, color: AppColors.accent),
                                  label: const Text(
                                    'Verify Your Profile',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                                  ),
                                  onPressed: () {
                                    // TODO: Implement navigation to verification flow
                                    print("Verify Profile button pressed - Placeholder");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Profile Verification coming soon!'), duration: Duration(seconds: 2)),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppColors.accent.withOpacity(0.5)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  ),
                                ),
                              ),
                            ),
                          // Add extra spacing if button is shown
                          if (!(editState.initialProfile?.isVerified ?? false))
                            const SizedBox(height: 16),
                          // --- End Verify Profile Button ---
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Basic Info Section Card ---
                    _buildSectionCard(
                      title: 'Basic Information',
                      children: [
                        // Custom row for Name + Verification Badge
                         Row(
                           children: [
                             Expanded(
                               child: _buildEditableTextField(
                                 controller: _nameController,
                                 label: 'Name',
                                 icon: Icons.person_outline,
                                 onChanged: editNotifier.updateName,
                               ),
                             ),
                             // Add verified badge if profile is verified
                             if (editState.initialProfile?.isVerified ?? false)
                               Padding(
                                 padding: const EdgeInsets.only(left: 8.0, top: 8.0), // Adjust padding as needed
                                 child: Tooltip(
                                    message: 'Verified Profile',
                                    child: Icon(Icons.verified, color: AppColors.accent, size: 24),
                                 ),
                               ),
                           ],
                         ),
                        const SizedBox(height: 12),
                        _buildDatePicker(editState.birthDate),
                        const SizedBox(height: 12),
                        _buildGenderSelector(editState.gender),
                      ]
                    ),
                    const SizedBox(height: 24), // Spacing between cards

                    // --- About Me Section Card ---
                    _buildSectionCard(
                      title: 'About Me',
                      children: [
                         _buildEditableTextField(
                          controller: _bioController,
                          label: 'Bio',
                          icon: Icons.edit_note_outlined,
                          maxLines: 4,
                          onChanged: editNotifier.updateBio,
                        ),
                        const SizedBox(height: 12),
                         _buildEditableTextField(
                            controller: _locationController,
                            label: 'Location',
                            icon: Icons.location_on_outlined,
                            onChanged: editNotifier.updateLocation,
                        ),
                        const SizedBox(height: 12),
                         _buildEditableTextField(
                            controller: _occupationController,
                            label: 'Occupation',
                            icon: Icons.work_outline,
                            onChanged: editNotifier.updateOccupation,
                        ),
                      ]
                    ),
                     const SizedBox(height: 24), // Spacing between cards

                    // --- Interests Section Card ---
                     _buildSectionCard(
                      title: 'Interests',
                      children: [
                        _buildInterestsSectionWidget(editState.interests), // Renamed helper
                      ]
                    ),
                    const SizedBox(height: 24), // Spacing between cards

                    // --- NEW: Prompts Section Card ---
                     _buildSectionCard(
                       title: 'My Answers', // Or 'Prompts'
                       children: [
                         _buildPromptsSectionWidget(editState.prompts), // NEW helper
                       ]
                     ),
                    const SizedBox(height: 24), // Spacing between cards

                    // --- NEW: AI Profile Tips Section Card ---
                     _buildSectionCard(
                       title: '✨ Profile Tips ✨', // Add some flair
                       children: [
                         _buildProfileTipsSectionWidget(), // NEW helper
                       ]
                     ),
                    const SizedBox(height: 32), // Keep spacing before error/save

                    // --- Error Message Display ---
                    if (editState.saveState is AsyncError)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          (editState.saveState as AsyncError).error.toString(),
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (editState.saveState is! AsyncError)
                       const SizedBox(height: 20),

                    // --- Save Button ---
                    Center(
                      child: AnimatedTapFeedback(
                        onTap: isSaving ? null : editNotifier.saveProfile,
                        child: ElevatedButton.icon(
                          onPressed: null,
                          icon: isSaving
                              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(Icons.save_outlined),
                          label: Text(isSaving ? 'Saving...' : 'Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
          loading: () => Center(
            child: LoadingIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: ErrorDisplay(
              message: 'Failed to load profile: ${error.toString()}',
              onRetry: () => ref.refresh(userProfileProvider),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets (now part of State class, no need for ref passing) ---

  // NEW: Helper widget to build sections within Cards
  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2.0, // Subtle elevation
      margin: const EdgeInsets.symmetric(vertical: 8.0), // Vertical margin for cards
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0), // Rounded corners for card
      ),
      color: Colors.white.withOpacity(0.9), // Slightly transparent white card
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(title), // Reuse existing header style
            const SizedBox(height: 8), // Space after header inside card
            ...children, // Add the fields for this section
          ],
        ),
      ),
    );
  }

  // _buildSectionHeader remains mostly the same, maybe adjust padding if needed
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0), // Adjusted padding
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
             color: AppColors.textPrimary.withOpacity(0.9)
        ) ?? TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary.withOpacity(0.9),
        ),
      ),
    );
  }

  // _buildEditableTextField remains the same
  Widget _buildEditableTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.primary),
          filled: true,
          fillColor: Colors.white.withOpacity(0.7), // Slightly more opaque inside card?
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(12),
             borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
        ),
        onChanged: onChanged,
      ),
    );
  }

  // _buildDatePicker remains the same
  Widget _buildDatePicker(DateTime currentBirthDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: currentBirthDate,
            firstDate: DateTime(1920),
            lastDate: DateTime.now().subtract(Duration(days: 365 * 18)),
             builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                       primary: AppColors.primary,
                       onPrimary: Colors.white,
                       onSurface: AppColors.textPrimary,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
          );
          if (picked != null && picked != currentBirthDate) {
             // Use ref from State class
             ref.read(profileEditProvider.notifier).updateBirthDate(picked);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Birth Date',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.primary),
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
             contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
          ),
          child: Text(
            "${currentBirthDate.toLocal()}".split(' ')[0],
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
        ),
      ),
    );
  }

 // _buildGenderSelector remains the same
 Widget _buildGenderSelector(String currentGender) {
    List<String> genders = ['male', 'female', 'other'];
    return Padding(
       padding: const EdgeInsets.symmetric(vertical: 6.0),
       child: InputDecorator(
          decoration: InputDecoration(
             labelText: 'Gender',
             labelStyle: TextStyle(color: AppColors.textSecondary),
             prefixIcon: Icon(Icons.wc_outlined, color: AppColors.primary),
             filled: true,
             fillColor: Colors.white.withOpacity(0.7),
             border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
             ),
             contentPadding: EdgeInsets.zero,
          ),
          child: DropdownButtonHideUnderline(
             child: DropdownButton<String>(
                // Ensure the value exists in the items list or handle null/default
                value: genders.contains(currentGender) ? currentGender : genders.first,
                isExpanded: true,
                icon: Padding(
                   padding: const EdgeInsets.only(right: 12.0),
                   child: Icon(Icons.arrow_drop_down, color: AppColors.textPrimary),
                ),
                elevation: 2,
                 style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                dropdownColor: Colors.white,
                items: genders.map<DropdownMenuItem<String>>((String value) {
                   return DropdownMenuItem<String>(
                      value: value,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(value[0].toUpperCase() + value.substring(1)),
                      ),
                   );
                }).toList(),
                onChanged: (String? newValue) {
                   if (newValue != null) {
                      // Use ref from State class
                       ref.read(profileEditProvider.notifier).updateGender(newValue);
                   }
                },
             ),
          ),
       ),
    );
 }


 // Renamed helper for clarity, contains the Wrap and TextField for interests
  Widget _buildInterestsSectionWidget(List<String> currentInterests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add a bit more space if needed
        if (currentInterests.isEmpty)
           Padding(
             padding: const EdgeInsets.only(bottom: 8.0),
             child: Text("Add some interests!", style: TextStyle(color: AppColors.textHint)),
           ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0, // Increased run spacing for badges
          children: currentInterests.map((interest) => InterestBadge(
            interest: interest,
            // Pass the remove function to the badge's onDeleted
            onDeleted: () => _removeInterest(interest),
          )).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _interestController,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Add an interest (e.g., Hiking)',
            hintStyle: TextStyle(color: AppColors.textHint),
             prefixIcon: Icon(Icons.interests_outlined, color: AppColors.primary),
             filled: true,
             // Ensure consistent field background
             fillColor: Colors.white.withOpacity(0.7),
             border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
             ),
             focusedBorder: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(12),
                 borderSide: BorderSide(color: AppColors.primary, width: 1.5),
             ),
             contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
            suffixIcon: IconButton(
              icon: Icon(Icons.add_circle_outline, color: AppColors.primary),
              onPressed: _addInterest,
            ),
          ),
          onSubmitted: (_) => _addInterest(),
        ),
      ],
    );
  }

  // --- NEW: Widget for Prompts Section ---
  Widget _buildPromptsSectionWidget(List<ProfilePrompt> currentPrompts) {
    final editNotifier = ref.read(profileEditProvider.notifier);

    // Define a list of available prompts (could come from backend later)
    final List<String> availablePrompts = [
      "Two truths and a lie...",
      "My most controversial opinion is...",
      "I'm looking for...",
      "A random fact I love is...",
      "The key to my heart is...",
      "My simple pleasures...",
      "I geek out on...",
      "My favorite quality in a person...",
      "I won't shut up about...",
    ];

    // Filter out prompts already used
    final promptsToShow = availablePrompts
        .where((q) => !currentPrompts.any((p) => p.question == q))
        .toList();

    // Function to show the prompt selection dialog
    void _showPromptSelectionDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Choose a Prompt'),
            content: SingleChildScrollView(
              child: ListBody(
                children: promptsToShow.map((promptQuestion) {
                  return ListTile(
                    title: Text(promptQuestion),
                    onTap: () {
                      editNotifier.addPrompt(ProfilePrompt(question: promptQuestion, answer: ''));
                      Navigator.of(context).pop(); // Close the dialog
                      // Optionally open edit dialog immediately?
                    },
                  );
                }).toList(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }

    // Function to show the answer editing dialog
    void _showAnswerEditDialog(int index, ProfilePrompt prompt) {
      final answerController = TextEditingController(text: prompt.answer);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(prompt.question), // Show question as title
            content: TextField(
              controller: answerController,
              autofocus: true,
              maxLines: null, // Allows multi-line input
              decoration: InputDecoration(
                hintText: 'Your answer...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text('Save'),
                onPressed: () {
                  editNotifier.updatePromptAnswer(index, answerController.text);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    // Build the list of prompt widgets
    List<Widget> promptWidgets = [];
    for (int i = 0; i < 3; i++) { // Limit to 3 prompts
      if (i < currentPrompts.length) {
        // Display existing prompt
        final prompt = currentPrompts[i];
        promptWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              onTap: () => _showAnswerEditDialog(i, prompt),
              child: Container(
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: AppColors.primaryLight.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            prompt.question,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary.withOpacity(0.8),
                              fontSize: 15
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: Colors.grey[600]),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          tooltip: 'Remove Prompt',
                          onPressed: () => editNotifier.removePrompt(i),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      prompt.answer.isEmpty ? 'Tap to answer...' : prompt.answer,
                      style: TextStyle(
                        color: prompt.answer.isEmpty ? AppColors.textHint : AppColors.textPrimary,
                        fontSize: 16,
                        height: 1.4
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis, // Prevent long answers from overflowing
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else if (promptsToShow.isNotEmpty) {
        // Show 'Add Prompt' button if space available and prompts available
        promptWidgets.add(
          Center(
            child: OutlinedButton.icon(
              icon: Icon(Icons.add_circle_outline),
              label: Text("Add a Prompt Answer"),
              onPressed: _showPromptSelectionDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
          ),
        );
        break; // Only show one add button
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: promptWidgets,
    );
  }
  // --- End of Prompts Section Widget ---

  // --- NEW: Widget for Profile Optimization Tips ---
  Widget _buildProfileTipsSectionWidget() {
    // Watch the provider
    final tipsAsyncValue = ref.watch(profileOptimizationTipsProvider);

    return tipsAsyncValue.when(
       data: (tips) {
         if (tips.isEmpty) {
            return const Text("Looking good! No specific tips right now.", style: TextStyle(color: AppColors.textHint));
         }
         // Display tips as a list
         return Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: tips.map((tip) => Padding(
             padding: const EdgeInsets.only(bottom: 10.0),
             child: Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Icon(Icons.lightbulb_outline, size: 18, color: AppColors.accent.withOpacity(0.8)),
                 const SizedBox(width: 8),
                 Expanded(
                   child: Text(
                     tip,
                     style: TextStyle(
                       color: AppColors.textPrimary.withOpacity(0.9),
                       fontSize: 14,
                       height: 1.4,
                     ),
                   ),
                 ),
               ],
             ),
           )).toList(),
         );
       },
       loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          )
       ),
       error: (err, stack) => Center(
          child: Padding(
             padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text("Could not load profile tips.", style: TextStyle(color: Colors.orange[700]))
          )
       ),
    );
  }
  // --- End Profile Tips Widget ---
}

// TODO: Define AppColors in utils/colors.dart
// Example:
/*
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF4B6C);
  static const Color primaryLight = Color(0xFFFFE8EC);
  static const Color secondary = Color(0xFF4F4F4F); // Example secondary
  static const Color textDark = Color(0xFF2A2C36);
  static const Color textLight = Color(0xFF8A8A8F);
  static const Color backgroundLight = Color(0xFFFFF5F7);
  static const Color backgroundLighter = Color(0xFFF8F9FE);
  static const Color accent = Color(0xFF61DAFB); // Example accent
}
*/

// TODO: Define LoadingIndicator widget in widgets/loading_indicator.dart
// Example:
/*
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }
}
*/

// TODO: Define ErrorDisplay widget in widgets/error_display.dart
// Example:
/*
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorDisplay({Key? key, required this.message, this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
*/