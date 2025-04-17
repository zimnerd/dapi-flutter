import 'package:flutter/material.dart';
import '../utils/colors.dart'; // Assuming you have AppColors defined

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Go Premium ✨',
          style: TextStyle(
             color: Theme.of(context).brightness == Brightness.light ? AppColors.textPrimary : AppColors.textSecondary,
             fontWeight: FontWeight.bold,
          )
        ),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
        iconTheme: IconThemeData(color: Theme.of(context).brightness == Brightness.light ? AppColors.textPrimary : AppColors.textSecondary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Icon(Icons.star_border_purple500_outlined, size: 80, color: AppColors.primary), // Use primary color for consistency?
            const SizedBox(height: 20),
            Text(
              'Unlock Premium Features!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Supercharge your dating experience and get more matches!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Feature List
            _buildFeatureItem(Icons.swipe_right_alt_outlined, 'Unlimited Swipes', 'Never run out of profiles to see.'),
            _buildFeatureItem(Icons.favorite_border_outlined, 'See Who Likes You', 'Match instantly by seeing who already liked you.'),
            _buildFeatureItem(Icons.undo_outlined, 'Undo Last Swipe', 'Accidentally swiped left? Get a second chance.'),
            _buildFeatureItem(Icons.visibility_outlined, 'Read Receipts', 'Know when your messages have been read.'),
            _buildFeatureItem(Icons.trending_up_outlined, 'Profile Boost (Monthly)', 'Get seen by more people for 30 minutes.'), // Example
            _buildFeatureItem(Icons.no_accounts_outlined, 'Ad-Free Experience', 'Enjoy the app without interruptions.'), // Example

            const SizedBox(height: 40),

            // Mock Subscription Options
             Text(
              'Choose Your Plan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
             const SizedBox(height: 20),
             _buildSubscriptionOption(
                context: context,
                title: '1 Month',
                price: '\$19.99',
                description: '/ month',
                isPopular: false,
                onTap: () => _handlePurchase(context, 'monthly'),
             ),
             const SizedBox(height: 12),
              _buildSubscriptionOption(
                context: context,
                title: '12 Months',
                price: '\$9.99',
                description: '/ month (Save 50%)',
                isPopular: true,
                onTap: () => _handlePurchase(context, 'yearly'),
             ),
              const SizedBox(height: 12),
              _buildSubscriptionOption(
                context: context,
                title: '6 Months',
                price: '\$14.99',
                description: '/ month (Save 25%)',
                isPopular: false,
                onTap: () => _handlePurchase(context, 'half_yearly'),
             ),
            const SizedBox(height: 24),
            Text(
              'Payment will be charged to your account upon confirmation. Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper widget for feature items
  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

   // Helper widget for subscription options
  Widget _buildSubscriptionOption({
    required BuildContext context,
    required String title,
    required String price,
    required String description,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
             color: isPopular ? AppColors.accent : Theme.of(context).dividerColor,
             width: isPopular ? 2 : 1,
          ),
           color: Theme.of(context).cardColor,
        ),
        child: Stack(
           clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(description, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
                Text(price, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
             if (isPopular)
               Positioned(
                 top: -28,
                 right: 10,
                 child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                       color: AppColors.accent,
                       borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('POPULAR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                 ),
               ),
          ],
        ),
      ),
    );
  }

  // Placeholder purchase handler
  void _handlePurchase(BuildContext context, String planId) {
    print("Attempting purchase for plan: $planId");
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscription purchase for $planId not implemented yet.')),
     );
  }

} 