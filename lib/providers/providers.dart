import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import services
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../services/api_config.dart';

// Import other provider files
import './auth_provider.dart';

// --- Re-export Auth Providers ---
// This allows importing only this file to access auth-related providers
export './auth_provider.dart' show 
    AuthState, 
    AuthNotifier, 
    authStateProvider, 
    authStatusProvider, 
    currentUserProvider, 
    userIdProvider, 
    userEmailProvider, 
    userNameProvider;

// --- Core Services ---

// Dio provider first to avoid circular dependency
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.apiBaseUrl, // Use the configuration instead of hardcoding the URL
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    contentType: 'application/json',
    responseType: ResponseType.json,
  ));

  // Add basic logging
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

  return dio;
});

// ApiClient Provider (after dioProvider)
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(ref, dio);
});

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthService(dio);
});

// Profile Service Provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileService(dio);
});

// Chat Service Provider
final chatServiceProvider = Provider<ChatService>((ref) {
  final dio = ref.watch(dioProvider);
  return ChatService(dio);
});

// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// --- App State / Feature Providers ---

// Premium Status Provider
final premiumProvider = StateProvider<bool>((ref) => false);

// Note: Other specific feature providers (like chat, discover, profile edit)
// should ideally remain in their own files (e.g., chat_provider.dart)
// and import this file if they need core services or auth state. 