import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';

// Provider for secure storage
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Provider for Dio HTTP client
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ),
  );

  // Add logging interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        logger.debug('REQUEST[${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        logger.debug('RESPONSE[${response.statusCode}] <= PATH: ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        logger.error('ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
        return handler.next(e);
      },
    ),
  );

  // Add auth token interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get the secure storage instance
        final storage = ref.read(secureStorageProvider);
        
        // Read token from secure storage
        final token = await storage.read(key: 'auth_token');
        
        // If token exists, add it to the headers
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          logger.debug('Added auth token to request');
        }
        
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Check if error is due to unauthorized (token expired)
        if (e.response?.statusCode == 401) {
          logger.warning('Got 401 response, attempting token refresh');
          
          // Get the secure storage instance
          final storage = ref.read(secureStorageProvider);
          
          // Try to refresh token
          final refreshToken = await storage.read(key: 'refresh_token');
          
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              // Create a new Dio instance for refresh request to avoid interceptor loop
              final refreshDio = Dio();
              refreshDio.options.baseUrl = AppConfig.apiBaseUrl;
              
              final refreshResponse = await refreshDio.post(
                '/auth/refresh',
                data: {'refreshToken': refreshToken},
              );
              
              if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
                // Extract new tokens
                final newToken = refreshResponse.data['token'];
                final newRefreshToken = refreshResponse.data['refreshToken'];
                
                // Save new tokens
                await storage.write(key: 'auth_token', value: newToken);
                await storage.write(key: 'refresh_token', value: newRefreshToken);
                
                // Retry original request with new token
                final options = e.requestOptions;
                options.headers['Authorization'] = 'Bearer $newToken';
                
                // Create a new request with the updated token
                final response = await dio.fetch(options);
                
                // Return the response of the retried request
                return handler.resolve(response);
              }
            } catch (refreshError) {
              logger.error('Token refresh failed: $refreshError');
              // Continue with original error
            }
          }
        }
        
        // Continue with original error
        return handler.next(e);
      },
    ),
  );

  return dio;
}); 