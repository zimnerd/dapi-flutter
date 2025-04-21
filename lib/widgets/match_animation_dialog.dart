import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:confetti/confetti.dart';
import '../models/profile.dart';
import '../utils/colors.dart';

class MatchAnimationDialog extends StatefulWidget {
  final Profile userProfile;
  final Profile matchProfile;
  final VoidCallback onContinue;
  final VoidCallback onMessage;

  const MatchAnimationDialog({
    super.key,
    required this.userProfile,
    required this.matchProfile,
    required this.onContinue,
    required this.onMessage,
  });

  static Future<void> show({
    required BuildContext context,
    required Profile userProfile,
    required Profile matchProfile,
    required VoidCallback onContinue,
    required VoidCallback onMessage,
  }) async {
    // Show haptic feedback on entry
    HapticFeedback.heavyImpact();

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation1, animation2) {
        return MatchAnimationDialog(
          userProfile: userProfile,
          matchProfile: matchProfile,
          onContinue: onContinue,
          onMessage: onMessage,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            )),
            child: child,
          ),
        );
      },
    );
  }

  @override
  _MatchAnimationDialogState createState() => _MatchAnimationDialogState();
}

class _MatchAnimationDialogState extends State<MatchAnimationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _matchTextAnimation;
  late Animation<double> _profilePhotosAnimation;
  late Animation<double> _buttonsAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _matchTextAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
    ).drive(Tween<double>(begin: 0.0, end: 1.0));

    _profilePhotosAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack),
    ).drive(Tween<double>(begin: 0.0, end: 1.0));

    _buttonsAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ).drive(Tween<double>(begin: 0.0, end: 1.0));

    _buttonsAnimation.addListener(() {
      if (_buttonsAnimation.value > 0.01 && _buttonsAnimation.value < 0.1) {
        HapticFeedback.lightImpact();
      }
    });

    _controller.forward().whenComplete(() {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Set<String> userInterests =
        widget.userProfile.interests.map((i) => i.toLowerCase()).toSet();
    final Set<String> matchInterests =
        widget.matchProfile.interests.map((i) => i.toLowerCase()).toSet();
    final List<String> commonInterests =
        userInterests.intersection(matchInterests).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 25,
              gravity: 0.2,
              emissionFrequency: 0.05,
              maxBlastForce: 20,
              minBlastForce: 10,
              particleDrag: 0.05,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow
              ],
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 120,
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                        child: AnimatedTextKit(
                          totalRepeatCount: 1,
                          pause: const Duration(milliseconds: 500),
                          animatedTexts: [
                            WavyAnimatedText("It's a Match!"),
                          ],
                          displayFullTextOnTap: true,
                          stopPauseOnTap: true,
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: _matchTextAnimation.value.clamp(0.0, 1.0),
                      child: Text(
                        "You and ${widget.matchProfile.name} like each other",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    if (commonInterests.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Opacity(
                          opacity: _matchTextAnimation.value.clamp(0.0, 1.0),
                          child: Text(
                            commonInterests.length == 1
                                ? "You both like ${commonInterests.first}!"
                                : "You both like: ${commonInterests.join(', ')}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                    Opacity(
                      opacity: _profilePhotosAnimation.value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.7 + (_profilePhotosAnimation.value * 0.3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.translate(
                              offset: Offset(
                                  -80 * (1 - _profilePhotosAnimation.value), 0),
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: widget
                                            .userProfile.photoUrls.isNotEmpty
                                        ? NetworkImage(
                                            widget.userProfile.photoUrls.first)
                                        : const AssetImage(
                                                'assets/images/default_profile.png')
                                            as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(
                                  80 * (1 - _profilePhotosAnimation.value), 0),
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: widget
                                            .matchProfile.photoUrls.isNotEmpty
                                        ? NetworkImage(
                                            widget.matchProfile.photoUrls.first)
                                        : const AssetImage(
                                                'assets/images/default_profile.png')
                                            as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    Opacity(
                      opacity: _buttonsAnimation.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, 50 * (1 - _buttonsAnimation.value)),
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: widget.onMessage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 48, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 8,
                                shadowColor: AppColors.primary.withOpacity(0.5),
                              ),
                              child: const Text(
                                'Send a Message',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: widget.onContinue,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 12),
                              ),
                              child: const Text(
                                'Keep Swiping',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
