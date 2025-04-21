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
import '../config/app_config.dart';

// Import auth provider
import './auth_provider.dart';

// Import models
import '../models/conversation.dart';

// Export auth providers
export './auth_provider.dart'
    show
        AuthState,
        AuthNotifier,
        AuthStatus,
        authStateProvider,
        userIdProvider,
        userEmailProvider,
        userNameProvider;

// --- Core Services ---

// Secure storage provider - moved up to break circular dependency
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Shared preferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized before use');
});

// Dio provider for HTTP client - with simpler interceptor to avoid circular dependency
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  final secureStorage = ref.read(secureStorageProvider);

  // Set base URL for all requests
  dio.options.baseUrl = AppConfig.apiBaseUrl;

  // Set default timeouts
  dio.options.connectTimeout =
      Duration(milliseconds: AppConfig.networkTimeoutMs);
  dio.options.receiveTimeout =
      Duration(milliseconds: AppConfig.networkTimeoutMs);
  dio.options.sendTimeout = Duration(milliseconds: AppConfig.networkTimeoutMs);

  // Set default headers
  dio.options.headers = {
    AppHeaders.contentType: 'application/json',
    AppHeaders.accept: 'application/json',
  };

  // Request interceptor to add authentication token
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Try to get the token
        final token = await secureStorage.read(key: AppStorageKeys.accessToken);

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print('⟹ [Dio] Adding auth token to request: ${maskToken(token)}');
        }

        // Fix double slashes in URL
        if (options.path.startsWith('/') && options.baseUrl.endsWith('/')) {
          options.path = options.path.substring(1);
        }

        print('⟹ [Dio] Request URL: ${options.baseUrl}${options.path}');
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          print(
              '⟹ [Dio] Received 401 error for ${error.requestOptions.path}, attempting token refresh');

          try {
            // Get secure storage for tokens
            final refreshToken =
                await secureStorage.read(key: AppStorageKeys.refreshToken);

            if (refreshToken == null || refreshToken.isEmpty) {
              print('⟹ [Dio] No refresh token available');
              // Directly remove tokens from secure storage instead of calling logout
              await secureStorage.delete(key: AppStorageKeys.accessToken);
              await secureStorage.delete(key: AppStorageKeys.refreshToken);
              await secureStorage.delete(key: AppStorageKeys.token);
              print('⟹ [Dio] Tokens cleared from secure storage');
              return handler.next(error);
            }

            // Create a new Dio instance for token refresh to avoid interceptor loops
            final refreshDio = Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout:
                  Duration(milliseconds: AppConfig.networkTimeoutMs),
              receiveTimeout:
                  Duration(milliseconds: AppConfig.networkTimeoutMs),
              headers: {
                'Content-Type': AppHeaders.applicationJson,
                'Accept': AppHeaders.applicationJson,
              },
            ));

            // Attempt to refresh token - using the path from AppEndpoints
            final refreshUrl = AppEndpoints.refresh;
            print(
                '⟹ [Dio] Making token refresh request to: ${refreshDio.options.baseUrl}$refreshUrl');

            final response = await refreshDio.post(
              refreshUrl,
              data: {
                'refreshToken': refreshToken,
              },
            );

            print(
                '⟹ [Dio] Token refresh response status: ${response.statusCode}');

            // Check response and handle all possible token formats
            if (response.statusCode == 200 || response.statusCode == 201) {
              Map<String, dynamic> data = response.data;

              // Check for token in root or nested in data field
              final newToken = data['accessToken'] ??
                  data['token'] ??
                  (data['data'] is Map ? data['data']['token'] : null);

              final newRefreshToken = data['refreshToken'] ??
                  data['refresh_token'] ??
                  (data['data'] is Map ? data['data']['refreshToken'] : null) ??
                  refreshToken; // Fallback to same refresh token

              if (newToken != null) {
                // Store tokens
                await secureStorage.write(
                    key: AppStorageKeys.token, value: newToken);
                await secureStorage.write(
                    key: AppStorageKeys.refreshToken, value: newRefreshToken);
                await secureStorage.write(
                    key: AppStorageKeys.accessToken, value: newToken);

                print('⟹ [Dio] Token refresh successful, retrying request');

                // Clone the original request with the new token
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newToken';

                // Create a new request with the updated token
                final opts = Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                );

                final retryResponse = await dio.request(
                  error.requestOptions.path,
                  options: opts,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );

                return handler.resolve(retryResponse);
              } else {
                print(
                    '⟹ [Dio] Token refresh failed - missing token in response');
                print('⟹ [Dio] Response data keys: ${data.keys.toList()}');
              }
            } else {
              print(
                  '⟹ [Dio] Token refresh failed with status: ${response.statusCode}');
            }

            // If we reach here, token refresh failed - directly clean up tokens
            await secureStorage.delete(key: AppStorageKeys.accessToken);
            await secureStorage.delete(key: AppStorageKeys.refreshToken);
            await secureStorage.delete(key: AppStorageKeys.token);
            print(
                '⟹ [Dio] Tokens cleared from secure storage after failed refresh');
          } catch (e) {
            print('⟹ [Dio] Error during token refresh: $e');
            // Also clean tokens on any error during refresh process
            try {
              await secureStorage.delete(key: AppStorageKeys.accessToken);
              await secureStorage.delete(key: AppStorageKeys.refreshToken);
              await secureStorage.delete(key: AppStorageKeys.token);
              print('⟹ [Dio] Tokens cleared after refresh error');
            } catch (cleanupError) {
              print('⟹ [Dio] Error cleaning up tokens: $cleanupError');
            }
          }
        }

        return handler.next(error);
      },
    ),
  );

  // Add logging interceptor
  dio.interceptors.add(LogInterceptor(
    request: true,
    requestHeader: true,
    requestBody: true,
    responseHeader: false,
    responseBody: true,
    error: true,
    logPrint: (object) => print('⟹ [Dio] $object'),
  ));

  return dio;
});

