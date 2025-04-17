import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';
import 'auth_service.dart'; // Import AuthService to access refreshToken
import '../providers/auth_provider.dart'; // Import AuthState and authStateProvider
import '../providers/providers.dart'; // For dioProvider
import '../utils/constants.dart';

/// API Client for handling HTTP requests
class ApiClient {
  final Dio _dio;
  final Ref _ref;

  ApiClient(this._ref, this._dio) {
    // Configure interceptors if needed
    _setupInterceptors();
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    // Add logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      requestHeader: true,
      responseHeader: true,
      request: true,
    ));

    // Add error interceptor for handling connection errors
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        print("API Error: ${error.message}");
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          // Handle timeout errors
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: "Connection timed out. Please check your internet connection.",
              type: error.type,
            ),
          );
        }
        
        if (error.error is SocketException) {
          // Handle network errors
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: "No internet connection. Please check your network settings.",
              type: error.type,
            ),
          );
        }

        // Handle auth errors (401)
        if (error.response?.statusCode == 401) {
          print("Unauthorized access. Token may have expired.");
          // You could trigger a refresh token workflow here
          // or clear auth state and redirect to login
        }
        
        // Continue with the error
        return handler.next(error);
      },
    ));
  }

  // Convenience methods for API calls
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.put(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.patch(path, data: data, queryParameters: queryParameters, options: options);
  }
}

// Provider for FlutterSecureStorage
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Provider for the Dio instance
final dioProvider = Provider<Dio>((ref) {
  // Use the ApiClient's dio instance
  return ref.watch(apiClientProvider).dio;
});

// Interceptor to handle adding auth token and refreshing it
class AuthInterceptor extends Interceptor {
  final Ref ref;

  AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip adding token for auth endpoints
    if (options.path.startsWith('/auth/')) {
      print('Skipping token for auth path: ${options.path}');
      return handler.next(options);
    }

    print('Adding token for path: ${options.path}');
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: 'auth_token');

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      print('Token added.');
    } else {
      print('No token found for request.');
      // Potentially reject the request if token is mandatory and missing
      // return handler.reject(DioException(requestOptions: options, message: 'Auth token missing'));
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    print('onError interceptor: ${err.response?.statusCode}');
    if (err.response?.statusCode == 401) {
      print('Handling 401 error...');
      // If a 401 response is received, attempt to refresh the token
      final authService = ref.read(authServiceProvider); // Access AuthService
      final bool refreshed = await authService.refreshToken();

      if (refreshed) {
        print('Token refreshed successfully. Retrying request...');
        // If refresh successful, retry the original request with the new token
        try {
          final dio = ref.read(dioProvider); // Get dio instance
          // Clone the request options and retry
          final response = await dio.request(
            err.requestOptions.path,
            data: err.requestOptions.data,
            queryParameters: err.requestOptions.queryParameters,
            options: Options(
              method: err.requestOptions.method,
              headers: err.requestOptions.headers, // Headers will be updated by onRequest
            ),
          );
          print('Retry successful.');
          // Return the new response
          return handler.resolve(response);
        } catch (retryError) {
          print('Retry failed after token refresh: $retryError');
          // If retry also fails, pass the error along
          // Optionally logout user if retry fails
          await ref.read(authStateProvider.notifier).logout();
          return handler.reject(DioException(
            requestOptions: err.requestOptions,
            error: retryError,
            message: 'Retry failed after token refresh'
          ));
        }
      } else {
         print('Token refresh failed. Logging out.');
         // If refresh fails, logout the user and reject the request
         await ref.read(authStateProvider.notifier).logout();
         return handler.reject(err);
      }
    }
    // For other errors, pass them along
    return handler.next(err);
  }
} 