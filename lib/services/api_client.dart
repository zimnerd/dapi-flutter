import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

/// Auth Interceptor for handling token authentication
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  final AuthService? authService; // Renamed from _authService
  final Logger _logger = Logger('Auth');
  final Dio _refreshDio = Dio(); // Separate Dio instance for token refresh
  bool _isRefreshing = false;
  final List<RequestOptions> _pendingRequests = [];

  AuthInterceptor(this._secureStorage, [this.authService]);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Make sure base URL is set
    if (options.baseUrl.isEmpty && !options.path.startsWith('http')) {
      options.baseUrl = AppConfig.apiBaseUrl;
      
      // Fix double slash issue
      if (options.path.startsWith('/') && options.baseUrl.endsWith('/')) {
        options.path = options.path.substring(1);
      }
    }
    
    // Add auth header if not already present
    if (!options.headers.containsKey('Authorization')) {
      final token = await _secureStorage.read(key: AppStorageKeys.token);
      if (token != null && token.isNotEmpty) {
        _logger.debug('Adding token to request: ${maskToken(token)}');
        options.headers['Authorization'] = '${AppHeaders.bearer} $token';
      } else {
        _logger.debug('No token available for request to ${options.path}');
      }
    }
    
    // Default headers
    options.headers.putIfAbsent('Content-Type', () => AppHeaders.applicationJson);
    options.headers.putIfAbsent('Accept', () => AppHeaders.applicationJson);
    
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 - try token refresh
    if (err.response?.statusCode == 401 && 
        !err.requestOptions.path.contains(AppEndpoints.refresh) &&
        !err.requestOptions.path.contains(AppEndpoints.login)) {
      _logger.debug('Received 401 error for ${err.requestOptions.path}, attempting token refresh');
      
      final refreshedRequest = await _refreshTokenAndRetry(err.requestOptions);
      if (refreshedRequest != null) {
        _logger.debug('Request retried successfully after token refresh');
        return handler.resolve(refreshedRequest);
      } else {
        _logger.error('Token refresh failed, propagating original 401 error');
      }
    }
    return handler.next(err);
  }

  Future<Response<dynamic>?> _refreshTokenAndRetry(RequestOptions requestOptions) async {
    // Store the pending request
    _pendingRequests.add(requestOptions);
    _logger.debug('Added request to pending queue: ${requestOptions.path}');
    
    // Only refresh once if multiple requests fail simultaneously
    if (!_isRefreshing) {
      _isRefreshing = true;
      _logger.debug('Starting token refresh process');
      
      try {
        bool refreshSuccess = false;
        
        // Use AuthService's refreshToken if available (preferred method)
        if (authService != null) {
          _logger.debug('Using AuthService to refresh token');
          refreshSuccess = await authService!.refreshToken();
        } else {
          // Fallback to direct token refresh if AuthService not available
          _logger.debug('Using direct token refresh (AuthService not provided)');
          refreshSuccess = await _refreshTokenDirectly();
        }
        
        if (refreshSuccess) {
          _logger.debug('Token refresh succeeded, retrying pending requests (${_pendingRequests.length})');
          // Process all pending requests with new token
          final result = await _retryPendingRequests(requestOptions);
          _isRefreshing = false;
          return result;
        } else {
          _logger.error('Token refresh failed, clearing pending requests');
          _isRefreshing = false;
          _handleFailedRefresh();
          return null;
        }
      } catch (e) {
        _logger.error('Exception during token refresh: $e');
        _isRefreshing = false;
        _handleFailedRefresh();
        return null;
      }
    } else {
      // If already refreshing, wait for it to complete
      _logger.debug('Token refresh already in progress, waiting...');
      int attempts = 0;
      while (_isRefreshing && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }
      
      // If successful, this request will be retried with the new token
      // If failed, return null to let the original error propagate
      if (!_isRefreshing && !_pendingRequests.contains(requestOptions)) {
        _logger.debug('Token refresh completed while waiting');
        return null; // Refresh was successful and request was processed
      } else {
        _logger.error('Timeout waiting for token refresh after ${attempts * 500}ms');
        // Clear request from pending list to avoid memory leaks
        _pendingRequests.remove(requestOptions);
        return null;
      }
    }
  }
  
  // Legacy direct token refresh method
  Future<bool> _refreshTokenDirectly() async {
    try {
      final refreshToken = await _secureStorage.read(key: AppStorageKeys.refreshToken);
      
      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.error('No refresh token found for direct refresh');
        return false;
      }
      
      _logger.debug('Making direct token refresh request with token: ${maskToken(refreshToken)}');
      
      // Make refresh token request using the correct endpoint
      final refreshUrl = '${AppConfig.apiBaseUrl}${AppEndpoints.refresh}';
      final refreshResponse = await _refreshDio.post(
        refreshUrl,
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {
            'Content-Type': AppHeaders.applicationJson,
            'Accept': AppHeaders.applicationJson,
          }
        ),
      );
      
      _logger.debug('Refresh response status: ${refreshResponse.statusCode}');
      
      if (refreshResponse.statusCode == 200 && 
          refreshResponse.data is Map<String, dynamic>) {
        
        // Try different property names
        final data = refreshResponse.data as Map<String, dynamic>;
        
        // Check for token in root or nested in data field
        final newToken = data['accessToken'] ?? 
                        data['token'] ?? 
                        (data['data'] is Map ? data['data']['token'] : null);
        
        final newRefreshToken = data['refreshToken'] ?? 
                              data['refresh_token'] ?? 
                              (data['data'] is Map ? data['data']['refreshToken'] : null) ??
                              refreshToken; // Fallback to same refresh token
        
        if (newToken != null) {
          // Store new tokens
          await _secureStorage.write(key: AppStorageKeys.token, value: newToken);
          await _secureStorage.write(key: AppStorageKeys.refreshToken, value: newRefreshToken);
          await _secureStorage.write(key: AppStorageKeys.accessToken, value: newToken);
          
          _logger.debug('Token refreshed successfully: ${maskToken(newToken)}');
          return true;
        } else {
          _logger.error('Token refresh response missing token field: ${data.keys}');
          return false;
        }
      } else {
        _logger.error('Token refresh failed with status: ${refreshResponse.statusCode}');
        if (refreshResponse.data != null) {
          _logger.error('Response data: ${refreshResponse.data}');
        }
        return false;
      }
    } on DioException catch (e) {
      _logger.error('Dio error during direct token refresh: ${e.message}');
      if (e.response != null) {
        _logger.error('Response status: ${e.response?.statusCode}');
        _logger.error('Response data: ${e.response?.data}');
      }
      return false;
    } catch (e) {
      _logger.error('Error during direct token refresh: $e');
      return false;
    }
  }
  
  // Process all pending requests with the new token
  Future<Response> _retryPendingRequests(RequestOptions originalRequest) async {
    Response? originalResponse;
    
    try {
      // Get the new token
      final token = await _secureStorage.read(key: AppStorageKeys.token);
      if (token == null || token.isEmpty) {
        throw Exception('No token available after refresh');
      }
      
      _logger.debug('Retrying ${_pendingRequests.length} requests with new token');
      
      // Process all pending requests with new token
      final List<Future<Response>> responses = [];
      final List<RequestOptions> requests = List.from(_pendingRequests);
      _pendingRequests.clear();
      
      for (final pendingRequest in requests) {
        // Clone the original request with new token
        final updatedRequest = Options(
          method: pendingRequest.method,
          headers: {
            ...pendingRequest.headers,
            'Authorization': '${AppHeaders.bearer} $token',
          },
        );
        
        // Create new Dio instance for retry to avoid interceptors loop
        final retryDio = Dio();
        
        // Retry the original request
        final retryUrl = pendingRequest.uri.toString();
        _logger.debug('Retrying request: ${pendingRequest.method} $retryUrl');
        
        final responseFuture = retryDio.request(
          retryUrl,
          data: pendingRequest.data,
          queryParameters: pendingRequest.queryParameters,
          options: updatedRequest,
        );
        
        responses.add(responseFuture);
        
        // If this is the original request we're interested in, save its response
        if (pendingRequest.uri.toString() == originalRequest.uri.toString() &&
            pendingRequest.method == originalRequest.method) {
          originalResponse = await responseFuture;
        }
      }
      
      // Wait for all retries to complete
      await Future.wait(responses);
      
      // Return the response for the original request
      if (originalResponse != null) {
        return originalResponse;
      }
      
      // If we somehow didn't get the original response, throw an error
      throw Exception('Failed to retry the original request after token refresh');
      
    } catch (e) {
      _logger.error('Error retrying requests after token refresh: $e');
      throw e;
    }
  }
  
  void _handleFailedRefresh() {
    // Clear pending requests
    _pendingRequests.clear();
    
    // Clear tokens on failed refresh
    _secureStorage.delete(key: AppStorageKeys.token);
    _secureStorage.delete(key: AppStorageKeys.refreshToken);
    _secureStorage.delete(key: AppStorageKeys.accessToken);
    
    // Log the failure
    _logger.warn('Token refresh failed - user needs to log in again');
  }
  
  // Helper to mask token for logging
  String maskToken(String token) {
    if (token.length > 10) {
      return '${token.substring(0, 5)}...${token.substring(token.length - 5)}';
    }
    return '***';
  }
  
  int min(int a, int b) => a < b ? a : b;
}

