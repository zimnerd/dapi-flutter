import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';
import 'dart:math' as math;

/// A widget that displays an animation when a match occurs
class MatchAnimation extends StatefulWidget {
  final String matchName;
  final String? matchPhoto;
  final VoidCallback? onMessageTap;
  final VoidCallback? onKeepSwipingTap;

  const MatchAnimation({
    super.key,
    required this.matchName,
    this.matchPhoto,
    this.onMessageTap,
    this.onKeepSwipingTap,
  });

  @override
  _MatchAnimationState createState() => _MatchAnimationState();
}

class _MatchAnimationState extends State<MatchAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _contentOpacityAnimation;

  final List<_Particle> _particles = [];
  final int _particleCount = 50;
  final math.Random _random = math.Random();
  bool _particlesGenerated = false;

  @override
  void initState() {
    super.initState();

    // Add vibration feedback
    HapticFeedback.mediumImpact();

    // Create animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Define animations
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.3, curve: Curves.easeOutBack),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    _contentOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    // We'll generate particles in didChangeDependencies instead

    // Start animation immediately
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Generate particles only once after the widget is fully initialized
    if (!_particlesGenerated) {
      _generateParticles();
      _particlesGenerated = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateParticles() {
    final size = MediaQuery.of(context).size;

    for (int i = 0; i < _particleCount; i++) {
      final particle = _Particle(
        position: Offset(
          size.width * 0.5,
          size.height * 0.4,
        ),
        color: _getRandomColor(),
        size: _random.nextDouble() * 12 + 5,
        velocity: Offset(
          (_random.nextDouble() * 2 - 1) * 5,
          (_random.nextDouble() * -1 - 1) * 5,
        ),
        angleSpeed: (_random.nextDouble() * 2 - 1) * 0.1,
        shape: _random.nextInt(2),
      );

      _particles.add(particle);
    }
  }

  Color _getRandomColor() {
    final colors = [
      AppColors.primary,
      AppColors.primaryLight,
      AppColors.secondary,
      AppColors.secondaryLight,
      Colors.pink[300]!,
      Colors.pinkAccent,
      Colors.white,
    ];

    return colors[_random.nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Update particle positions
          for (final particle in _particles) {
            particle.position += particle.velocity;
            particle.angle += particle.angleSpeed;

            // Add gravity effect
            particle.velocity += const Offset(0, 0.05);

            // Apply air resistance
            particle.velocity *= 0.99;
          }

          return Stack(
            children: [
              // Particles
              if (_controller.value > 0.05)
                CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _controller.value,
                  ),
                  size: Size.infinite,
                ),

              // Center content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // "It's a Match!" text with scale animation
                    Opacity(
                      opacity: _opacityAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return AppColors.primaryGradient
                                .createShader(bounds);
                          },
                          child: const Text(
                            "It's a Match!",
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 40),

                    // Content that appears after the match text
                    Opacity(
                      opacity: _contentOpacityAnimation.value,
                      child: Column(
                        children: [
                          // Profile image
                          CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.white,
                            backgroundImage: widget.matchPhoto != null
                                ? NetworkImage(widget.matchPhoto!)
                                : null,
                            child: widget.matchPhoto == null
                                ? Icon(Icons.person,
                                    size: 70, color: Colors.grey)
                                : null,
                          ),

                          SizedBox(height: 20),

                          // Match name
                          Text(
                            'You and ${widget.matchName} have liked each other.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: 40),

                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Send message button
                              ElevatedButton(
                                onPressed: widget.onMessageTap,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Send Message',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              SizedBox(width: 16),

                              // Keep swiping button
                              OutlinedButton(
                                onPressed: widget.onKeepSwipingTap,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                      color: Colors.white, width: 1.5),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  'Keep Swiping',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double angle;
  double angleSpeed;
  int shape; // 0 = circle, 1 = square, 2 = triangle

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.angleSpeed,
    required this.shape,
    this.angle = 0.0,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Only show particles until certain point in the animation
    if (progress < 0.9) {
      // Adjust opacity based on progress to fade out
      final opacity = progress < 0.7 ? 1.0 : (0.9 - progress) / 0.2;

      for (final particle in particles) {
        paint.color = particle.color.withOpacity(opacity);

        // Apply rotation
        canvas.save();
        canvas.translate(particle.position.dx, particle.position.dy);
        canvas.rotate(particle.angle);

        // Draw different shapes
        switch (particle.shape) {
          case 0: // Circle
            canvas.drawCircle(Offset.zero, particle.size / 2, paint);
            break;
          case 1: // Square
            final rect = Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size,
            );
            canvas.drawRect(rect, paint);
            break;
          case 2: // Heart
            drawHeart(canvas, paint, particle.size);
            break;
        }

        canvas.restore();
      }
    }
  }

  void drawHeart(Canvas canvas, Paint paint, double size) {
    final path = Path();
    final width = size;
    final height = size;

    path.moveTo(width / 2, height / 5);

    // Left curve
    path.cubicTo(
      5 * width / 14,
      0,
      0,
      height / 15,
      width / 4,
      2 * height / 5,
    );

    // Bottom point
    path.cubicTo(
      width / 2,
      2 * height / 3,
      width / 2,
      2 * height / 3,
      width / 2,
      4 * height / 5,
    );

    // Right curve
    path.cubicTo(
      width / 2,
      2 * height / 3,
      width / 2,
      2 * height / 3,
      3 * width / 4,
      2 * height / 5,
    );

    path.cubicTo(
      width,
      height / 15,
      9 * width / 14,
      0,
      width / 2,
      height / 5,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
