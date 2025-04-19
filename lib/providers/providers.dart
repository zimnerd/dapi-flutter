import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import services
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';
import '../services/unsplash_service.dart';
import '../services/notification_service.dart';
import '../config/app_config.dart';

// Import providers
import './auth_provider.dart';
import './typing_provider.dart';
import './user_providers.dart';
import './chat_provider.dart';
import './socket_connection_provider.dart';
import './offline_message_provider.dart';
import 'offline_message_queue_provider.dart';
import './notification_provider.dart';
import './network_status_provider.dart';
import './message_provider.dart';

// Export auth providers
export './auth_provider.dart' show 
    AuthState, 
    AuthNotifier, 
    AuthStatus,
    authStateProvider, 
    userIdProvider, 
    userEmailProvider, 
    userNameProvider;

// Export socket providers
export './typing_provider.dart' show
    typingUsersProvider;
export '../services/socket_service.dart' show
    socketServiceProvider,
    SocketConnectionStatus;

// Export user providers
export './user_providers.dart' show
    userProviders;

// Export chat providers
export './chat_provider.dart' show
    chatServiceProvider;

// Export socket connection provider
export './socket_connection_provider.dart' show
    socketConnectionProvider;

// Export offline message provider
export './offline_message_provider.dart' show
    offlineMessageProvider;

// Add offline message queue provider export
export 'offline_message_queue_provider.dart';

// Export notification providers
export 'notification_provider.dart';

// Include the network status provider 
export 'network_status_provider.dart';

// Include the message provider
export 'message_provider.dart';

// Include the offline message queue provider
export 'offline_message_queue_provider.dart';

// Include the typing status provider
export 'typing_provider.dart';

// --- Core Services ---

// Secure storage provider - moved up to break circular dependency
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Shared preferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main.dart before runApp');
});

// Provider for SharedPreferences Future (use this during startup)
final sharedPreferencesFutureProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Dio provider for HTTP client - with simpler interceptor to avoid circular dependency
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: 10000),
      receiveTimeout: const Duration(milliseconds: 10000),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add logging interceptor
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (object) => print('⟹ [HTTP] $object'),
  ));

  // Add auth token interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final secureStorage = ref.read(secureStorageProvider);
        final token = await secureStorage.read(key: 'access_token');

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('⟹ [HTTP] Added token: ${maskToken(token)}');
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          print('⟹ [HTTP] 401 Unauthorized - attempting token refresh');
          
          try {
            final authService = ref.read(authServiceProvider);
            final refreshed = await authService.refreshToken();
            
            if (refreshed) {
              print('⟹ [HTTP] Token refreshed, retrying request');
              
              // Clone the request with the new token
              final secureStorage = ref.read(secureStorageProvider);
              final newToken = await secureStorage.read(key: 'access_token');
              
              if (newToken != null) {
                // Create a new request with the updated token
                final opts = Options(
                  method: error.requestOptions.method,
                  headers: {
                    ...error.requestOptions.headers,
                    'Authorization': 'Bearer $newToken',
                  },
                );
                
                // Clone request with the new token
                final response = await dio.request(
                  error.requestOptions.path,
                  options: opts,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );
                
                return handler.resolve(response);
              }
            }
          } catch (e) {
            print('⟹ [HTTP] Token refresh failed: $e');
          }
        }
        
        return handler.next(error);
      },
    ),
  );
  
  return dio;
});

// Helper function to mask token for logging
String maskToken(String token) {
  if (token.length <= 10) {
    return '*' * token.length;
  }
  return '${token.substring(0, 5)}...${token.substring(token.length - 5)}';
}

// --- Service providers ---

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthService(dio, secureStorage, prefs);
});

// API Client provider
final baseApiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});

// API Client provider with auth service
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  final authService = ref.watch(authServiceProvider);
  return ApiClient(dio, authService: authService);
});

// Profile Service Provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileService(apiClient);
});

// Chat Service Provider
final chatServiceProvider = Provider<ChatService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatService(apiClient);
});

// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(secureStorage, prefs);
});

// Unsplash Service Provider
final unsplashServiceProvider = Provider<UnsplashService>((ref) {
  final dio = ref.watch(dioProvider);
  return UnsplashService(dio);
});

// Socket Service Provider (Singleton instance)
final socketServiceProvider = Provider<SocketService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return SocketService(storageService);
});

// Notification Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// --- App State Providers ---

// Premium Status Provider (returns AsyncValue<bool>)
final premiumProvider = FutureProvider<bool>((ref) async {
  // Implement premium status check
  await Future.delayed(Duration(milliseconds: 500));
  return false; // Default to non-premium
});

// Auto-connect socket when authenticated
final socketConnectionProvider = Provider<void>((ref) {
  final authState = ref.watch(authStateProvider);
  final socketService = ref.watch(socketServiceProvider);
  
  // Connect socket when authenticated
  if (authState.status == AuthStatus.authenticated && !socketService.isConnected) {
    socketService.connect();
  }
  
  // Disconnect socket when not authenticated
  if (authState.status != AuthStatus.authenticated && socketService.isConnected) {
    socketService.disconnect();
  }
  
  // No return value needed, this is just for the side effect
  return;
}); 