import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/profile.dart';
import '../providers/profile_provider.dart'
    show profileServiceProvider, storageServiceProvider, userProfileProvider;
import 'home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart'; // Import centralized providers
import '../providers/profile_provider.dart';

class ProfileCreationScreen extends ConsumerStatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  _ProfileCreationScreenState createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends ConsumerState<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _occupationController = TextEditingController();
  DateTime? _selectedBirthDate;
  String _selectedGender = 'Prefer not to say';
  final List<XFile> _selectedPhotos = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  String _location = '';
  String _errorMessage = '';
  bool _agreedToGuidelines = false;

  // Interest selection
  final List<String> _availableInterests = [
    'Hiking',
    'Reading',
    'Cooking',
    'Travel',
    'Photography',
    'Movies',
    'Music',
    'Sports',
    'Art',
    'Technology',
    'Fitness',
    'Dancing',
    'Gaming',
    'Yoga',
    'Meditation',
  ];
  final List<String> _selectedInterests = [];

  // Preference settings
  RangeValues _ageRangeValues = RangeValues(18, 50);
  double _maxDistance = 30;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedPhotos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can select a maximum of 5 photos.')),
      );
      return;
    }
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedPhotos.add(pickedFile);
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedBirthDate ??
            DateTime.now().subtract(Duration(days: 365 * 18)),
        firstDate: DateTime(1920, 1),
        lastDate: DateTime.now().subtract(Duration(days: 365 * 18)));
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate() ||
        _selectedBirthDate == null ||
        _selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please complete all fields and add at least one photo.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = ref.read(userIdProvider);
      if (userId == null) {
        throw Exception('User not logged in.');
      }

      int age = Profile.calculateAge(_selectedBirthDate!);

      final profile = Profile(
        id: userId,
        name: _nameController.text,
        gender: _selectedGender,
        birthDate: _selectedBirthDate!,
        prompts: [],
        bio: _bioController.text,
        interests: _selectedInterests.toList(),
        photoUrls: _selectedPhotos.map((photo) => photo.path).toList(),
        location: {
          'city': _location,
          'country': 'Unknown', // You might want to add country selection
        },
        profilePictures: _selectedPhotos.map((photo) => photo.path).toList(),
        isPremium: false,
        lastActive: DateTime.now(),
      );

      final profileService = ref.read(profileServiceProvider);
      final storageService = ref.read(storageServiceProvider);

      List<String> uploadedPhotoUrls = [];
      for (var photoFile in _selectedPhotos) {
        final url = await storageService.uploadProfileImage(photoFile, userId);
        uploadedPhotoUrls.add(url);
      }

      final profileData = profile.toJson();
      profileData['photoUrls'] = uploadedPhotoUrls;
      profileData.remove('id');
      profileData.remove('age');

      await profileService.createProfile(profileData);

      ref.invalidate(userProfileProvider);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Profile'),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Custom step indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStepCircle(0, 'Basic Info'),
                          _buildStepLine(0),
                          _buildStepCircle(1, 'Photos'),
                          _buildStepLine(1),
                          _buildStepCircle(2, 'Interests'),
                          _buildStepLine(2),
                          _buildStepCircle(3, 'Preferences'),
                          _buildStepLine(3),
                          _buildStepCircle(4, 'Guidelines'),
                        ],
                      ),
                    ),

                    // Step content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: IndexedStack(
                          index: 0,
                          children: [
                            _buildBasicInfoStep(),
                            _buildPhotosStep(),
                            _buildInterestsStep(),
                            _buildPreferencesStep(),
                            _buildRulesOfEngagementStep(),
                          ],
                        ),
                      ),
                    ),

                    // Navigation buttons
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submitProfile,
                              child: Text('FINISH'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStepCircle(int step, String title) {
    bool isActive = 0 >= step;
    bool isCurrent = 0 == step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCurrent
                ? Theme.of(context).colorScheme.primary
                : isActive
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                    : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    bool isActive = 0 > step;

    return Expanded(
      child: Container(
        height: 2,
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Birth Date',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              _selectedBirthDate == null
                  ? 'Select your birth date'
                  : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}',
            ),
          ),
        ),
        if (_selectedBirthDate == null)
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 8.0),
            child: Text(
              'Birth date is required',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        SizedBox(height: 16),
        Text('I identify as:', style: Theme.of(context).textTheme.titleMedium),
        RadioListTile<String>(
          title: Text('Man'),
          value: 'male',
          groupValue: _selectedGender,
          onChanged: (value) {
            setState(() {
              _selectedGender = value!;
            });
          },
        ),
        RadioListTile<String>(
          title: Text('Woman'),
          value: 'female',
          groupValue: _selectedGender,
          onChanged: (value) {
            setState(() {
              _selectedGender = value!;
            });
          },
        ),
        RadioListTile<String>(
          title: Text('Non-binary'),
          value: 'non-binary',
          groupValue: _selectedGender,
          onChanged: (value) {
            setState(() {
              _selectedGender = value!;
            });
          },
        ),
        RadioListTile<String>(
          title: Text('Other'),
          value: 'other',
          groupValue: _selectedGender,
          onChanged: (value) {
            setState(() {
              _selectedGender = value!;
            });
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _occupationController,
          decoration: InputDecoration(
            labelText: 'Occupation',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.work),
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          decoration: InputDecoration(
            labelText: 'Bio',
            border: OutlineInputBorder(),
            helperText: 'Tell potential matches about yourself',
            prefixIcon: Icon(Icons.edit),
          ),
          maxLines: 3,
          maxLength: 300,
        ),
      ],
    );
  }

  Widget _buildPhotosStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add your photos',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 8),
        Text(
          'Add at least 1 photo to continue (up to 6)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: min(6, _selectedPhotos.length + 1),
          itemBuilder: (context, index) {
            if (index == _selectedPhotos.length && _selectedPhotos.length < 6) {
              return InkWell(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              );
            } else {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(_selectedPhotos[index].path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
        SizedBox(height: 16),
        if (_selectedPhotos.isEmpty)
          Text(
            'Please add at least one photo',
            style: TextStyle(color: Colors.red),
          ),
        SizedBox(height: 8),
        Text(
          'Tips:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 4),
        Text('• Clear face photos get more matches'),
        Text('• Add photos of you doing activities you enjoy'),
        Text('• Group photos are okay, but make sure we can identify you'),
      ],
    );
  }

  Widget _buildInterestsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your interests',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 8),
        Text(
          'Choose at least 3 interests that define you',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableInterests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (_) => _toggleInterest(interest),
              selectedColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        if (_selectedInterests.length < 3)
          Text(
            'Please select at least 3 interests',
            style: TextStyle(color: Colors.red),
          ),
      ],
    );
  }

  Widget _buildPreferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set your preferences',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        Text(
          'Age Range: ${_ageRangeValues.start.round()} - ${_ageRangeValues.end.round()} years',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        RangeSlider(
          values: _ageRangeValues,
          min: 18,
          max: 70,
          divisions: 52,
          labels: RangeLabels(
            '${_ageRangeValues.start.round()}',
            '${_ageRangeValues.end.round()}',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _ageRangeValues = values;
            });
          },
        ),
        SizedBox(height: 24),
        Text(
          'Maximum Distance: ${_maxDistance.round()} km',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: _maxDistance,
          min: 5,
          max: 100,
          divisions: 19,
          label: '${_maxDistance.round()} km',
          onChanged: (double value) {
            setState(() {
              _maxDistance = value;
            });
          },
        ),
        SizedBox(height: 24),
        TextFormField(
          initialValue: _location,
          decoration: InputDecoration(
            labelText: 'Location',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
            helperText: 'Enter your city or enable location services',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your city or enable location services';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _location = value;
            });
          },
        ),
        SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            icon: Icon(Icons.my_location),
            label: Text('Use Current Location'),
            onPressed: () {
              setState(() {
                _location = 'Current Location (Placeholder)';
                _errorMessage = '';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Location fetching not implemented yet.')),
              );
            },
          ),
        ),
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              _errorMessage,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildRulesOfEngagementStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community Guidelines',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        _buildGuidelineItem(
          icon: Icons.verified_user,
          title: 'Be Authentic',
          description:
              'Use recent photos and be honest in your profile. Authenticity builds trust.',
        ),
        SizedBox(height: 16),
        _buildGuidelineItem(
          icon: Icons.security,
          title: 'Stay Safe',
          description:
              'Meet in public places first. Let someone know where you\'re going.',
        ),
        SizedBox(height: 16),
        _buildGuidelineItem(
          icon: Icons.sentiment_satisfied_alt,
          title: 'Be Respectful',
          description:
              'Treat others as you wish to be treated. Respect boundaries and consent.',
        ),
        SizedBox(height: 16),
        _buildGuidelineItem(
          icon: Icons.message,
          title: 'Communicate Clearly',
          description: 'Be honest about your intentions and expectations.',
        ),
        SizedBox(height: 16),
        _buildGuidelineItem(
          icon: Icons.thumb_down_off_alt,
          title: 'Zero Tolerance for Harassment',
          description:
              'Unsolicited messages, hate speech, and discrimination are not allowed.',
        ),
        SizedBox(height: 24),
        CheckboxListTile(
          title: Text('I agree to follow these community guidelines'),
          value: _agreedToGuidelines,
          onChanged: (value) {
            setState(() {
              _agreedToGuidelines = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildGuidelineItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 4),
              Text(description),
            ],
          ),
        ),
      ],
    );
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }
}
