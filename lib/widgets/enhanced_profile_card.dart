import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/profile.dart';
import '../utils/colors.dart';
import '../utils/image_helper.dart';
import '../utils/logger.dart';
import '../screens/profile_details_screen.dart';
import 'dart:math';

// Create logger instance
final Logger logger = Logger('EnhancedProfileCard');

class EnhancedProfileCard extends StatefulWidget {
  final List<Profile> profiles;
  final Function(Profile) onLike;
  final Function(Profile) onDislike;
  final Function(Profile) onSuperLike;
  final bool showActions;
  final int initialIndex;
  final VoidCallback? onStackFinished;

  const EnhancedProfileCard({
    super.key,
    required this.profiles,
    required this.onLike,
    required this.onDislike,
    required this.onSuperLike,
    this.showActions = true,
    this.initialIndex = 0,
    this.onStackFinished,
  });

  @override
  EnhancedProfileCardState createState() => EnhancedProfileCardState();
}

class EnhancedProfileCardState extends State<EnhancedProfileCard> {
  late CardSwiperController controller;
  int currentIndex = 0;

  // Add PageController for photo navigation
  final Map<String, PageController> _photoControllers = {};

  // Add current page tracking map
  final Map<String, int> _currentPhotoIndices = {};

  @override
  void initState() {
    super.initState();
    controller = CardSwiperController();
    currentIndex = widget.initialIndex;

    // Initialize page controllers for each profile
    for (final profile in widget.profiles) {
      _photoControllers[profile.id] = PageController();
      _currentPhotoIndices[profile.id] = 0; // Initialize page index to 0
      logger.debug(
          'Created page controller for profile [33m[1m${profile.id}[0m');
    }

    logger.info('EnhancedProfileCard initialized');
  }

