import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/premium_provider.dart';
import '../../screens/settings/premium_screen.dart';

class PremiumBanner extends ConsumerWidget {
  final String message;
  final bool compact;

  const PremiumBanner({
    Key? key,
    this.message = 'Unlock premium features to enhance your dating experience!',
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumProvider);
    
    // Don't show banner if user is already premium
    if (isPremium) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PremiumScreen()),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: compact ? 8.0 : 16.0,
          vertical: compact ? 4.0 : 8.0,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12.0 : 16.0,
          vertical: compact ? 8.0 : 12.0,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9945), Color(0xFFFF5445)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(compact ? 8.0 : 12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.star,
              color: Colors.white,
              size: compact ? 20.0 : 24.0,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 12.0 : 14.0,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: compact ? 16.0 : 18.0,
            ),
          ],
        ),
      ),
    );
  }
} 