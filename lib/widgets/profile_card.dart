import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/profile.dart';
import '../utils/colors.dart';
import '../screens/profile_details_screen.dart';

class ProfileCard extends StatefulWidget {
  final Profile profile;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onSuperLike;
  final bool showActions;
  final bool interactive;

  const ProfileCard({
    Key? key,
    required this.profile,
    this.onLike,
    this.onDislike,
    this.onSuperLike,
    this.showActions = true,
    this.interactive = true,
  }) : super(key: key);

  @override
  _ProfileCardState createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> with TickerProviderStateMixin {
  // Controllers and animations
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _rotationAnimation;
  
  // Additional controllers for complex animations
  late AnimationController _dragResetController;
  late AnimationController _swipeOutController;
  late AnimationController _superLikeController;
  
  // Page controller for photos
  final PageController _photoController = PageController();
  int _currentPhotoIndex = 0;
  
  // State tracking
  bool _isDragging = false;
  bool _isAnimating = false;
  bool _isPressed = false;
  bool _isBioExpanded = false;
  
  // Positioning state
  Offset _dragPosition = Offset.zero;
  Offset _dragStartPosition = Offset.zero;
  double _currentRotation = 0.0;
  double _currentScale = 1.0;
  
  // Constants for better responsiveness
  final double _swipeThreshold = 0.25; // Percentage of screen width
  final double _maxRotationAngle = 0.2; // ~11.5 degrees in radians
  final double _maxMovementFactor = 1.5; // Allow movement beyond screen boundaries
  
  @override
  void initState() {
    super.initState();
    
    // Initialize all controllers upfront to avoid multiple ticker creation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _dragResetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _swipeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _superLikeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    
    // Default animations
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _photoController.addListener(_onPhotoChange);
  }
  
  @override
  void dispose() {
    _photoController.removeListener(_onPhotoChange);
    _photoController.dispose();
    _animationController.dispose();
    _dragResetController.dispose();
    _swipeOutController.dispose();
    _superLikeController.dispose();
    super.dispose();
  }
  
  void _onPhotoChange() {
    final page = _photoController.page?.round() ?? 0;
    if (page != _currentPhotoIndex) {
      setState(() {
        _currentPhotoIndex = page;
      });
      
      // Add haptic feedback when changing photos
      if (widget.interactive) {
        HapticFeedback.selectionClick();
      }
    }
  }
  
  // MARK: - Gesture Handling
  
  void _handleDragStart(DragStartDetails details) {
    if (!widget.interactive) return;
    
    // Reset isDragging and capture start position
    setState(() {
      _isDragging = true;
      _dragStartPosition = details.localPosition;
      _dragPosition = Offset.zero;
    });
    
    // Add haptic feedback on start of drag
    HapticFeedback.lightImpact();
  }
  
  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.interactive || !_isDragging) return;
    
    final screenSize = MediaQuery.of(context).size;
    final maxDragX = screenSize.width * _maxMovementFactor;
    final maxDragY = screenSize.height * _maxMovementFactor;
    
