import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'providers.dart'; // Import providers.dart for dioProvider and authServiceProvider

// We already have a dioProvider in providers.dart, so let's consider this a specialized network provider

// Provider for network connectivity status
final networkStatusProvider = StateProvider<bool>((ref) {
  // Default to true, a real implementation would check connectivity
  return true;
});

// Provider to get API client - this conflicts with the one in providers.dart
// Let's rename it to avoid duplicate provider definition
final networkApiClientProvider = Provider<ApiClient>((ref) {
  // Use the dio instance from providers.dart
  final dio = ref.watch(dioProvider);
  // Use the auth service from providers for token refresh
  final authServiceInstance = ref.read(authServiceProvider);
  return ApiClient(dio, authService: authServiceInstance);
});

// Remove the networkServiceProvider since NetworkService isn't defined
// If needed, create a proper NetworkService class and implement it 