/// API Client for handling HTTP requests
class ApiClient {
  final Dio _dio;
  final bool _enableLogging;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Logger _logger = Logger('ApiClient');
  final AuthService? authService;

  ApiClient(this._dio, {
    bool enableLogging = true,
    this.authService,
  }) : _enableLogging = enableLogging {
    _setupInterceptors();
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.clear();
    
    // Add auth interceptor with optional AuthService reference
    _dio.interceptors.add(AuthInterceptor(_secureStorage, authService));
    
    // Add logging interceptor in debug mode
    if (_enableLogging && kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (object) => print('⟹ [Dio] $object'),
        ),
      );
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<String> uploadFile(String endpoint, String filePath, {String? fileName}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post(endpoint, data: formData);
      return _handleResponse(response)['url'];
    } on DioException catch (e) {
      _logger.error('File upload failed: ${e.message}');
      rethrow;
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      return response.data;
    }
    if (response.data is List) {
      return {'data': response.data};
    }
    return {'data': response.data};
  }

  void _handleError(DioException e) {
    Map<String, dynamic> errorDetails = {
      'url': e.requestOptions.uri.toString(),
      'method': e.requestOptions.method,
      'statusCode': e.response?.statusCode,
    };
    
    if (e.type == DioExceptionType.connectionTimeout || 
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      _logger.error('Network timeout: ${e.message}');
      throw Exception(Constants.ERROR_NETWORK);
    } else if (e.response?.statusCode == Constants.statusCodeUnauthorized) {
      _logger.error('Unauthorized access: ${e.message}');
      
      // Check if this is due to a missing token
      if (e.response?.data is Map && 
          e.response?.data['code'] == 'AUTH_HEADER_MISSING') {
        _logger.error('Authentication required - missing token');
        throw Exception('Authentication required. Please log in and try again.');
      } else {
        _logger.error('Token might be expired or invalid');
        throw Exception(Constants.ERROR_UNAUTHORIZED);
      }
    } else if (e.response?.statusCode == Constants.statusCodeNotFound) {
      _logger.error('Resource not found: ${e.message}');
      throw Exception('Resource not found');
    } else if (e.response?.statusCode == Constants.statusCodeServerError) {
      _logger.error('Server error: ${e.message}');
      throw Exception(Constants.ERROR_SERVER);
    } else if (e.type == DioExceptionType.connectionError) {
      _logger.error('Connection error: ${e.message}');
      throw Exception(Constants.ERROR_NETWORK);
    }
    
    // Extract server error message if possible
    String errorMessage = Constants.ERROR_GENERIC;
    if (e.response?.data is Map) {
      final errorData = e.response!.data as Map;
      if (errorData.containsKey('message')) {
        errorMessage = errorData['message'] as String;
      } else if (errorData.containsKey('error')) {
        errorMessage = errorData['error'] as String;
      }
    }
    
    _logger.error('API Error: $errorMessage');
    throw Exception(errorMessage);
  }
}