    // Calculate new position with resistance - more resistance as it gets further from center
    setState(() {
      // Update position with resistance - increase initial smoothness by adjusting factor
      final rawDelta = details.delta;
      final dragDistanceRatio = (_dragPosition.distance / (screenSize.width * 0.5)).clamp(0.0, 1.0);
      
      // Smoother resistance curve - moves easily near center, harder at edges
      final resistanceFactor = 0.9 - (math.pow(dragDistanceRatio, 2) * 0.4);
      final delta = rawDelta * resistanceFactor;
      _dragPosition += delta;
      
      // Apply smoother boundaries with elastic effect
      if (_dragPosition.dx.abs() > maxDragX) {
        _dragPosition = Offset(
          _dragPosition.dx.sign * (maxDragX + (_dragPosition.dx.abs() - maxDragX) * 0.05),
          _dragPosition.dy
        );
      }
      
      if (_dragPosition.dy.abs() > maxDragY) {
        _dragPosition = Offset(
          _dragPosition.dx,
          _dragPosition.dy.sign * (maxDragY + (_dragPosition.dy.abs() - maxDragY) * 0.05)
        );
      }
      
      // Update rotation based on horizontal position with improved curve
      // Use a nonlinear curve for more natural rotation that increases toward edges
      final normalizedDx = (_dragPosition.dx / screenSize.width).clamp(-1.0, 1.0);
      _currentRotation = normalizedDx * _maxRotationAngle * 
          (0.8 + (normalizedDx.abs() * 0.3)); // Progressively stronger rotation near edges
      
      // Scale slightly when dragging for better interaction feedback
      _currentScale = 1.0 - (dragDistanceRatio * 0.05);
    });
  }
  
  void _handleDragEnd(DragEndDetails details) {
    if (!widget.interactive || !_isDragging) return;
    
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Thresholds based on screen size for more responsive interaction
    final dragThresholdX = screenWidth * _swipeThreshold;
    final dragThresholdY = screenHeight * _swipeThreshold;
    
    // Velocity thresholds adjusted for better responsiveness
    final velocity = details.velocity.pixelsPerSecond;
    final horizontalVelocityThreshold = 800.0;
    final verticalVelocityThreshold = -800.0;
    
    // Check for super like (upward swipe)
    if ((_dragPosition.dy < -dragThresholdY || velocity.dy < verticalVelocityThreshold) && 
        _dragPosition.dx.abs() < dragThresholdX) {
      _animateSuperLike();
      return;
    }
    
    // Check for like (right swipe)
    if ((_dragPosition.dx > dragThresholdX || velocity.dx > horizontalVelocityThreshold) && 
        widget.onLike != null) {
      _animateCardOffScreen(Offset(1.0, 0.0), true);
      return;
    }
    
    // Check for dislike (left swipe)
    if ((_dragPosition.dx < -dragThresholdX || velocity.dx < -horizontalVelocityThreshold) && 
        widget.onDislike != null) {
      _animateCardOffScreen(Offset(-1.0, 0.0), false);
      return;
    }
    
    // If no gesture matched, reset the card with a bounce effect
    _resetCardWithBounce(details.velocity);
  }
  
  void _resetCardWithBounce(Velocity? velocity) {
    if (_isAnimating) return;
    _isAnimating = true;
    
    // Reset the controller
    _dragResetController.reset();
    
    // Scale velocity for better bounce effect - divide by smaller value for more responsive bounce
    final velocityInfluence = velocity?.pixelsPerSecond.dx.clamp(-3000.0, 3000.0) ?? 0.0;
    final velocityFactor = velocityInfluence / 3000.0; // Normalize to -1..1 range
    
    // Position animation with bounce and velocity-based overshoot
    final positionAnimation = TweenSequence<Offset>([
      // First quickly move back with slight overshoot in direction of velocity
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: _dragPosition,
          end: Offset(velocityFactor * 20.0, _dragPosition.dy * 0.8),
        ).chain(CurveTween(curve: Curves.easeOutQuint)),
        weight: 30,
      ),
      // Then settle back to center with elastic effect
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(velocityFactor * 20.0, _dragPosition.dy * 0.8),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_dragResetController);
    
    // Rotation animation with bounce - more dramatic based on velocity
    final rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: _currentRotation,
          end: -velocityFactor * 0.1,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -velocityFactor * 0.1,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_dragResetController);
    
    // Scale animation with bounce
    final scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: _currentScale,
          // Slight pulse out when returning
          end: 1.02,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.02,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutBack)),
        weight: 70,
      ),
    ]).animate(_dragResetController);
    
    _dragResetController.addListener(() {
      if (mounted) {
        setState(() {
          _dragPosition = positionAnimation.value;
          _currentRotation = rotationAnimation.value;
          _currentScale = scaleAnimation.value;
        });
      }
    });
    
    _dragResetController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _dragPosition = Offset.zero;
          _currentRotation = 0.0;
          _currentScale = 1.0;
          _isDragging = false;
          _isAnimating = false;
        });
      }
    });
    
    // Add light haptic feedback for reset
    HapticFeedback.lightImpact();
    
    _dragResetController.forward();
  }
  
  void _animateSuperLike() {
    if (!mounted || _isAnimating || !widget.interactive) return;
    
    _isAnimating = true;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Reset the controller
    _superLikeController.reset();
    
    // Create a path animation for the card with improved feel
    final positionAnimation = TweenSequence<Offset>([
      // First, a small anticipation dip down
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: _dragPosition,
          end: Offset(_dragPosition.dx * 0.7, _dragPosition.dy + 20),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      // Quick rise to apex point
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(_dragPosition.dx * 0.7, _dragPosition.dy + 20),
          end: Offset(_dragPosition.dx * 0.3, -screenHeight * 0.2),
        ).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 30,
      ),
      // Arcing path toward top of screen
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(_dragPosition.dx * 0.3, -screenHeight * 0.2),
          end: Offset(0, -screenHeight * 1.5),
        ).chain(CurveTween(curve: Curves.easeOutQuint)),
        weight: 60,
      ),
    ]).animate(_superLikeController);
    
    // Add scale animation with pulse effect
    final scaleAnimation = TweenSequence<double>([
      // Initial slight pulse
      TweenSequenceItem(
        tween: Tween<double>(
          begin: _currentScale,
          end: 1.1, // More dramatic pulse
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 20,
      ),
      // Hold the pulse briefly
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.1,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      // Shrink as it flies away
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.05,
          end: 0.6, // Smaller end size for more dramatic effect
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_superLikeController);
    
    // Add rotation animation with slight wobble
    final rotationAnimation = TweenSequence<double>([
      // Initial small counter-rotation
      TweenSequenceItem(
        tween: Tween<double>(
          begin: _currentRotation,
          end: -_currentRotation * 0.5, // Reverse current rotation
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      // Small wobble as it rises
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -_currentRotation * 0.5,
          end: 0.05, // Slight lean right
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      // Straighten out for final rise
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.05,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
    ]).animate(_superLikeController);
    
    _superLikeController.addListener(() {
      if (mounted) {
        setState(() {
          _dragPosition = positionAnimation.value;
          _currentScale = scaleAnimation.value;
          _currentRotation = rotationAnimation.value;
        });
      }
    });
    
    _superLikeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.onSuperLike != null) {
          widget.onSuperLike!();
        }
        
        // Use post-frame callback to avoid the flash
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _dragPosition = Offset.zero;
              _currentRotation = 0.0;
              _currentScale = 1.0;
              _isDragging = false;
              _isAnimating = false;
            });
          }
        });
      }
    });
    
    // Add medium haptic feedback for super like
    HapticFeedback.mediumImpact();
    
    _superLikeController.forward();
  }
  
  void _animateCardOffScreen(Offset direction, bool isLike) {
    // Normalize direction vector for consistent distance regardless of direction
    final normalized = direction.distance > 0 
        ? Offset(direction.dx / direction.distance, direction.dy / direction.distance) 
        : Offset.zero;
    
    // Calculate final destination based on screen size
    final size = MediaQuery.of(context).size;
    final destinationX = normalized.dx * size.width * 1.2; // Ensure it's off screen
    final destinationY = normalized.dy * size.height * 0.3; // Don't go too far vertically
    
    // Set end position for animation
    _dragPosition = Offset(destinationX, destinationY);
    
    // Set final rotation based on horizontal movement direction
    _currentRotation = direction.dx > 0 ? math.pi / 8 : -math.pi / 8;
    
    // Flag that animation is in progress to prevent further interaction
    setState(() {
      _isAnimating = true;
    });
    
    // Start the swipe out animation
    _swipeOutController.forward().then((_) {
      // Use post-frame callback to ensure the UI updates before we notify parent
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Callback based on direction
        if (isLike) {
          if (widget.onLike != null) widget.onLike!();
        } else {
          if (widget.onDislike != null) widget.onDislike!();
        }
        
        // Set a delay before resetting to prevent flashing
        Future.delayed(const Duration(milliseconds: 50), () {
          // Check if widget is still mounted before updating state
          if (mounted) {
            setState(() {
              // Reset state while card is hidden
              _dragPosition = Offset.zero;
              _currentRotation = 0.0;
              _isDragging = false;
              _isAnimating = false;
              _currentScale = 1.0;
              
              // Reset controllers to prepare for potential reuse
              _swipeOutController.reset();
            });
          }
        });
      });
    });
  }
  
  void _handleTapDown(TapDownDetails details) {
    if (!widget.interactive) return;
    
    setState(() => _isPressed = true);
    _animationController.forward();
  }
  
  void _handleTapUp(TapUpDetails details) {
    if (!widget.interactive) return;
    
    setState(() => _isPressed = false);
    _animationController.reverse();
  }
  
  void _handleTapCancel() {
    if (!widget.interactive) return;
    
    setState(() => _isPressed = false);
    _animationController.reverse();
  }
  
  void _navigateToPhoto(int index) {
    _photoController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _expandPhoto() {
    if (!widget.interactive) return;
    
    // Navigate to the full profile details screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileDetailsScreen(
          profile: widget.profile,
        ),
      ),
    );
  }
  
  void onLikeButtonPressed() {
    if (!widget.interactive || _isAnimating) return;
    
    HapticFeedback.mediumImpact();
    _animateCardOffScreen(Offset(1.0, 0.0), true);
  }

  void onDislikeButtonPressed() {
    if (!widget.interactive || _isAnimating) return;
    
    HapticFeedback.mediumImpact();
    _animateCardOffScreen(Offset(-1.0, 0.0), false);
  }
  
  void onSuperLikeButtonPressed() {
    if (!widget.interactive || _isAnimating) return;
    
    HapticFeedback.mediumImpact();
    _animateSuperLike();
  }
  
  // MARK: - Widget Building
  
  @override
  Widget build(BuildContext context) {
    // Add an outer AnimatedOpacity to smooth out any transition
    return GestureDetector(
      onPanStart: (!widget.interactive || _isAnimating) ? null : _handleDragStart,
      onPanUpdate: (!widget.interactive || _isAnimating) ? null : _handleDragUpdate,
      onPanEnd: (!widget.interactive || _isAnimating) ? null : _handleDragEnd,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onDoubleTap: _expandPhoto,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _animationController,
          _dragResetController,
          _swipeOutController,
          _superLikeController,
        ]),
        builder: (context, child) {
          // Calculate opacity based on animation progress for smoother exit
          double exitOpacity = 1.0;
          if (_swipeOutController.isAnimating && _swipeOutController.value > 0.5) {
            // Start fading out at 50% of the animation for smoother transition
            exitOpacity = 1.0 - ((_swipeOutController.value - 0.5) / 0.5);
          } else if (_superLikeController.isAnimating && _superLikeController.value > 0.6) {
            // Start fading out at 60% of the super like animation
            exitOpacity = 1.0 - ((_superLikeController.value - 0.6) / 0.4);
          }
          
          return Opacity(
            opacity: exitOpacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: _dragPosition,
              child: Transform.rotate(
                angle: _currentRotation,
                alignment: Alignment.center,
                child: Transform.scale(
                  scale: _currentScale,
                  alignment: Alignment.center,
                  child: child,
                ),
              ),
            ),
          );
        },
        child: RepaintBoundary(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Card content
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
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
                        // Profile photo
                        _buildPhotoSwitcher(),
                        
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
                        
                        // Info content at the bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name and age
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${widget.profile.name}, ${widget.profile.age}',
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (widget.profile.isVerified ?? false)
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
                                if (widget.profile.location?.isNotEmpty == true)
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
                                          widget.profile.location ?? '',
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
                                
                                // Bio with click to expand
                                if (widget.profile.bio?.isNotEmpty == true)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isBioExpanded = !_isBioExpanded;
                                      });
                                    },
                                    child: AnimatedCrossFade(
                                      duration: const Duration(milliseconds: 300),
                                      firstChild: Text(
                                        widget.profile.bio ?? '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      secondChild: Text(
                                        widget.profile.bio ?? '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      crossFadeState: _isBioExpanded 
                                          ? CrossFadeState.showSecond 
                                          : CrossFadeState.showFirst,
                                    ),
                                  ),
                                
                                const SizedBox(height: 12),
                                
                                // Interests
                                if (widget.profile.interests.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: widget.profile.interests
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
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ))
                                        .toList(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Photo indicators
                        if (widget.profile.photoUrls.length > 1)
                          Positioned(
                            bottom: widget.profile.interests.isEmpty ? 90 : 140,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                widget.profile.photoUrls.length,
                                (index) {
                                  final isActive = index == _currentPhotoIndex;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: isActive ? 16 : 8,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isActive 
                                        ? Colors.white 
                                        : Colors.white.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                        // Swipe indicators as overlay
                        if (_isDragging) ...[
                          _buildSwipeIndicator(isLike: true),
                          _buildSwipeIndicator(isLike: false),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Bottom action buttons
                if (widget.showActions && widget.interactive)
                  _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPhotoSwitcher() {
    return PageView.builder(
      controller: _photoController,
      itemCount: widget.profile.photoUrls.length,
      physics: widget.interactive
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: _expandPhoto,
          child: Hero(
            tag: 'profile_photo_${widget.profile.id}_$index',
            child: Image.network(
              widget.profile.photoUrls[index],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 64,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      onPageChanged: (index) {
        // Add subtle haptic feedback when changing photos
        HapticFeedback.selectionClick();
        setState(() {
          _currentPhotoIndex = index;
        });
      },
    );
  }
  
  Widget _buildSwipeIndicator({required bool isLike}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate opacity based on drag position
    double opacity = 0.0;
    if (isLike) {
      opacity = (_dragPosition.dx / (screenWidth * 0.5)).clamp(0.0, 1.0);
    } else {
      opacity = (-_dragPosition.dx / (screenWidth * 0.5)).clamp(0.0, 1.0);
    }
    
    // Don't show indicator if dragging too far up (super like territory)
    if (_dragPosition.dy < -screenHeight * 0.1) {
      opacity = 0.0;
    }
    
    // If not dragging horizontally enough, don't show
    if (_dragPosition.dx.abs() < 10) {
      opacity = 0.0;
    }
    
    // Calculate position - upper corners
    final position = isLike ? Alignment.topRight : Alignment.topLeft;
    
    return Positioned.fill(
      child: Align(
        alignment: position,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: opacity,
            child: Transform.rotate(
              angle: isLike ? -0.1 : 0.1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isLike ? AppColors.like : AppColors.dislike,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isLike ? 'LIKE' : 'NOPE',
                  style: TextStyle(
                    color: isLike ? AppColors.like : AppColors.dislike,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.close,
            color: AppColors.dislike,
            onTap: onDislikeButtonPressed,
          ),
          _buildActionButton(
            icon: Icons.star,
            color: AppColors.superLike,
            size: 64,
            onTap: onSuperLikeButtonPressed,
          ),
          _buildActionButton(
            icon: Icons.favorite,
            color: AppColors.like,
            onTap: onLikeButtonPressed,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 56,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Material(
            elevation: 4,
            shape: const CircleBorder(),
            color: Colors.white,
            child: InkWell(
              onTap: () {
                // Add extra visual feedback with scale animation
                _animateButtonPress(onTap);
              },
              customBorder: const CircleBorder(),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.2), width: 2),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: size * 0.5,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // New method to animate button press with scale effect
  void _animateButtonPress(VoidCallback callback) {
    // Create a quick pulse animation
    final buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    buttonController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        buttonController.reverse().then((_) {
          buttonController.dispose();
        });
        // Execute the callback after animation starts
        callback();
      }
    });
    
    // Start with a quick scale down then up
    buttonController.forward();
    
    // Add haptic feedback
    HapticFeedback.mediumImpact();
  }
}

// Fullscreen photo view widget
class _FullscreenPhotoView extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  
  const _FullscreenPhotoView({
    Key? key,
    required this.photos,
    required this.initialIndex,
  }) : super(key: key);
  
  @override
  _FullscreenPhotoViewState createState() => _FullscreenPhotoViewState();
}

class _FullscreenPhotoViewState extends State<_FullscreenPhotoView> {
  late PageController _pageController;
  late int _currentIndex;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Stack(
        children: [
          // Photo viewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Hero(
                tag: 'photo_$index',
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Center(
                    child: Image.network(
                      widget.photos[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                loadingProgress.expectedTotalBytes!
                              : null,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Material(
              color: Colors.black.withOpacity(0.5),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          
          // Photo indicators
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.photos.length,
                (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 20 : 10,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive 
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Counter
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.photos.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}