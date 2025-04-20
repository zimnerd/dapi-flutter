import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/premium_provider.dart';
import '../../services/subscription_service.dart';
import '../../utils/logger.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isLoading = false;
  
  Future<void> _subscribeToPremium() async {
    setState(() => _isLoading = true);
    try {
      print('⟹ [PremiumScreen] Initiating premium subscription');
      final subscriptionService = SubscriptionService();
      await subscriptionService.subscribeToPremium('monthly');
      print('⟹ [PremiumScreen] Premium subscription successful');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully subscribed to premium!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('⟹ [PremiumScreen] Error subscribing to premium: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to subscribe: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);
    final hasFeature = ref.watch(premiumFeaturesProvider('unlimited_swipes'));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Membership'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9945), Color(0xFFFF5445)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 48.0,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      isPremium.when(
                        data: (value) => value ? 'You are a Premium Member!' : 'Upgrade to Premium',
                        loading: () => 'Loading...',
                        error: (_, __) => 'Upgrade to Premium',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      isPremium.when(
                        data: (value) => value
                            ? 'Enjoy all the exclusive features'
                            : 'Unlock the full potential of your dating experience',
                        loading: () => 'Loading your premium status...',
                        error: (_, __) => 'Unlock the full potential of your dating experience',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24.0),
              
              // Features
              const Text(
                'Premium Features',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              
              _buildFeatureCard(
                icon: Icons.autorenew,
                title: 'Unlimited Swipes',
                description: 'Swipe as much as you want without daily limits',
                isActive: hasFeature,
              ),
              
              _buildFeatureCard(
                icon: Icons.visibility,
                title: 'See Who Likes You',
                description: 'Discover users who have already liked your profile',
                isActive: ref.watch(premiumFeaturesProvider('see_likes')),
              ),
              
              _buildFeatureCard(
                icon: Icons.location_on,
                title: 'Global Mode',
                description: 'Match with people from anywhere in the world',
                isActive: ref.watch(premiumFeaturesProvider('global_mode')),
              ),
              
              _buildFeatureCard(
                icon: Icons.history,
                title: 'Rewind Swipes',
                description: 'Go back to profiles you accidentally swiped on',
                isActive: ref.watch(premiumFeaturesProvider('rewind')),
              ),
              
              _buildFeatureCard(
                icon: Icons.star,
                title: 'Priority Matches',
                description: 'Get more visibility and match faster',
                isActive: ref.watch(premiumFeaturesProvider('priority_matching')),
              ),
              
              const SizedBox(height: 24.0),
              
              // Pricing
              if (isPremium is AsyncData && isPremium.value == false) ...[
                const Text(
                  'Pricing',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Monthly Subscription',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        '\$9.99 / month',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5445),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Cancel anytime',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _subscribeToPremium,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5445),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Subscribe Now',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16.0),
                
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12.0),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Annual Subscription',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5445),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: const Text(
                              '50% OFF',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        '\$59.99 / year',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5445),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      const Text(
                        'Only \$4.99 per month',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: _isLoading ? null : () => _subscribeToPremium(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5445),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Subscribe Now',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32.0),
              
              // Info text
              const Text(
                'By subscribing, you agree to our Terms of Service and Privacy Policy. Subscriptions automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12.0,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isActive ? Colors.grey.shade50 : Colors.white,
        border: Border.all(
          color: isActive ? const Color(0xFFFF5445) : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFF5445).withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFFFF5445) : Colors.grey.shade600,
              size: 24.0,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: isActive ? const Color(0xFFFF5445) : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            const Icon(
              Icons.check_circle,
              color: Color(0xFFFF5445),
              size: 24.0,
            ),
        ],
      ),
    );
  }
} 