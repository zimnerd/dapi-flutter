import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/profile.dart';
import '../utils/colors.dart';
import '../screens/profile_details_screen.dart';

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
  final CardSwiperController _cardController = CardSwiperController();
  
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
            controller: _cardController,
            cardsCount: widget.profiles.length,
            initialIndex: widget.initialIndex,
            isLoop: false,
            maxAngle: 30, // Maximum rotation angle
            threshold: 50, // Swipe threshold
            scale: 0.9, // Scale for the card below
            padding: const EdgeInsets.all(16),
            allowedSwipeDirection: AllowedSwipeDirection.all(), // Allow all swipe directions
            onSwipe: (int previousIndex, int? currentIndex, CardSwiperDirection direction) {
              final swipedProfile = widget.profiles[previousIndex];
              
              // Provide haptic feedback
              switch (direction) {
                case CardSwiperDirection.right:
                  HapticFeedback.mediumImpact();
                  widget.onLike(swipedProfile);
                  break;
                case CardSwiperDirection.left:
                  HapticFeedback.mediumImpact();
                  widget.onDislike(swipedProfile);
                  break;
                case CardSwiperDirection.top:
                  HapticFeedback.heavyImpact();
                  widget.onSuperLike(swipedProfile);
                  break;
                default:
                  // Handle other directions if needed
                  break;
              }
              
              // Always return true to allow the swipe
              return true;
            },
            onEnd: widget.onStackFinished,
            cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
              final profile = widget.profiles[index];
              
              // Calculate like/dislike indicators opacity based on drag threshold
              final likeOpacity = percentThresholdX > 0 ? percentThresholdX.toDouble() : 0.0;
              final dislikeOpacity = percentThresholdX < 0 ? (-percentThresholdX).toDouble() : 0.0;
              final superLikeOpacity = percentThresholdY < 0 ? (-percentThresholdY).toDouble() : 0.0;
              
              return _buildProfileCard(
                profile: profile,
                likeOpacity: likeOpacity,
                dislikeOpacity: dislikeOpacity,
                superLikeOpacity: superLikeOpacity,
              );
            },
          ),
        ),
        if (widget.showActions)
          _buildActionButtons(),
      ],
    );
  }

  Widget _buildProfileCard({
    required Profile profile,
    double likeOpacity = 0.0,
    double dislikeOpacity = 0.0,
    double superLikeOpacity = 0.0,
  }) {
    return GestureDetector(
      onDoubleTap: () => _navigateToProfileDetails(profile),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Profile photo viewer
            _PhotoSwitcher(photos: profile.photoUrls),
                      
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            
            // Like/Dislike indicators
            if (likeOpacity > 0)
              Positioned(
                top: 30,
                right: 30,
                child: Opacity(
                  opacity: likeOpacity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.like, width: 4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LIKE',
                      style: TextStyle(
                        color: AppColors.like,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
              ),
              
            if (dislikeOpacity > 0)
              Positioned(
                top: 30,
                left: 30,
                child: Opacity(
                  opacity: dislikeOpacity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.dislike, width: 4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'NOPE',
                      style: TextStyle(
                        color: AppColors.dislike,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
              ),
              
            if (superLikeOpacity > 0)
              Positioned.fill(
                // Use Positioned.fill and Align to center the overlay
                child: Align(
                  alignment: Alignment.center, // Center the whole feedback
                  child: Opacity(
                    // Fade the entire effect based on drag
                    opacity: superLikeOpacity * 1.5 > 1.0 ? 1.0 : superLikeOpacity * 1.5, // Make opacity reach 1 faster
                    child: Container(
                      // Add a semi-transparent background flash
                      decoration: BoxDecoration(
                         color: AppColors.superLike.withOpacity(superLikeOpacity * 0.2), // Background flash fades in
                         shape: BoxShape.circle, // Make it circular
                      ),
                      padding: EdgeInsets.all(40 + (superLikeOpacity * 20)), // Make padding pulse slightly
                      child: Transform.scale(
                        scale: 1.0 + (superLikeOpacity * 0.1), // Make icon/text pulse slightly
                        child: Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Icon(
                               Icons.star_rounded,
                               color: AppColors.superLike.withOpacity(0.8),
                               size: 40 + (superLikeOpacity * 15), // Icon scales up
                             ),
                             const SizedBox(height: 8),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                               decoration: BoxDecoration(
                                 border: Border.all(
                                   color: AppColors.superLike, 
                                   // Make border width pulse slightly
                                   width: 3 + (superLikeOpacity * 2),
                                 ),
                                 borderRadius: BorderRadius.circular(8),
                                 color: Colors.black.withOpacity(0.1), // Slight background for text
                               ),
                               child: const Text(
                                 'SUPER LIKE',
                                 style: TextStyle(
                                   color: AppColors.superLike,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 24, // Slightly smaller
                                 ),
                               ),
                             ),
                           ],
                         ),
                      ),
                    ),
                  ),
                ),
              ),
            
            // Profile info content at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildProfileInfo(profile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(Profile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and age
        Row(
          children: [
            Expanded(
              child: Text(
                '${profile.name}, ${profile.age}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (profile.isVerified ?? false)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Location
        if (profile.location?.isNotEmpty == true)
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  profile.location ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        
        const SizedBox(height: 8),
        
        // Bio (truncated)
        if (profile.bio?.isNotEmpty == true)
          Text(
            profile.bio ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        
        const SizedBox(height: 12),
        
        // Interests
        if (profile.interests.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.interests
                .take(5) // Limit to 5 interests to avoid overcrowding
                .map((interest) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, 
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    interest,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Dislike button (X)
          _buildCircleButton(
            onTap: () {
              HapticFeedback.mediumImpact();
              _cardController.swipe(CardSwiperDirection.left);
            },
            icon: Icons.close,
            color: AppColors.dislike,
            size: 60,
            iconSize: 30,
          ),
          
          // Rewind/Undo button (Premium feature)
          _buildCircleButton(
            onTap: () {
              HapticFeedback.mediumImpact();
              _cardController.undo();
            },
            icon: Icons.replay,
            color: Colors.amber,
            size: 48,
            iconSize: 22,
          ),
          
          // Super Like button (star)
          _buildCircleButton(
            onTap: () {
              HapticFeedback.heavyImpact();
              _cardController.swipe(CardSwiperDirection.top);
            },
            icon: Icons.star,
            color: AppColors.superLike,
            size: 54,
            iconSize: 26,
          ),
          
          // Like button (heart)
          _buildCircleButton(
            onTap: () {
              HapticFeedback.mediumImpact();
              _cardController.swipe(CardSwiperDirection.right);
            },
            icon: Icons.favorite,
            color: AppColors.like,
            size: 60,
            iconSize: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            child: Icon(
              icon,
              color: color,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
  
  void _navigateToProfileDetails(Profile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileDetailsScreen(
          profile: profile,
        ),
      ),
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
          top: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.photos.length,
              (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentIndex
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
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