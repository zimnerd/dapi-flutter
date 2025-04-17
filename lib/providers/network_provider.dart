import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/dio_provider.dart'; // Import the already created dio provider

// We already have a dioProvider in dio_provider.dart, so let's consider this a specialized network provider

// Provider for network connectivity status
final networkStatusProvider = StateProvider<bool>((ref) {
  // Default to true, a real implementation would check connectivity
  return true;
});

// Provider to get API client
final apiClientProvider = Provider<ApiClient>((ref) {
  // Use the dio instance from dio_provider.dart
  final dio = ref.watch(dioProvider);
  return ApiClient(ref, dio);
});

// Optional: Provider for ApiClient itself if needed elsewhere
// final apiClientProvider = Provider<ApiClient>((ref) {
//    final dio = ref.watch(dioProvider);
//    return ApiClient(dio);
// }); 