  @override
  void dispose() {
    controller.dispose();
    // Dispose all page controllers
    for (final controller in _photoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleSwipe(int index, CardSwiperDirection direction) {
    if (index >= widget.profiles.length) return;

    final profile = widget.profiles[index];

    switch (direction) {
      case CardSwiperDirection.right:
        HapticFeedback.mediumImpact();
        widget.onLike(profile);
        break;
      case CardSwiperDirection.left:
        HapticFeedback.lightImpact();
        widget.onDislike(profile);
        break;
      case CardSwiperDirection.top:
        HapticFeedback.heavyImpact();
        widget.onSuperLike(profile);
        break;
      default:
        break;
    }

    setState(() {
      currentIndex = index + 1;
    });

    // Check if we've reached the end of the stack
    if (currentIndex >= widget.profiles.length &&
        widget.onStackFinished != null) {
      widget.onStackFinished!();
    }
  }

  // Method to handle page changing (for logging)
  void _handlePageChanged(Profile profile, int page) {
    logger
        .debug('Page changed for profile [33m[1m${profile.id}[0m to $page');
    // Update the current page index in our tracking map
    setState(() {
      _currentPhotoIndices[profile.id] = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    logger.debug(
        'Building EnhancedProfileCard with [33m[1m${widget.profiles.length}[0m profiles');

    if (widget.profiles.isEmpty) {
      return const Center(
        child: Text('No profiles available'),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        children: [
          Expanded(
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight - (widget.showActions ? 100 : 0),
              child: CardSwiper(
                controller: controller,
                cardsCount: widget.profiles.length,
                initialIndex: currentIndex,
                onSwipe: (int index, int? previousIndex,
                    CardSwiperDirection direction) {
                  _handleSwipe(index, direction);
                  return true; // Allow the swipe
                },
                padding: const EdgeInsets.all(24.0),
                allowedSwipeDirection: const AllowedSwipeDirection.all(),
                onUndo: (previousIndex, currentIndex, direction) {
                  // Handle undo if needed
                  return true;
                },
                cardBuilder:
                    (context, index, percentThresholdX, percentThresholdY) {
                  if (index >= widget.profiles.length) {
                    return Container();
                  }
                  // Add debug log for each card build
                  logger.debug(
                      'Building card for profile [33m[1m${widget.profiles[index].name}[0m');

                  return _buildProfileCard(
                      widget.profiles[index],
                      percentThresholdX.toDouble(),
                      percentThresholdY.toDouble());
                },
              ),
            ),
          ),
          if (widget.showActions)
            SizedBox(
              height: 100,
              child: _buildActionButtons(),
            ),
        ],
      );
    });
  }

  Widget _buildProfileCard(Profile profile, double percentX, double percentY) {
    // Determine which overlay to show based on swipe direction
    Widget? overlay;
    if (percentX > 0.3) {
      overlay = Positioned(
        top: 20,
        left: 20,
        child: Transform.rotate(
          angle: -0.2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'LIKE',
              style: TextStyle(
                color: Colors.green,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    } else if (percentX < -0.3) {
      overlay = Positioned(
        top: 20,
        right: 20,
        child: Transform.rotate(
          angle: 0.2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'NOPE',
              style: TextStyle(
                color: Colors.red,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    } else if (percentY < -0.3) {
      overlay = Positioned(
        top: 20,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'SUPER LIKE',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildCardContent(profile),
              ),
            ),
          ),
          if (overlay != null) overlay,
        ],
      );
    });
  }

  // Update card content to use PageView with explicit tap areas
  Widget _buildCardContent(Profile profile) {
    logger.debug('Building card content for [33m[1m${profile.name}[0m');

    // Get or create a PageController for this profile
    final pageController = _photoControllers[profile.id] ??
        (_photoControllers[profile.id] = PageController());

    // Get current page index with fallback
    final currentPhotoIndex = _currentPhotoIndices[profile.id] ?? 0;

    return GestureDetector(
      // Double tap to view full profile
      onDoubleTap: () => _navigateToProfileDetails(context, profile),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Use PageView for photos - direct, no intermediary widget
          PageView.builder(
            controller: pageController,
            itemCount: profile.photoUrls.length,
            onPageChanged: (index) => _handlePageChanged(profile, index),
            physics: ClampingScrollPhysics(), // Prevent horizontal scrolling
            itemBuilder: (context, index) {
              final imageUrl = profile.photoUrls[index];
              logger.debug(
                  'Building photo $index for ${profile.id}: ${imageUrl.substring(0, min(20, imageUrl.length))}...');

              return ImageHelper.getNetworkImageWithFallback(
                imageUrl: imageUrl,
                gender: profile.gender,
                fit: BoxFit.cover,
              );
            },
          ),

          // ARROW BUTTONS - clearly visible on the left and right edges
          if (profile.photoUrls.length > 1)
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT ARROW
                  if (currentPhotoIndex > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          logger.debug('LEFT ARROW TAPPED');
                          // Direct navigation
                          if (currentPhotoIndex > 0) {
                            // Both change the page controller and update state directly
                            final newIndex = currentPhotoIndex - 1;
                            _currentPhotoIndices[profile.id] = newIndex;
                            pageController.jumpToPage(newIndex);

                            // Force update state
                            setState(() {});

                            // Vibrate
                            HapticFeedback.selectionClick();
                          }
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),

                  // RIGHT ARROW
                  if (currentPhotoIndex < profile.photoUrls.length - 1)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          logger.debug('RIGHT ARROW TAPPED');
                          // Direct navigation
                          if (currentPhotoIndex <
                              profile.photoUrls.length - 1) {
                            // Both change the page controller and update state directly
                            final newIndex = currentPhotoIndex + 1;
                            _currentPhotoIndices[profile.id] = newIndex;
                            pageController.jumpToPage(newIndex);

                            // Force update state
                            setState(() {});

                            // Vibrate
                            HapticFeedback.selectionClick();
                          }
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Swipe instruction overlay that only shows for 5 seconds
          if (profile.photoUrls.length > 1) _SwipeInstructionOverlay(),

          // Profile details at the bottom
          _buildProfileDetails(profile),

          // Visual indicator for double tap
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Double tap to view full profile",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black.withAlpha((0.5 * 255).toInt()),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Photo counter with tappable dots
          if (profile.photoUrls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        min(profile.photoUrls.length, 5),
                        (i) => GestureDetector(
                          onTap: () {
                            logger.debug('DOT $i TAPPED');
                            // Direct jump to this photo
                            _currentPhotoIndices[profile.id] = i;
                            pageController.jumpToPage(i);
                            setState(() {});
                            HapticFeedback.selectionClick();
                          },
                          child: Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == currentPhotoIndex
                                  ? Colors.white
                                  : Colors.white.withAlpha((0.5 * 255).toInt()),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToProfileDetails(BuildContext context, Profile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailsScreen(profile: profile),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Dislike button
          FloatingActionButton(
            heroTag: 'dislikeBtn',
            onPressed: () {
              if (currentIndex < widget.profiles.length) {
                _handleSwipe(currentIndex, CardSwiperDirection.left);
                controller.swipe(CardSwiperDirection.left);
              }
            },
            backgroundColor: Colors.white,
            elevation: 6,
            child: const Icon(
              Icons.close,
              color: Colors.red,
              size: 30,
            ),
          ),

          // INFO button (new)
          FloatingActionButton(
            heroTag: 'infoBtn',
            onPressed: () {
              if (currentIndex < widget.profiles.length) {
                _navigateToProfileDetails(
                    context, widget.profiles[currentIndex]);
              }
            },
            backgroundColor: Colors.white,
            elevation: 6,
            mini: true,
            child: const Icon(
              Icons.info,
              color: AppColors.primary,
              size: 24,
            ),
          ),

          // Super like button
          FloatingActionButton(
            heroTag: 'superLikeBtn',
            onPressed: () {
              if (currentIndex < widget.profiles.length) {
                _handleSwipe(currentIndex, CardSwiperDirection.top);
                controller.swipe(CardSwiperDirection.top);
              }
            },
            backgroundColor: Colors.white,
            elevation: 6,
            mini: true,
            child: const Icon(
              Icons.star,
              color: Colors.blue,
              size: 24,
            ),
          ),

          // Like button
          FloatingActionButton(
            heroTag: 'likeBtn',
            onPressed: () {
              if (currentIndex < widget.profiles.length) {
                _handleSwipe(currentIndex, CardSwiperDirection.right);
                controller.swipe(CardSwiperDirection.right);
              }
            },
            backgroundColor: Colors.white,
            elevation: 6,
            child: const Icon(
              Icons.favorite,
              color: Colors.green,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails(Profile profile) {
    return Container(
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withAlpha((0.7 * 255).toInt()),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name, age and verification badge
          Row(
            children: [
              Text(
                '${profile.name}, ${profile.age}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              if (profile.isVerified == true)
                const Icon(
                  Icons.verified,
                  color: Colors.blue,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Location and distance
          if (profile.location != null)
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  profile.location is Map
                      ? '${profile.location['city']}, ${profile.location['country']}'
                      : profile.location.toString(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                if (profile.distance != null) ...[
                  const Text(' • ', style: TextStyle(color: Colors.white70)),
                  Text(
                    '${profile.distance!.round()} km',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 8),

          // Occupation
          if (profile.occupation != null && profile.occupation!.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.work, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  profile.occupation!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),

          // Bio
          if (profile.bio != null && profile.bio!.isNotEmpty)
            Text(
              profile.bio!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),

          // Interests
          if (profile.interests.isNotEmpty)
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: profile.interests
                  .map((interest) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.2 * 255).toInt()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          interest,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// Add a separate widget for the swipe instruction that auto-hides
class _SwipeInstructionOverlay extends StatefulWidget {
  @override
  _SwipeInstructionOverlayState createState() =>
      _SwipeInstructionOverlayState();
}

class _SwipeInstructionOverlayState extends State<_SwipeInstructionOverlay> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    // Auto-hide after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _visible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return SizedBox.shrink();

    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            "Tap arrows to view more photos",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
