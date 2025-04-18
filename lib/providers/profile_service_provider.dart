import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import the canonical providers from providers.dart
import 'providers.dart' show dioProvider, sharedPreferencesProvider;

// This is the canonical provider for ProfileService
// It's used to provide the ProfileService instance to other providers and widgets
final profileServiceProvider = Provider<ProfileService>((ref) {
  final dio = ref.watch(dioProvider);
  
  // Use existing shared preferences provider from providers.dart
  final prefs = ref.read(sharedPreferencesProvider);
  
  return ProfileService(dio, prefs);
});

// Removing duplicate SharedPreferences provider since it's already defined in providers.dart
// Shared preferences provider
// final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
//   throw UnimplementedError('SharedPreferences provider must be overridden before use');
// }); 