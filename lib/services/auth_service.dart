import 'dart:convert';
import 'dart:async';
import 'dart:math' as Math;
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import 'api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';
import '../providers/providers.dart'; // Import providers.dart for reference to shared providers

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthService(dio, secureStorage, prefs);
});

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;
  final _logger = Logger('Auth');

  AuthService(this._dio, this._secureStorage, this._prefs);

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    _logger.debug('Attempting login for email: $email');
    try {
      // Ensure the URL is properly constructed
      String loginUrl = AppEndpoints.login;
      if (loginUrl.startsWith('/') && AppConfig.apiBaseUrl.endsWith('/')) {
        loginUrl = loginUrl.substring(1);
      }
      
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}$loginUrl',
        data: {
          AppRequestKeys.email: email,
          AppRequestKeys.password: password,
        },
      );
      
      _logger.debug('Login success: ${response.statusCode}');
      
      await _handleAuthResponse(response.data);
      
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      String errorMessage = 'Login failed';
      
      if (e.response != null) {
        _logger.error('Login failed: ${e.response?.statusCode} - ${e.response?.data}');
        
        // Extract error message from response if available
        if (e.response?.data is Map) {
          errorMessage = e.response?.data['message'] ?? 
                        e.response?.data['error'] ?? 
                        'Authentication failed';
        }
        
        // Handle specific status codes
        if (e.response?.statusCode == 401) {
          errorMessage = 'Invalid email or password';
        } else if (e.response?.statusCode == 429) {
          errorMessage = 'Too many login attempts. Please try again later.';
        } else if (e.response?.statusCode == 403) {
          errorMessage = 'Account locked or disabled. Please contact support.';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Account not found with this email.';
        }
      } else {
        _logger.error('Login failed: ${e.message}');
        errorMessage = 'Network error. Please check your connection.';
      }
      
      return {
        'success': false,
        'message': errorMessage,
        'error': e,
      };
    } catch (e) {
      _logger.error('Unexpected error during login: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e,
      };
    }
  }
  
  // Login with biometrics
  Future<Map<String, dynamic>> loginWithBiometrics(String email) async {
    _logger.info('Attempting biometric login with email: $email');
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}${AppEndpoints.biometricLogin}',
        data: {
          AppRequestKeys.email: email,
          AppRequestKeys.biometricAuthenticated: true,
        },
      );
      
      if (response.statusCode == AppStatusCodes.success && response.data != null) {
        await _handleAuthResponse(response.data!);
        return response.data!;
      } else {
        String errorMessage = response.data?[AppResponseKeys.message] ?? AppErrorMessages.biometricLoginFailed;
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      _logger.error('Biometric Login Dio exception: ${e.message}');
      String errorMessage = e.response?.data?[AppResponseKeys.message] ?? e.message ?? AppErrorMessages.biometricLoginFailed;
      throw Exception(errorMessage);
    } catch (e) {
      _logger.error('Biometric Login general exception: $e');
      throw Exception(AppErrorMessages.unexpectedError);
    }
  }
  
  // Register user
  Future<Map<String, dynamic>> register(
    String name, 
    String email, 
    String password, 
    String birthDate, 
    String gender
  ) async {
    _logger.info('Registering new user: $email');
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}${AppEndpoints.register}',
        data: {
          AppRequestKeys.name: name,
          AppRequestKeys.email: email,
          AppRequestKeys.password: password,
          AppRequestKeys.birthDate: birthDate,
          AppRequestKeys.gender: gender,
        },
      );
      
      if (response.statusCode == AppStatusCodes.created && response.data != null) {
        await _handleAuthResponse(response.data!);
        _logger.info('Registration successful for: $email');
        return response.data!;
      } else {
        String errorMessage = response.data?[AppResponseKeys.message] ?? AppErrorMessages.registrationFailed;
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      _logger.error('Registration Dio exception: ${e.message}');
      String errorMessage = e.response?.data?[AppResponseKeys.message] ?? e.message ?? AppErrorMessages.registrationFailed;
      throw Exception(errorMessage);
    } catch (e) {
      _logger.error('Registration general exception: $e');
      throw Exception(AppErrorMessages.unexpectedError);
    }
  }
  
  // Logout user
  Future<void> logout() async {
    _logger.debug('Logging out user');
    try {
      await _secureStorage.delete(key: AppStorageKeys.accessToken);
      await _secureStorage.delete(key: AppStorageKeys.refreshToken);
      await _prefs.remove(AppStorageKeys.userId);
      await _prefs.remove(AppStorageKeys.userEmail);
      await _prefs.remove(AppStorageKeys.userName);
      await _prefs.remove(AppStorageKeys.profileId);
      _logger.info('User logged out successfully');
    } catch (e) {
      _logger.error('Error during logout: $e');
      rethrow;
    }
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      _logger.debug('Checking if user is logged in');
      final token = await _secureStorage.read(key: AppStorageKeys.accessToken);
      final result = token != null && token.isNotEmpty;
      _logger.debug('User logged in status: $result');
      return result;
    } catch (e) {
      _logger.error('Error checking login status: $e');
      return false;
    }
  }
  
  // Get current user id from SharedPreferences
  Future<String?> getUserId() async {
    try {
      _logger.debug('Getting user ID from preferences');
      return _prefs.getString(AppStorageKeys.userId);
    } catch (e) {
      _logger.error('Error getting user ID: $e');
      return null;
    }
  }

  // Get current user email from SharedPreferences
  Future<String?> getUserEmail() async {
    return _prefs.getString(AppStorageKeys.userEmail);
  }

  // Get current user name from SharedPreferences
  Future<String?> getUserName() async {
    return _prefs.getString(AppStorageKeys.userName);
  }

  // Get access token
  Future<String?> getAccessToken() async {
    try {
      _logger.debug('Getting access token from secure storage');
      return await _secureStorage.read(key: AppStorageKeys.accessToken);
    } catch (e) {
      _logger.error('Error getting access token: $e');
      return null;
    }
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      _logger.debug('Getting refresh token from secure storage');
      return await _secureStorage.read(key: AppStorageKeys.refreshToken);
    } catch (e) {
      _logger.error('Error getting refresh token: $e');
      return null;
    }
  }

  // Refresh token with enhanced error handling
  Future<bool> refreshToken() async {
    _logger.debug('Attempting to refresh token');
    try {
      final refreshToken = await _secureStorage.read(key: AppStorageKeys.refreshToken);
      
      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.warn('No refresh token available - authentication required');
        return false;
      }
      
      // Create a new dio instance to avoid interceptor loops
      final refreshDio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.networkTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConfig.networkTimeoutMs),
        headers: {
          'Content-Type': AppHeaders.applicationJson,
          'Accept': AppHeaders.applicationJson,
        },
      ));
      
      // Ensure the URL is properly constructed
      String refreshUrl = AppEndpoints.refresh; // Use refresh instead of refreshToken
      if (refreshUrl.startsWith('/') && refreshDio.options.baseUrl.endsWith('/')) {
        refreshUrl = refreshUrl.substring(1);
      }
      
      _logger.debug('Making refresh token request to: ${refreshDio.options.baseUrl}$refreshUrl');
      
      final response = await refreshDio.post(
        refreshUrl,
        data: {
          // Use 'refreshToken' key as required by the server
          'refreshToken': refreshToken,
        },
      );
      
      _logger.debug('Token refresh response status: ${response.statusCode}');
      _logger.debug('Token refresh response data: ${response.data}');
      
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
          // Store new tokens
          await _secureStorage.write(key: AppStorageKeys.token, value: newToken);
          await _secureStorage.write(key: AppStorageKeys.accessToken, value: newToken);
          
          if (newRefreshToken != null) {
            await _secureStorage.write(key: AppStorageKeys.refreshToken, value: newRefreshToken);
          }
          
          _logger.info('Token refreshed successfully');
          return true;
        } else {
          _logger.error('Missing token in refresh response: ${data}');
          return false;
        }
      } else {
        _logger.error('Invalid token refresh response: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      // Handle specific error cases
      if (e.response?.statusCode == 401) {
        _logger.error('Refresh token is invalid or expired (401)');
        // Clear tokens on 401 response
        await _secureStorage.delete(key: AppStorageKeys.token);
        await _secureStorage.delete(key: AppStorageKeys.accessToken);
        await _secureStorage.delete(key: AppStorageKeys.refreshToken);
      } else if (e.type == DioExceptionType.connectionTimeout || 
                e.type == DioExceptionType.sendTimeout ||
                e.type == DioExceptionType.receiveTimeout) {
        _logger.error('Token refresh timeout: ${e.message}');
      } else {
        _logger.error('Token refresh Dio error: ${e.message}, status: ${e.response?.statusCode}');
        _logger.error('Response data: ${e.response?.data}');
      }
      return false;
    } catch (e) {
      _logger.error('Unexpected error during token refresh: $e');
      return false;
    }
  }
  
  // Handle auth response and store tokens
  Future<void> _handleAuthResponse(Map<String, dynamic> data) async {
    _logger.debug('Handling auth response');
    
    // Extract tokens from response
    String? token;
    String? refreshToken;
    Map<String, dynamic>? userData;
    
    // Check if the data is nested in a 'data' field
    final Map<String, dynamic> dataToUse = data['data'] is Map ? 
                                          data['data'] as Map<String, dynamic> : 
                                          data;
    
    // Extract token - check multiple possible field names
    token = dataToUse['token'] as String?;
    if (token == null) {
      token = dataToUse['accessToken'] as String?;
    }
    
    // Extract refresh token - check multiple possible field names
    refreshToken = dataToUse['refresh_token'] as String?;
    if (refreshToken == null) {
      refreshToken = dataToUse['refreshToken'] as String?;
    }
    
    // Extract user data
    userData = dataToUse['user'] as Map<String, dynamic>?;
    
    _logger.debug('Extracted token: ${token != null ? 'yes' : 'no'}');
    _logger.debug('Extracted refresh token: ${refreshToken != null ? 'yes' : 'no'}');
    _logger.debug('Extracted user data: ${userData != null ? 'yes' : 'no'}');
    
    if (token != null) {
      await _secureStorage.write(key: AppStorageKeys.token, value: token);
      await _secureStorage.write(key: AppStorageKeys.accessToken, value: token);
      _logger.debug('Token stored in secure storage');
    }
    
    if (refreshToken != null) {
      await _secureStorage.write(key: AppStorageKeys.refreshToken, value: refreshToken);
      _logger.debug('Refresh token stored in secure storage');
    }
    
    if (userData != null) {
      await _prefs.setString(AppStorageKeys.userId, userData['id'].toString());
      await _prefs.setString(AppStorageKeys.userEmail, userData['email'].toString());
      await _prefs.setString(AppStorageKeys.userName, userData['name']?.toString() ?? '');
      _logger.debug('User data stored in preferences');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    _logger.info('Requesting password reset for email: $email');
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}${AppEndpoints.forgotPassword}',
        data: {
          AppRequestKeys.email: email,
        },
      );
      
      if (response.statusCode != AppStatusCodes.success) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data?['message'] ?? 'Failed to request password reset'
        );
      }
      // Success
    } on DioException catch (e) {
      _logger.error('Reset password Dio exception: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Password reset failed';
      throw Exception(errorMessage);
    } catch (e) {
      _logger.error('Reset password general exception: $e');
      throw Exception(AppErrorMessages.unexpectedError);
    }
  }
  
  // Confirm password reset with token
  Future<void> confirmPasswordReset(String email, String token, String newPassword) async {
    _logger.info('Confirming password reset for email: $email');
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}${AppEndpoints.resetPassword}',
        data: {
          AppRequestKeys.email: email,
          AppRequestKeys.token: token,
          AppRequestKeys.password: newPassword,
        },
      );
      
      if (response.statusCode != AppStatusCodes.success) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data?['message'] ?? 'Failed to reset password'
        );
      }
      _logger.info('Password reset successful for email: $email');
      // Success
    } on DioException catch (e) {
      _logger.error('Confirm password reset Dio exception: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Password reset failed';
      throw Exception(errorMessage);
    } catch (e) {
      _logger.error('Confirm password reset general exception: $e');
      throw Exception(AppErrorMessages.unexpectedError);
    }
  }

  // Get current user data
  Future<User> getCurrentUser() async {
    _logger.info('Getting current user...');
    try {
      final token = await getAccessToken();
      
      if (token == null || token.isEmpty) {
        _logger.error('No auth token available for getCurrentUser request');
        throw Exception('Authentication required: No token available');
      }
      
      _logger.debug('Making request to ${AppConfig.apiBaseUrl}/api/users/me with token: ${token.length > 15 ? token.substring(0, 15) + '...' : token}');
      
      // Add explicit headers for this specific request to ensure token is included
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      final response = await _dio.get('${AppConfig.apiBaseUrl}/api/users/me', options: options);
      _logger.debug('Get user response status: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['user'] != null) {
        _logger.info('Successfully retrieved user: ${response.data['user']['email']}');
        return User.fromJson(response.data['user']);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data?['message'] ?? 'Failed to get user data'
        );
      }
    } on DioException catch (e) {
      _logger.error('Get user Dio error: ${e.message}');
      _logger.error('Error status code: ${e.response?.statusCode}');
      
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Failed to get user data';
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please log in again.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      _logger.error('Get user general error: $e');
      throw Exception('Failed to get user data');
    }
  }

  // Update user profile
  Future<User> updateProfile(Map<String, dynamic> data) async {
    _logger.info('Updating profile...');
    try {
      final response = await _dio.put(
        '/api/users/profile',
        data: data,
      );

      if (response.statusCode == 200 && response.data['user'] != null) {
        return User.fromJson(response.data['user']);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data?['message'] ?? 'Failed to update profile'
        );
      }
    } on DioException catch (e) {
      _logger.error('Update profile Dio error: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Failed to update profile';
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please log in again.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      _logger.error('Update profile general error: $e');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }
}