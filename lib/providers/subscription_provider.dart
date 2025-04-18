import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../utils/logger.dart';

// Define subscription tiers
enum SubscriptionTier {
  free,
  premium,
  gold,
}

// Class to hold subscription state
class SubscriptionState {
  final SubscriptionTier tier;
  final DateTime? expiryDate;
  final Map<String, bool> features;

  const SubscriptionState({
    required this.tier,
    this.expiryDate,
    required this.features,
  });

  // Factory for free tier
  factory SubscriptionState.free() {
    return SubscriptionState(
      tier: SubscriptionTier.free,
      features: {
        'unlimitedSwipes': false,
        'seeWhoLikesYou': false,
        'superLikes': false,
        'advanced_filters': false,
        'boost': false,
        'rewind': false,
      },
    );
  }

  // Factory for premium tier
  factory SubscriptionState.premium() {
    final now = DateTime.now();
    return SubscriptionState(
      tier: SubscriptionTier.premium,
      expiryDate: DateTime(now.year, now.month + 1, now.day), // 1 month from now
      features: {
        'unlimitedSwipes': true,
        'seeWhoLikesYou': true,
        'superLikes': true,
        'advanced_filters': true,
        'boost': true,
        'rewind': true,
      },
    );
  }

  // Factory for gold tier
  factory SubscriptionState.gold() {
    final now = DateTime.now();
    return SubscriptionState(
      tier: SubscriptionTier.gold,
      expiryDate: DateTime(now.year, now.month + 1, now.day), // 1 month from now
      features: {
        'unlimitedSwipes': true,
        'seeWhoLikesYou': true,
        'superLikes': true,
        'advanced_filters': true,
        'boost': true,
        'rewind': true,
        'priorityMatches': true,
        'incognitoMode': true,
      },
    );
  }

  // Check if a feature is available
  bool hasFeature(String featureName) {
    return features[featureName] ?? false;
  }

  // Check if subscription is still valid
  bool get isValid {
    if (tier == SubscriptionTier.free) return true;
    return expiryDate != null && expiryDate!.isAfter(DateTime.now());
  }

  // Check if premium or higher
  bool get isPremium {
    return tier == SubscriptionTier.premium || tier == SubscriptionTier.gold;
  }

  // Check if gold tier
  bool get isGold {
    return tier == SubscriptionTier.gold;
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'tier': tier.toString(),
      'expiryDate': expiryDate?.toIso8601String(),
      'features': features,
    };
  }

  // Create from JSON
  factory SubscriptionState.fromJson(Map<String, dynamic> json) {
    return SubscriptionState(
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.toString() == json['tier'],
        orElse: () => SubscriptionTier.free,
      ),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      features: Map<String, bool>.from(json['features'] ?? {}),
    );
  }
}

// Subscription state notifier
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final FlutterSecureStorage _storage;

  SubscriptionNotifier(this._storage) : super(SubscriptionState.free()) {
    _loadSubscription();
  }

  // Load the subscription from secure storage
  Future<void> _loadSubscription() async {
    try {
      final data = await _storage.read(key: 'subscription');
      if (data != null) {
        final json = jsonDecode(data) as Map<String, dynamic>;
        state = SubscriptionState.fromJson(json);
        
        // Check if subscription is expired
        if (state.expiryDate != null && state.expiryDate!.isBefore(DateTime.now())) {
          state = SubscriptionState.free();
          await _saveSubscription();
          final logger = Logger('SubscriptionProvider');
          logger.info('Subscription expired, downgraded to free');
        } else {
          final logger = Logger('SubscriptionProvider');
          logger.info('Loaded subscription: ${state.tier}');
        }
      } else {
        final logger = Logger('SubscriptionProvider');
        logger.info('No subscription found, using free tier');
      }
    } catch (e) {
      final logger = Logger('SubscriptionProvider');
      logger.error('Error loading subscription: $e');
      state = SubscriptionState.free();
    }
  }

  // Save subscription to secure storage
  Future<void> _saveSubscription() async {
    try {
      await _storage.write(
        key: 'subscription',
        value: jsonEncode(state.toJson()),
      );
      final logger = Logger('SubscriptionProvider');
      logger.info('Saved subscription: ${state.tier}');
    } catch (e) {
      final logger = Logger('SubscriptionProvider');
      logger.error('Error saving subscription: $e');
    }
  }

  // Upgrade to premium
  Future<void> upgradeToPremium() async {
    final logger = Logger('SubscriptionProvider');
    logger.info('Upgrading to premium');
    state = SubscriptionState.premium();
    await _saveSubscription();
  }

  // Upgrade to gold
  Future<void> upgradeToGold() async {
    final logger = Logger('SubscriptionProvider');
    logger.info('Upgrading to gold');
    state = SubscriptionState.gold();
    await _saveSubscription();
  }

  // Cancel subscription
  Future<void> cancelSubscription() async {
    final logger = Logger('SubscriptionProvider');
    logger.info('Cancelling subscription');
    state = SubscriptionState.free();
    await _saveSubscription();
  }

  // Restore purchases - would integrate with platform purchase APIs
  Future<bool> restorePurchases() async {
    try {
      final logger = Logger('SubscriptionProvider');
      logger.info('Restoring purchases');
      // Mock implementation - in real app would check with App Store/Play Store
      // Return true if restored successfully
      return Future.value(false);
    } catch (e) {
      final logger = Logger('SubscriptionProvider');
      logger.error('Error restoring purchases: $e');
      return false;
    }
  }
}

// Subscription provider
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier(const FlutterSecureStorage());
}); 