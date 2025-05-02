import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logger.dart';
import '../services/subscription_service.dart';

final Logger _logger = Logger('PremiumProvider');

/// Provider that exposes the user's premium status
final premiumProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    _logger.info('[premiumProvider] Checking premium status');
    final subscriptionService = SubscriptionService();
    final isPremium = await subscriptionService.checkPremiumStatus();
    _logger.info('[premiumProvider] Premium status: $isPremium');
    return isPremium;
  } catch (e) {
    _logger.error('[premiumProvider] Error checking premium status: $e');
    return false; // Default to non-premium on error
  }
});

/// Provider that exposes whether a specific premium feature is available to the user
/// This handles both checking premium status and feature-specific availability
final premiumFeaturesProvider = Provider.family<bool, String>((ref, featureId) {
  // Get the premium status
  final premiumStatus = ref.watch(premiumProvider);

  // If still loading, assume not premium
  if (premiumStatus is AsyncLoading) {
    return false;
  }

  // Extract the value or default to false on error
  final isPremium = premiumStatus.value ?? false;

  // Mock feature-specific logic - in a real app, this could check for
  // individually purchased features or different tiers of premium
  switch (featureId) {
    case 'unlimited_swipes':
    case 'see_likes':
    case 'global_mode':
    case 'rewind':
    case 'priority_matching':
      return isPremium;
    // For any feature not in the list, default to false
    default:
      _logger.warn('[premiumProvider] Unknown feature: $featureId');
      return false;
  }
});

// Notifier that will handle premium status changes
class PremiumSubscriptionNotifier extends StateNotifier<bool> {
  final FlutterSecureStorage _storage;

  PremiumSubscriptionNotifier(this._storage) : super(false) {
    // Load premium status when initialized
    _loadPremiumStatus();
  }

  // Load premium status from storage
  Future<void> _loadPremiumStatus() async {
    try {
      final isPremium = await _storage.read(key: 'premium_status');
      state = isPremium == 'true';
      _logger.info('Loaded premium status: $state');
    } catch (e) {
      _logger.error('Error loading premium status: $e');
      state = false;
    }
  }

  // Method to upgrade to premium
  Future<bool> upgradeToPremium() async {
    try {
      // In a real app, this would communicate with a payment service
      // This is just a placeholder
      await _storage.write(key: 'premium_status', value: 'true');
      state = true;
      _logger.info('Upgraded to premium');
      return true;
    } catch (e) {
      _logger.error('Error upgrading to premium: $e');
      return false;
    }
  }

  // Method to cancel premium
  Future<bool> cancelPremium() async {
    try {
      await _storage.write(key: 'premium_status', value: 'false');
      state = false;
      _logger.info('Cancelled premium');
      return true;
    } catch (e) {
      _logger.error('Error cancelling premium: $e');
      return false;
    }
  }

  // Method to check if a feature is available (based on premium status)
  bool canUseFeature(String feature) {
    // List of premium-only features
    const premiumFeatures = [
      'undo',
      'super_like',
      'see_likes',
      'unlimited_likes',
      'passport'
    ];

    // If the feature is premium-only and user is not premium, return false
    if (premiumFeatures.contains(feature) && !state) {
      _logger
          .debug('Premium feature $feature requested but user is not premium');
      return false;
    }

    return true;
  }
}

// Create a provider for the premium subscription notifier
final premiumSubscriptionProvider =
    StateNotifierProvider<PremiumSubscriptionNotifier, bool>((ref) {
  final storage = FlutterSecureStorage();
  return PremiumSubscriptionNotifier(storage);
});
