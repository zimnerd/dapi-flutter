import 'package:flutter/material.dart';
import 'dart:convert'; // Keep only if used elsewhere
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
// Remove direct service imports if only used via providers
// import '../services/auth_service.dart';
// import '../services/chat_service.dart';
// import '../services/profile_service.dart'; 
import '../providers/auth_provider.dart'; // Keep for user/logout actions
import '../providers/discover_provider.dart'; // Import discover provider
import '../providers/profile_action_provider.dart'; // Import action provider (will create next)
import '../models/profile.dart';
import '../utils/colors.dart';
import '../utils/config.dart'; // Keep for config if needed
import '../models/conversation.dart'; // Keep if used directly
import 'conversation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/enhanced_profile_card.dart';
import 'dart:math';
import '../widgets/match_animation_dialog.dart';
import 'chat_screen.dart';
import '../services/chat_service.dart'; // Keep for chat service provider access
import '../widgets/profile_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_display.dart';
import '../widgets/animated_tap_feedback.dart';
import '../providers/providers.dart'; // Import for premiumProvider and profileServiceProvider
import '../providers/subscription_provider.dart'; // <-- Import premium provider
import 'package:flutter_card_swiper/flutter_card_swiper.dart'; // Use flutter_card_swiper instead of appinio_swiper
import 'package:flutter/services.dart'; // Import for HapticFeedback
import 'premium_screen.dart'; // FIX: Import PremiumScreen
import '../widgets/premium_feature_wrapper.dart'; // Import PremiumFeatureWrapper

// Enum to represent swipe direction for clarity
enum SwipeDirection { like, dislike, superLike }

// Class to hold last swipe information
class LastSwipeInfo {
  final Profile profile;
  final SwipeDirection direction;

  LastSwipeInfo({required this.profile, required this.direction});
}

// Change to ConsumerStatefulWidget
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);
  
  @override
  _DiscoverScreenState createState() => _DiscoverScreenState();
}

// Change to ConsumerState
class _DiscoverScreenState extends ConsumerState<DiscoverScreen> with SingleTickerProviderStateMixin {
  // Remove local state for profiles, loading, error as provider handles it
  // bool _isLoading = true; 
  // bool _isInitialLoading = true; 
  // List<Profile> _profiles = [];
  // String _errorMessage = '';
  
  int _currentIndex = 0; // Keep track of swipe index locally
  // bool _isRefreshing = false; // Refresh handled by provider .refresh()
  
  // Filter values (consider moving to a StateNotifier if complex)
  double _maxDistance = 50;
  RangeValues _ageRange = const RangeValues(18, 50);
  String _genderPreference = 'All';
  
  // Animation controller can remain local UI state
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Remove direct service instances
  // final AuthService _authService = AuthService(); 
  // final ChatService _chatService = ChatService();
  // final ProfileService _profileService = ProfileService();

  final CardSwiperController _swipeController = CardSwiperController();
  
