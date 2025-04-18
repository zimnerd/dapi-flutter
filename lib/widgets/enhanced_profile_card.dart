import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/profile.dart';
import '../utils/colors.dart';
import '../utils/image_helper.dart';
import '../screens/profile_details_screen.dart';
import 'dart:math';

class EnhancedProfileCard extends StatefulWidget {
  final List<Profile> profiles;
  final Function(Profile) onLike;
  final Function(Profile) onDislike;
  final Function(Profile) onSuperLike;
  final bool showActions;
  final int initialIndex;
  final VoidCallback? onStackFinished;

  const EnhancedProfileCard({
    Key? key,
    required this.profiles,
    required this.onLike,
    required this.onDislike,
    required this.onSuperLike,
    this.showActions = true,
    this.initialIndex = 0,
    this.onStackFinished,
  }) : super(key: key);

  @override
  _EnhancedProfileCardState createState() => _EnhancedProfileCardState();
}

class _EnhancedProfileCardState extends State<EnhancedProfileCard> {
  late CardSwiperController controller;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = CardSwiperController();
    currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    controller.dispose();
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
    if (currentIndex >= widget.profiles.length && widget.onStackFinished != null) {
      widget.onStackFinished!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profiles.isEmpty) {
      return const Center(
        child: Text('No profiles available'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: CardSwiper(
            controller: controller,
            cardsCount: widget.profiles.length,
            initialIndex: currentIndex,
            onSwipe: (int index, int? previousIndex, CardSwiperDirection direction) {
              _handleSwipe(index, direction);
              return true; // Allow the swipe
            },
            padding: const EdgeInsets.all(24.0),
            allowedSwipeDirection: const AllowedSwipeDirection.all(),
            onUndo: (previousIndex, currentIndex, direction) {
              // Handle undo if needed
              return true;
            },
            cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
              if (index >= widget.profiles.length) {
                return Container();
              }
              return _buildProfileCard(widget.profiles[index], percentThresholdX.toDouble(), percentThresholdY.toDouble());
            },
          ),
        ),
        if (widget.showActions)
          _buildActionButtons(),
      ],
    );
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

    return Stack(
      children: [
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Use our new helper method for profile photos with fallbacks
                _buildProfilePhoto(profile, 0),
                
                // Photo count indicators
                if (profile.photoUrls.length > 1)
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        profile.photoUrls.length.clamp(0, 5),
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == 0
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Profile details at the bottom
                _buildProfileDetails(profile),
              ],
            ),
          ),
        ),
        if (overlay != null) overlay,
      ],
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
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          if (profile.occupation != null && profile.occupation!.isNotEmpty)
            Text(
              profile.occupation!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          if (profile.distance != null)
            Text(
              '${profile.distance} km away',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 8),
          if (profile.interests.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: profile.interests.take(3).map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    interest,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto(Profile profile, int photoIndex) {
    final String photoUrl = photoIndex < profile.photoUrls.length 
        ? profile.photoUrls[photoIndex]
        : '';
        
    // Use our new static ImageHelper method for better image loading with fallbacks
    return ImageHelper.getNetworkImageWithFallback(
      imageUrl: photoUrl,
      gender: profile.gender,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(16),
    );
  }
}

/// Photo switcher widget for profile cards
class _PhotoSwitcher extends StatefulWidget {
  final List<String> photos;
  
  const _PhotoSwitcher({required this.photos});
  
  @override
  _PhotoSwitcherState createState() => _PhotoSwitcherState();
}

class _PhotoSwitcherState extends State<_PhotoSwitcher> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Photo PageView
        PageView.builder(
          controller: _pageController,
          itemCount: widget.photos.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
            HapticFeedback.selectionClick();
          },
          itemBuilder: (context, index) {
            return Image.network(
              widget.photos[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                );
              },
            );
          },
        ),
        
        // Photo indicators
        Positioned(
          top: 12, // Moved slightly higher
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.photos.length,
              (index) {
                return Container(
                  width: 6, // Smaller dots
                  height: 6, // Smaller dots
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentIndex
                        ? Colors.white
                        : Colors.white.withOpacity(0.4), // More subtle non-active dots
                  ),
                );
              },
            ),
          ),
        ),
        
        // Left edge tap area for previous photo
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 70,
          child: GestureDetector(
            onTap: () {
              if (_currentIndex > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
        
        // Right edge tap area for next photo
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 70,
          child: GestureDetector(
            onTap: () {
              if (_currentIndex < widget.photos.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
} 