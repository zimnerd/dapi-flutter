import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/colors.dart';

class TypingIndicator extends ConsumerStatefulWidget {
  final bool isTyping;
  final String userName;
  
  const TypingIndicator({
    Key? key,
    required this.isTyping,
    this.userName = '',
  }) : super(key: key);

  @override
  ConsumerState<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends ConsumerState<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _dotAnimations;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _dotAnimations = List.generate(3, (index) {
      final begin = index * 0.2;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            begin,
            begin + 0.5,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isTyping) {
      return const SizedBox.shrink();
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: widget.isTyping ? 40 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.userName.isNotEmpty) ...[
            Text(
              '${widget.userName} is typing',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
          ],
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(
                        0.3 + (_dotAnimations[index].value * 0.7),
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
} 