// Helper function to mask token for logging
String maskToken(String token) {
  if (token.length > 10) {
    return '${token.substring(0, 5)}...${token.substring(token.length - 5)}';
  }
  return '***';
}

// We need to first create a base API client without auth service
final baseApiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio); // Create without auth service first
});

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthService(dio, secureStorage, prefs);
});

// Enhanced API Client provider with auth service
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  final authService = ref.watch(authServiceProvider);
  return ApiClient(dio, authService: authService);
});

// Profile Service Provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  final dio = ref.watch(dioProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProfileService(dio, prefs);
});

// Chat Service Provider
final chatServiceProvider = Provider<ChatService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final chatService = ChatService();

  // Initialize right away with the auth service
  chatService.initializeAuthService(authService);
  print('ChatService initialized with AuthService in provider');

  return chatService;
});

// Provider for incoming messages stream
final messageStreamProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.onNewMessage;
});

// Provider for typing status changes stream
// Data structure: Map<String, bool> where key is senderId and value is isTyping
final typingStatusProvider = StreamProvider.autoDispose
    .family<Map<String, bool>, String>((ref, String conversationId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.onTypingEvent.map((data) {
    final relevantStatus = <String, bool>{};
    // Attempt to get participantId safely
    final conversation = ref.read(conversationProvider(conversationId));
    final currentUserId = ref.read(userIdProvider);

    // Find the participant ID if conversation and participants exist
    String? participantId;
    if (conversation != null && conversation.participants.isNotEmpty) {
      try {
        // Find participant who is NOT the current user
        participantId = conversation.participants
            .firstWhere((p) => p.id != currentUserId)
            .id;
      } catch (e) {
        // Handle cases where current user might be the only participant listed, or list is malformed
        print(
            "Could not find other participant in conversation ${conversation.id}: $e");
        // Optionally, take the first participant if only one exists
        if (conversation.participants.length == 1 &&
            conversation.participants.first.id != currentUserId) {
          participantId = conversation.participants.first.id;
        }
      }
    }

    if (participantId != null &&
        data.containsKey('userId') &&
        data.containsKey('isTyping')) {
      if (data['userId'] == participantId) {
        relevantStatus[participantId] = data['isTyping'];
      }
    }
    return relevantStatus;
  });
});

// Provider to get a specific conversation (needed for typingStatusProvider filter)
final conversationProvider =
    Provider.autoDispose.family<Conversation?, String>((ref, conversationId) {
  final conversationsState = ref.watch(conversationsProvider);
  return conversationsState.whenData((conversations) {
    try {
      // Ensure 'c' is treated as Conversation before accessing 'id'
      return conversations.firstWhere((c) => (c).id == conversationId);
    } catch (e) {
      return null;
    }
  }).value;
});

// Provider for all conversations
final conversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final chatService = ref.watch(chatServiceProvider);
  final dynamicList = await chatService.getConversations();
  // Convert dynamic list to List<Conversation>
  return dynamicList.map((data) => Conversation.fromJson(data)).toList();
});

// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// --- App State Providers ---

// Premium Status Provider (returns AsyncValue<bool>)
final premiumProvider = FutureProvider<bool>((ref) async {
  // Implement premium status check
  await Future.delayed(Duration(milliseconds: 500));
  return false; // Default to non-premium
});

// User ID Provider - convenience accessor
final userIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).user?.id;
});

// User Email Provider - convenience accessor
final userEmailProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).user?.email;
});

// User Name Provider - convenience accessor
final userNameProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).user?.name;
});

// Note: Other specific feature providers (like chat, discover, profile edit)
// should ideally remain in their own files (e.g., chat_provider.dart)
// and import this file if they need core services or auth state.
