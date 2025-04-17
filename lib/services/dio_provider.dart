import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

// Secure storage provider for storing tokens
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Base Dio provider for HTTP requests
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  
  // Configure Dio with base URL and interceptors
  dio.options.baseUrl = ApiConfig.apiBaseUrl;
  dio.options.connectTimeout = const Duration(seconds: 10);
  dio.options.receiveTimeout = const Duration(seconds: 10);
  
  // Add request interceptor for authentication
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final storage = ref.read(secureStorageProvider);
      final token = await storage.read(key: 'auth_token');
      
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      
      return handler.next(options);
    },
    onError: (error, handler) async {
      // Handle token refresh on 401 errors
      if (error.response?.statusCode == 401) {
        try {
          final storage = ref.read(secureStorageProvider);
          final refreshToken = await storage.read(key: 'refresh_token');
          
          if (refreshToken != null) {
            final refreshDio = Dio();
            refreshDio.options.baseUrl = ApiConfig.apiBaseUrl;
            
            final refreshResponse = await refreshDio.post(
              '/auth/refresh',
              data: {'refreshToken': refreshToken},
            );
            
            if (refreshResponse.statusCode == 200) {
              final newToken = refreshResponse.data['token'];
              await storage.write(key: 'auth_token', value: newToken);
              
              // Retry the original request with new token
              final opts = Options(
                method: error.requestOptions.method,
                headers: {
                  'Authorization': 'Bearer $newToken',
                  ...error.requestOptions.headers,
                },
              );
              
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
          print('Token refresh error: $e');
        }
      }
      
      return handler.next(error);
    },
  ));
  
  return dio;
});

// Auth service provider that depends on Dio
final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthService(dio);
});

// Auth service class
class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String name, DateTime birthDate, String gender) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
        'birth_date': birthDate.toIso8601String(),
        'gender': gender,
      });
      return response.data;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }
} 