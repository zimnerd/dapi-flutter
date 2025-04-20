import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/profile_service.dart';
import '../../providers/providers.dart';
import '../../utils/colors.dart';
import '../../models/profile.dart';

// Define the profile provider
final profileProvider = Provider<ProfileService>((ref) {
  return ref.watch(profileServiceProvider);
});

class ProfileCreationScreen extends ConsumerStatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  ConsumerState<ProfileCreationScreen> createState() =>
      _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends ConsumerState<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  String _selectedGender = 'prefer not to say';
  final List<String> _selectedInterests = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profileService = ref.read(profileProvider);
      final userId = ref.read(userIdProvider);

      if (userId == null) {
        throw Exception('User ID not available. Please log in again.');
      }

      // Create profile data from form
      final profileData = {
        'name': _nameController.text,
        'bio': _bioController.text,
        'gender': _selectedGender,
        'interests': _selectedInterests,
      };

      // Submit profile data with user ID
      await profileService.createProfile(profileData);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate to next screen on success
        Navigator.pushReplacementNamed(context, '/profile');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to create profile: ${e.toString()}';
        });
      }
    }
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter your name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Bio field
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell us about yourself',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Gender selection
                    Text(
                      'Gender',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        'male',
                        'female',
                        'non-binary',
                        'prefer not to say',
                      ]
                          .map((gender) => ChoiceChip(
                                label: Text(gender),
                                selected: _selectedGender == gender,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedGender = gender;
                                    });
                                  }
                                },
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),

                    // Interests selection
                    Text(
                      'Interests',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        'Travel',
                        'Music',
                        'Fitness',
                        'Reading',
                        'Cooking',
                        'Art',
                        'Movies',
                        'Gaming',
                        'Sports',
                        'Technology',
                      ]
                          .map((interest) => FilterChip(
                                label: Text(interest),
                                selected: _selectedInterests.contains(interest),
                                onSelected: (_) => _toggleInterest(interest),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Create Profile',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
