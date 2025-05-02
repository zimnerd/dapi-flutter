import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

// Import required models
import '../models/profile.dart';

// Import providers from central providers file
import '../providers/providers.dart';
import '../providers/discover_provider.dart';
import '../providers/profile_action_provider.dart';
import '../providers/profile_filters_provider.dart';

// Import config and utils
import '../config/app_config.dart';
import '../utils/colors.dart';
import '../utils/logger.dart';

// Import screens and widgets
import '../screens/chat_screen.dart';
import '../widgets/match_animation_dialog.dart';
import '../widgets/enhanced_profile_card.dart';

// Define SwipeDirection enum
enum SwipeDirection { like, dislike, superLike }

// Define LastSwipeInfo class
class LastSwipeInfo {
  final Profile profile;
  final SwipeDirection direction;

  const LastSwipeInfo({required this.profile, required this.direction});
}

// Create a logger instance for this screen
final logger = Logger('DiscoverScreen');

// CardSwiperDirection and CardSwiperController are provided by the flutter_card_swiper package

// Change to ConsumerStatefulWidget
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

// Change to ConsumerState
class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  // Remove local state for profiles, loading, error as provider handles it
  // bool _isLoading = true;
  // bool _isInitialLoading = true;
  // List<Profile> _profiles = [];
  // String _errorMessage = '';

  int _currentIndex = 0; // Keep track of swipe index locally
  // bool _isRefreshing = false; // Refresh handled by provider .refresh()

  // Update filter values to use AppConfig constants
  double _maxDistance = AppConfig.maxDistance;
  RangeValues _ageRange =
      RangeValues(AppConfig.minAge.toDouble(), AppConfig.maxAge.toDouble());
  String _genderPreference = 'All';

  // Animation controller can remain local UI state
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Filter listener

  // Remove direct service instances
  // final AuthService _authService = AuthService();
  // final ChatService _chatService = ChatService();
  // final ProfileService _profileService = ProfileService();

  final CardSwiperController _swipeController = CardSwiperController();

  // NEW: State variable to store the last swiped profile info
  // LastSwipeInfo? _lastSwipe;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    logger.info("DiscoverScreen initState called");

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    // Load initial filters, but profile loading is handled by the provider
    logger.info("Loading initial filters");
    _loadFilters();

    // Listen for filter changes
    Future.microtask(() {
      if (mounted) {
        logger.info("Scheduling auto-login with Future.microtask");
        _autoLogin();
      }
    });

    logger.info("DiscoverScreen initialization complete");
  }

  @override
  void dispose() {
    logger.info("DiscoverScreen dispose called");
    _animationController.dispose();
    _swipeController.dispose(); // Dispose the swipe controller
    // Filter listener disposed automatically
    super.dispose();
  }

  // Keep filter loading/saving logic for now
  Future<void> _loadFilters() async {
    logger.info("Loading filters from SharedPreferences");
    try {
      final prefs = await SharedPreferences.getInstance();
      logger.info("SharedPreferences instance obtained");
      setState(() {
        _maxDistance = prefs.getDouble('maxDistance') ?? 50;
        _ageRange = RangeValues(
          prefs.getDouble('minAge') ?? 18,
          prefs.getDouble('maxAge') ?? 50,
        );
        _genderPreference = prefs.getString('genderPreference') ?? 'All';
      });
      logger.info(
          "Filters loaded: maxDistance=$_maxDistance, ageRange=${_ageRange.start}-${_ageRange.end}, gender=$_genderPreference");
    } catch (e) {
      logger.error("Error loading filters: $e");
    }
  }

  Future<void> _saveFilters() async {
    logger.info("Saving filters to SharedPreferences");
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('maxDistance', _maxDistance);
      await prefs.setDouble('minAge', _ageRange.start);
      await prefs.setDouble('maxAge', _ageRange.end);
      await prefs.setString('genderPreference', _genderPreference);
      logger.info("Filters saved to SharedPreferences");

      // Also update the provider state
      logger.info("Updating profile filters provider");
      ref.read(profileFiltersProvider.notifier).updateFilters(
            maxDistance: _maxDistance,
            ageRange: _ageRange,
            genderPreference: _genderPreference,
          );
    } catch (e) {
      logger.error("Error saving filters: $e");
    }
  }

  // Method to sync local state with provider state
  // void _syncFiltersWithProvider() { ... }

  // Remove _loadProfiles - Handled by discoverProfilesProvider
  // Future<void> _loadProfiles() async { ... }

  // Keep helper methods, but update to use services via ref
  // Future<List<String>> _getProfilePhotos(String profileId) async { ... }
  // Future<List<String>> _getProfileInterests(String profileId) async { ... }

  void _refreshProfiles() {
    logger.info("Refreshing discover profiles");
    setState(() {
      _currentIndex = 0;
    });
    ref.read(discoverProfilesProvider.notifier).refresh();
    logger.info("Discover provider refresh called");
  }

  // Update handlers to use services via ref and pass profile
  Future<void> _handleLike(Profile profile) async {
    logger.info("Handling Like for ${profile.name} (ID: ${profile.id})");
    // Use the action provider
    try {
      final success = await ref
          .read(profileActionProvider.notifier)
          .likeProfile(profile.id);
      logger.info("Like operation result: $success");

      if (success && mounted) {
        // Simulate match chance (can be removed if API handles matches)
        final bool isMatch = Random().nextDouble() < 0.2;
        logger.info("Match simulation result: $isMatch");
        if (isMatch) {
          await _showMatchAnimation(profile);
        }
      } else if (!success && mounted) {
        // Show error from the action provider state
        final actionState = ref.read(profileActionProvider);
        logger.error("Like failed: ${actionState.errorMessage}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(actionState.errorMessage ?? 'Failed to like profile')),
        );
      }
    } catch (e) {
      logger.error("Exception during like operation: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleDislike(Profile profile) async {
    logger.debug("Handling Dislike for ${profile.name}");
    final success = await ref
        .read(profileActionProvider.notifier)
        .dislikeProfile(profile.id);
    if (!success && mounted) {
      final actionState = ref.read(profileActionProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(actionState.errorMessage ?? 'Failed to dislike profile')),
      );
    }
  }

  Future<void> _handleSuperLike(Profile profile) async {
    logger.debug("Handling Super Like for ${profile.name}");
    final success = await ref
        .read(profileActionProvider.notifier)
        .superlikeProfile(profile.id);
    if (success && mounted) {
      // Simulate match chance
      final bool isMatch = Random().nextDouble() < 0.4;
      if (isMatch) {
        await _showMatchAnimation(profile);
      }
    } else if (!success && mounted) {
      final actionState = ref.read(profileActionProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                actionState.errorMessage ?? 'Failed to superlike profile')),
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
      logger.error('Error getting current user profile for match: $e');
      // Use a more robust fallback with minimum required fields
      currentUserProfile = Profile(
        id: '0',
        name: 'Guest User',
        photoUrls: [],
        interests: [],
        profilePictures: [],
        isPremium: false,
        lastActive: DateTime.now(),
      );
    }

    if (!mounted) return;

    // Use null check to avoid exception
    if (currentUserProfile == null) {
      logger.error('Failed to get current user profile for match animation');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Match found! But could not display animation.')),
      );
      return;
    }

    // Get ChatService via provider - no need to use it directly in this method
    // final chatService = ref.read(chatServiceProvider);

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MatchAnimationDialog(
        userProfile:
            currentUserProfile!, // Use non-null assertion since we already checked
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
            logger.error('Error navigating to chat: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not start chat: ${e.toString()}')),
            );
          }
        },
      ),
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
    final isPremiumAsync = ref.watch(premiumProvider);

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
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _isLoading ? null : _refreshProfiles,
            tooltip: 'Refresh Profiles',
          ),
          // Filter button
          IconButton(
            icon: Icon(Icons.filter_list, color: AppColors.primary),
            onPressed: () {
              _showFilterDialog(context);
            },
            tooltip: 'Filter Profiles',
          ),
        ],
      ),
      // Use AsyncValue.when to handle loading/error/data states
      body: Column(
        children: [
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
                      setState(() =>
                          _currentIndex++); // Increment local index on swipe
                    },
                    onDislike: (profile) {
                      _handleDislike(profile);
                      setState(() => _currentIndex++);
                    },
                    onSuperLike: (profile) {
                      _handleSuperLike(profile);
                      setState(() => _currentIndex++);
                    },
                    showActions: true, // Keep the card's action buttons
                    onStackFinished: () {
                      logger.debug("Stack finished");
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                logger.error("Error loading profiles: $error\n$stackTrace");
                return _buildErrorView(error.toString()); // Pass error message
              },
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
            color: AppColors.textSecondary.withAlpha(128),
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
            color: AppColors.primary.withAlpha(128),
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
    // Start with current local values
    double distanceValue = _maxDistance;
    RangeValues ageRange = _ageRange;
    String selectedGender = _genderPreference;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConfig.defaultBorderRadius * 2),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(AppConfig.defaultPadding),
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
                          max: AppConfig.maxDistance,
                          divisions: AppConfig.maxDistance.toInt() - 1,
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
                          min: AppConfig.minAge.toDouble(),
                          max: AppConfig.maxAge.toDouble(),
                          divisions: 32, // Fixed integer value
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
                          color: selectedGender == gender
                              ? Colors.white
                              : AppColors.textPrimary,
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
                      _maxDistance = distanceValue;
                      _ageRange = ageRange;
                      _genderPreference = selectedGender;

                      // Update both SharedPreferences and provider
                      _saveFilters();

                      // Also update the provider directly
                      ref.read(profileFiltersProvider.notifier).updateFilters(
                            maxDistance: distanceValue,
                            ageRange: ageRange,
                            genderPreference: selectedGender,
                          );

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
  // void _swipeProfile(int index, CardSwiperDirection direction) { ... }

  // Method to handle the undo action
  // Future<void> _handleUndo() async { ... }

  // Helper function to show profile details (example)
  // void _showProfileDetails(BuildContext context, Profile profile) { ... }

  Future<void> _autoLogin() async {
    try {
      logger.info('Checking authentication status');
      final authState = ref.read(authStateProvider.notifier);

      // Check if already authenticated
      final currentStatus = ref.read(authStateProvider).status;
      if (currentStatus == AuthStatus.authenticated) {
        logger.info('Already authenticated, loading discover profiles');
        return;
      } else {
        logger.info('Not authenticated, redirecting to login screen');
        if (mounted) {
          // Navigate to login screen instead of auto-logging in with test credentials
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }

      // Removed auto-login with test credentials for security
    } catch (e) {
      logger.error('Authentication check failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Authentication check failed: ${e.toString().split('\n').first}')));
      }
    }
  }
}
