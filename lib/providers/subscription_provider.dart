import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple state provider to simulate premium status.
//
// In a real app, this would likely be a more complex StateNotifierProvider
// that fetches the subscription status from a backend service upon login
// and potentially listens for real-time updates.
//
// For now, change the boolean value here to test premium/non-premium UI states.
final premiumStatusProvider = StateProvider<bool>((ref) {
  // --- Set this to true or false for testing --- 
  return true; 
  // -----------------------------------------------
}); 