  // NEW: State variable to store the last swiped profile info
  LastSwipeInfo? _lastSwipe;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Load initial filters, but profile loading is handled by the provider
    _loadFilters();
    // No need to call _loadProfiles() here
  }

  @override
  void dispose() {
    _animationController.dispose();
    _swipeController.dispose(); // Dispose the swipe controller
    super.dispose();
  }

  // Keep filter loading/saving logic for now
  Future<void> _loadFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _maxDistance = prefs.getDouble('maxDistance') ?? 50;
        _ageRange = RangeValues(
          prefs.getDouble('minAge') ?? 18,
          prefs.getDouble('maxAge') ?? 50,
        );
        _genderPreference = prefs.getString('genderPreference') ?? 'All';
      });
    } catch (e) {
      print('Error loading filters: $e');
    }
  }

  Future<void> _saveFilters() async {
     try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('maxDistance', _maxDistance);
      await prefs.setDouble('minAge', _ageRange.start);
      await prefs.setDouble('maxAge', _ageRange.end);
      await prefs.setString('genderPreference', _genderPreference);
    } catch (e) {
      print('Error saving filters: $e');
    }
  }

  // Remove _loadProfiles - Handled by discoverProfilesProvider
  // Future<void> _loadProfiles() async { ... }

  // Keep helper methods, but update to use services via ref
  // Future<List<String>> _getProfilePhotos(String profileId) async { ... }
  // Future<List<String>> _getProfileInterests(String profileId) async { ... }

  void _refreshProfiles() {
    setState(() {
      _currentIndex = 0;
      _lastSwipe = null;
    });
    ref.read(discoverProfilesProvider.notifier).refresh();
    print("Called discover provider refresh");
  }

  // Update handlers to use services via ref and pass profile
  Future<void> _handleLike(Profile profile) async {
    print("Handling Like for ${profile.name}");
    // Use the action provider
    final success = await ref.read(profileActionProvider.notifier).likeProfile(profile.id);
    if (success && mounted) {
      // Simulate match chance (can be removed if API handles matches)
      final bool isMatch = Random().nextDouble() < 0.2;
      if (isMatch) {
        await _showMatchAnimation(profile);
      }
    } else if (!success && mounted) {
      // Show error from the action provider state
      final error = ref.read(profileActionProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to like profile')),
      );
    }
  }
  
  Future<void> _handleDislike(Profile profile) async {
     print("Handling Dislike for ${profile.name}");
     final success = await ref.read(profileActionProvider.notifier).dislikeProfile(profile.id);
     if (!success && mounted) {
       final error = ref.read(profileActionProvider).errorMessage;
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(error ?? 'Failed to dislike profile')),
       );
     }
  }

  Future<void> _handleSuperLike(Profile profile) async {
    print("Handling Super Like for ${profile.name}");
     final success = await ref.read(profileActionProvider.notifier).superlikeProfile(profile.id);
     if (success && mounted) {
       // Simulate match chance
       final bool isMatch = Random().nextDouble() < 0.4;
       if (isMatch) {
         await _showMatchAnimation(profile);
       }
     } else if (!success && mounted) {
       final error = ref.read(profileActionProvider).errorMessage;
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(error ?? 'Failed to superlike profile')),
       );
     }
  }

  Future<void> _showMatchAnimation(Profile matchedProfile) async {
    final profileService = ref.read(profileServiceProvider);
    Profile? currentUserProfile;
    try {
      // Fetch current user profile using the service
      currentUserProfile = await profileService.getCurrentUserProfile();
    } catch (e) {
      print('⟹ [DiscoverScreen] Error getting current user profile for match: $e');
      // Use a more robust fallback or handle error differently
       currentUserProfile = Profile(
         id: 0,
         name: 'You',
         age: 0,
         gender: 'unknown',
         photoUrls: [],
         interests: [],
         birthDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
       );
    }
    
    if (!mounted) return;
    
    final chatService = ref.read(chatServiceProvider); // Get ChatService via provider

    return MatchAnimationDialog.show(
      context: context,
      userProfile: currentUserProfile!, // Ensure non-null
      matchProfile: matchedProfile,
      onContinue: () {
        Navigator.of(context).pop(); // Close dialog
      },
      onMessage: () async {
         Navigator.of(context).pop(); // Close dialog first
         try {
          // Pass profile to ChatScreen, it will handle conversation creation
           Navigator.of(context).push(
             MaterialPageRoute(
               builder: (context) => ChatScreen(matchProfile: matchedProfile),
             ),
           );
         } catch (e) {
            print('Error navigating to chat: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not start chat: ${e.toString()}')),
            );
         }
      },
    );
  }

  // Remove _getAuthHeaders - Dio interceptor handles this
  // Future<Map<String, String>> _getAuthHeaders() async { ... }

  // Remove _nextProfile - Card swiper package handles index
  // void _nextProfile() { ... }

  // Remove _showMatchDialog - Replaced by MatchAnimationDialog.show
  // void _showMatchDialog(Profile matchedProfile, {bool isSuperLike = false}) { ... }

  @override
  Widget build(BuildContext context) {
    // Watch the provider for discover profiles
    final discoverState = ref.watch(discoverProfilesProvider);
    final isPremium = ref.watch(premiumProvider); // Watch premium status
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discover',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // Refresh button (optional, provider handles reload on state change/pull-to-refresh)
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _refreshProfiles,
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: AppColors.primary),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      // Use AsyncValue.when to handle loading/error/data states
      body: Column(
        children: [
          // --- Filter UI (Example - keep or replace with your filter UI) ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Filters'), // Placeholder for filter button/display
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () { /* TODO: Show filter dialog */ },
                ),
                IconButton( // Refresh Button
                   icon: Icon(Icons.refresh),
                   onPressed: _refreshProfiles,
                   tooltip: 'Refresh Profiles',
                ),
              ],
            ),
          ),
          // --- Swiper Section ---
          Expanded(
            child: discoverState.profiles.when(
              data: (profiles) {
                if (profiles.isEmpty) {
                  return _buildEmptyView();
                }
                // Check if we've swiped past all loaded profiles
                if (_currentIndex >= profiles.length) {
                   return _buildNoMoreProfilesView();
                }
                // Start animation controller when data is ready
                _animationController.forward(); 
                return FadeTransition(
                  opacity: _fadeAnimation,
                  // Use EnhancedProfileCard which takes a list
                  child: EnhancedProfileCard(
                    profiles: profiles, // Pass the full list
                    initialIndex: _currentIndex, // Start from the current index
                    onLike: (profile) {
                      _handleLike(profile);
                      setState(() => _currentIndex++); // Increment local index on swipe
                    },
                    onDislike: (profile) {
                      _handleDislike(profile);
                       setState(() => _currentIndex++); 
                    },
                    onSuperLike: (profile) {
                      _handleSuperLike(profile);
                       setState(() => _currentIndex++); 
                    },
                    showActions: true,
                    onStackFinished: () {
                      print("Stack finished");
                      // Optionally trigger a refresh when stack is empty
                       setState(() {
                         _currentIndex = profiles.length; // Mark as finished
                       });
                       _refreshProfiles(); // Auto-refresh when stack is done
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Finding people near you...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              error: (error, stackTrace) {
                 print("Error loading profiles: $error\n$stackTrace");
                 return _buildErrorView(error.toString()); // Pass error message
              },
            ),
          ),
          // --- Action Buttons ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Undo Button - Wrapped with PremiumFeatureWrapper
                AnimatedTapFeedback(
                  onTap: discoverState.lastRemovedProfile != null
                      ? _handleUndoSwipe // Enable only if there's something to undo
                      : null,
                  child: PremiumFeatureWrapper(
                    featureName: 'Undo Last Swipe',
                    description: 'Changed your mind? Go back to profiles you accidentally passed.',
                    icon: Icons.undo,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: discoverState.lastRemovedProfile != null
                          ? AppColors.secondary.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.1),
                      child: Icon(
                        Icons.undo,
                        color: discoverState.lastRemovedProfile != null
                            ? AppColors.secondary
                            : Colors.grey,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                // Dislike Button
                AnimatedTapFeedback(
                  onTap: () => _swipeController.swipe(CardSwiperDirection.left),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.redAccent.withOpacity(0.15),
                    child: Icon(Icons.close, color: Colors.redAccent, size: 35),
                  ),
                ),
                // Super Like Button - Wrapped with PremiumFeatureWrapper
                AnimatedTapFeedback(
                  onTap: () => _swipeController.swipe(CardSwiperDirection.top),
                  child: PremiumFeatureWrapper(
                    featureName: 'Super Like',
                    description: 'Stand out from others by showing your special interest.',
                    icon: Icons.star,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.accent.withOpacity(0.15),
                      child: Icon(Icons.star, color: AppColors.accent, size: 28),
                    ),
                  ),
                ),
                // Like Button
                AnimatedTapFeedback(
                  onTap: () => _swipeController.swipe(CardSwiperDirection.right),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.green.withOpacity(0.15),
                    child: Icon(Icons.favorite, color: Colors.green, size: 35),
                  ),
                ),
                // Info/Profile Details Button (Example)
                AnimatedTapFeedback(
                  onTap: () {
                    // TODO: Implement action to show detailed profile view
                    print("Info button tapped");
                    final currentProfiles = ref.read(discoverProfilesProvider).profiles.valueOrNull;
                    if (currentProfiles != null && currentProfiles.isNotEmpty && _currentIndex < currentProfiles.length) {
                      final currentProfile = currentProfiles[_currentIndex];
                      _showProfileDetails(context, currentProfile);
                    }
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight.withOpacity(0.5),
                    child: Icon(Icons.info_outline, color: AppColors.primary, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Keep UI building helpers, update error view to accept message
  Widget _buildErrorView(String errorMessage) {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 70,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Oops!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              errorMessage, // Show the actual error
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshProfiles,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No one nearby',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'We couldn\'t find anyone matching your preferences. Try adjusting your filters or check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showFilterDialog(context);
            },
            icon: const Icon(Icons.tune),
            label: const Text('Adjust Filters'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMoreProfilesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.done_all,
            size: 80,
            color: AppColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'You\'ve seen everyone matching your preferences. Check back later for new people.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshProfiles,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    // Use the instance variables for the filters
    double distanceValue = _maxDistance;
    RangeValues ageRange = _ageRange;
    String selectedGender = _genderPreference;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Distance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: distanceValue,
                          min: 1,
                          max: 100,
                          divisions: 99,
                          activeColor: AppColors.primary,
                          label: '${distanceValue.round()} km',
                          onChanged: (value) {
                            setState(() {
                              distanceValue = value;
                            });
                          },
                        ),
                      ),
                      Text(
                        '${distanceValue.round()} km',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Age Range',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RangeSlider(
                          values: ageRange,
                          min: 18,
                          max: 100,
                          divisions: 82,
                          activeColor: AppColors.primary,
                          labels: RangeLabels(
                            '${ageRange.start.round()}',
                            '${ageRange.end.round()}',
                          ),
                          onChanged: (values) {
                            setState(() {
                              ageRange = values;
                            });
                          },
                        ),
                      ),
                      Text(
                        '${ageRange.start.round()} - ${ageRange.end.round()}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Show me',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Women', 'Men', 'All'].map((gender) {
                      return ChoiceChip(
                        label: Text(gender),
                        selected: selectedGender == gender,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selectedGender == gender ? Colors.white : AppColors.textPrimary,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            selectedGender = gender;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      // Save the new filter values
                      this._maxDistance = distanceValue;
                      this._ageRange = ageRange;
                      this._genderPreference = selectedGender;
                      
                      // Save filters to SharedPreferences
                      _saveFilters();
                      
                      Navigator.pop(context);
                      // Apply filters and reload profiles
                      _refreshProfiles();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Swipe handler - central place to record last swipe
  void _swipeProfile(int index, CardSwiperDirection direction) {
    // Read the profiles list currently held by the provider
    final profiles = ref.read(discoverProfilesProvider).profiles.valueOrNull ?? [];
    if (index >= profiles.length) return; // Safety check

    final swipedProfile = profiles[index];
    SwipeDirection swipeDirection;

    switch (direction) {
      case CardSwiperDirection.right:
         print("Swiped Right on ${swipedProfile.name}");
         swipeDirection = SwipeDirection.like;
         _handleLike(swipedProfile); // Keep existing handler call
        break;
      case CardSwiperDirection.left:
         print("Swiped Left on ${swipedProfile.name}");
         swipeDirection = SwipeDirection.dislike;
         _handleDislike(swipedProfile); // Keep existing handler call
        break;
      case CardSwiperDirection.top:
         print("Swiped Top (Super Like) on ${swipedProfile.name}");
          swipeDirection = SwipeDirection.superLike;
         _handleSuperLike(swipedProfile); // Keep existing handler call
        break;
      case CardSwiperDirection.bottom:
         print("Swiped Bottom (not implemented)");
         // If bottom swipe isn't used, we might not need to store it,
         // or assign a specific direction if it represents an action.
         return; // Don't store if it's not a primary action
      case CardSwiperDirection.none:
         print("No swipe direction (not implemented)");
         return; // Don't store if no direction
    }

    // Store the swipe info BEFORE the state potentially changes/profile removed
     setState(() {
       _lastSwipe = LastSwipeInfo(profile: swipedProfile, direction: swipeDirection);
       print("Stored last swipe: ${_lastSwipe?.profile.name} - ${_lastSwipe?.direction}");
     });

     // Note: The actual removal of the card from UI is handled by the swiper package
     // and the backend interaction happens in the _handleLike/Dislike/SuperLike methods.
  }

   // Method to handle the undo action
   Future<void> _handleUndoSwipe() async {
     final isPremium = ref.read(premiumProvider);
     if (!isPremium) {
       // Premium check is now handled by PremiumFeatureWrapper
       return;
     }
     
     final success = await ref.read(discoverProfilesProvider.notifier).undoLastSwipe();
     if (success) {
       // Trigger the swiper to go back one step
       _swipeController.undo();
       print("Undo successful, triggering swiper unswipe.");
     } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Nothing to undo.'), duration: Duration(seconds: 2)),
       );
     }
   }

  // Helper function to show profile details (example)
  void _showProfileDetails(BuildContext context, Profile profile) {
     // Implement how you want to show details, e.g., using a BottomSheet
     showModalBottomSheet(
        context: context,
        isScrollControlled: true, // Allows taller sheet
        builder: (context) {
           return DraggableScrollableSheet(
              expand: false, // Don't expand fully initially
              initialChildSize: 0.7, // Start at 70% height
              maxChildSize: 0.95, // Allow dragging up to 95%
              minChildSize: 0.4, // Minimum size
              builder: (_, controller) {
                 // Replace with your actual ProfileDetailsScreen or widget
                 return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                       color: Theme.of(context).canvasColor,
                       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ListView(
                      controller: controller,
                      children: [
                         Text(profile.name, style: Theme.of(context).textTheme.headlineSmall),
                         SizedBox(height: 8),
                         Text("Age: ${profile.age}"),
                         SizedBox(height: 8),
                         Text("Bio: ${profile.bio ?? 'N/A'}"),
                         SizedBox(height: 16),
                         // Add more profile details here...
                      ],
                    ),
                 );
              },
           );
        },
     );
  }
} 