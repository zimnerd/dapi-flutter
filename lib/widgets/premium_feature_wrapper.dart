import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../screens/premium_screen.dart';

class PremiumFeatureWrapper extends ConsumerWidget {
  final Widget child;
  final String featureName;
  final String description;
  final IconData icon;
  
  const PremiumFeatureWrapper({
    Key? key,
    required this.child,
    required this.featureName,
    required this.description,
    this.icon = Icons.lock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremiumAsync = ref.watch(premiumProvider);
    bool isPremium = false;
    
    // Extract the value from AsyncValue
    isPremiumAsync.whenData((value) {
      isPremium = value;
    });
    
    if (isPremium) {
      return child;
    }
    
    return GestureDetector(
      onTap: () => _showPremiumDialog(context),
      child: Stack(
        children: [
          Opacity(
            opacity: 0.6,
            child: child,
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Icon(
              icon,
              color: Colors.amber,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Text('Premium Feature'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              featureName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PremiumScreen()),
              );
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
} 