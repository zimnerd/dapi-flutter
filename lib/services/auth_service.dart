import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';
import '../providers/providers.dart'; // Import providers.dart for reference to shared providers
import '../utils/constants.dart'; // Import Constants
import '../utils/exceptions.dart'; // Import ApiException

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

  // Login user - Returns void on success, throws ApiException on failure
  Future<void> login(String email, String password) async {
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

      // Check status code for success (e.g., 200)
      if (response.statusCode == 200 && response.data != null) {
        _logger.debug('Login success: ${response.statusCode}');
        await _handleAuthResponse(response.data);
      } else {
        // Handle non-200 responses by throwing ApiException
        _logger.warn(
            'Login failed with status: ${response.statusCode}, data: ${response.data}');
        throw ApiException(
          response.data?['message'] ?? errorGeneric,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.error('Login failed: ${e.message}');
      _handleDioError(e, defaultMessage: errorGeneric); // Use helper
      rethrow; // Rethrow the ApiException from _handleDioError
    } catch (e, s) {
      _logger.error('Unexpected error during login: $e', e, s);
      throw ApiException(errorGeneric);
    }
  }

  // Login with biometrics - Returns void on success, throws ApiException on failure
  Future<void> loginWithBiometrics(String email) async {
    _logger.info('Attempting biometric login with email: $email');
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}${AppEndpoints.biometricLogin}',
        data: {
          AppRequestKeys.email: email,
          AppRequestKeys.biometricAuthenticated: true,
        },
      );

      if (response.statusCode == AppStatusCodes.success &&
          response.data != null) {
        await _handleAuthResponse(response.data!);
        _logger.info('Biometric login successful');
      } else {
        _logger.warn(
            'Biometric login failed with status: ${response.statusCode}, data: ${response.data}');
        throw ApiException(
          response.data?[AppResponseKeys.message] ?? errorGeneric,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.error('Biometric Login Dio exception: ${e.message}');
      _handleDioError(e, defaultMessage: errorGeneric);
      rethrow;
    } catch (e, s) {
      _logger.error('Biometric Login general exception: $e', e, s);
      throw ApiException(errorGeneric);
    }
  }

  // Register user - Returns void on success, throws ApiException on failure
  Future<void> register(String name, String email, String password,
      String birthDate, String gender) async {
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

      if (response.statusCode == AppStatusCodes.created &&
          response.data != null) {
        await _handleAuthResponse(response.data!);
        _logger.info('Registration successful for: $email');
      } else {
        _logger.warn(
            'Registration failed with status: ${response.statusCode}, data: ${response.data}');
        String errorMessage =
            response.data?[AppResponseKeys.message] ?? errorGeneric;
        if (response.statusCode == 409) {
          // Conflict
          errorMessage = errorGeneric;
        }
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      _logger.error('Registration Dio exception: ${e.message}');
      _handleDioError(e, defaultMessage: errorGeneric);
      rethrow;
    } catch (e, s) {
      _logger.error('Registration general exception: $e', e, s);
      throw ApiException(errorGeneric);
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

  // Refresh token - Returns void on success, throws ApiException on failure
  Future<void> refreshToken() async {
    _logger.debug('Attempting to refresh token');
    try {
      final refreshToken =
          await _secureStorage.read(key: AppStorageKeys.refreshToken);

      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.warn('No refresh token available - authentication required');
        return;
      }

      // Create a new dio instance to avoid interceptor loops
      final refreshDio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConfig.networkTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConfig.networkTimeoutMs),
        headers: {
          'Content-Type': AppHeaders.applicationJson,
          'Accept': AppHeaders.applicationJson,
        },
      ));

      // Ensure the URL is properly constructed
      String refreshUrl =
          AppEndpoints.refresh; // Use refresh instead of refreshToken
      if (refreshUrl.startsWith('/') &&
          refreshDio.options.baseUrl.endsWith('/')) {
        refreshUrl = refreshUrl.substring(1);
      }

      _logger.debug(
          'Making refresh token request to: ${refreshDio.options.baseUrl}$refreshUrl');

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
          await _secureStorage.write(
              key: AppStorageKeys.token, value: newToken);
          await _secureStorage.write(
              key: AppStorageKeys.accessToken, value: newToken);

          if (newRefreshToken != null) {
            await _secureStorage.write(
                key: AppStorageKeys.refreshToken, value: newRefreshToken);
          }

          _logger.info('Token refreshed successfully');
          // Success, return void
        } else {
          _logger.error('Missing token in refresh response: $data');
          throw ApiException(errorGeneric, statusCode: response.statusCode);
        }
      } else {
        _logger.error('Invalid token refresh response: ${response.statusCode}');
        throw ApiException(response.data?['message'] ?? errorGeneric,
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      // Handle specific error cases for logging, but throw standardized error via helper
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
        _logger.error(
            'Token refresh Dio error: ${e.message}, status: ${e.response?.statusCode}');
        _logger.error('Response data: ${e.response?.data}');
      }
      _handleDioError(e, defaultMessage: errorGeneric); // Centralized handling
      rethrow;
    } catch (e, s) {
      _logger.error('Unexpected error during token refresh: $e', e, s);
      throw ApiException(errorGeneric);
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
    final Map<String, dynamic> dataToUse =
        data['data'] is Map ? data['data'] as Map<String, dynamic> : data;

    // Extract token - check multiple possible field names
    token = dataToUse['token'] as String?;
    token ??= dataToUse['accessToken'] as String?;

    // Extract refresh token - check multiple possible field names
    refreshToken = dataToUse['refresh_token'] as String?;
    refreshToken ??= dataToUse['refreshToken'] as String?;

    // Extract user data
    userData = dataToUse['user'] as Map<String, dynamic>?;

    _logger.debug('Extracted token: ${token != null ? 'yes' : 'no'}');
    _logger.debug(
        'Extracted refresh token: ${refreshToken != null ? 'yes' : 'no'}');
    _logger.debug('Extracted user data: ${userData != null ? 'yes' : 'no'}');

    if (token != null) {
      await _secureStorage.write(key: AppStorageKeys.token, value: token);
      await _secureStorage.write(key: AppStorageKeys.accessToken, value: token);
      _logger.debug('Token stored in secure storage');
    }

    if (refreshToken != null) {
      await _secureStorage.write(
          key: AppStorageKeys.refreshToken, value: refreshToken);
      _logger.debug('Refresh token stored in secure storage');
    }

    if (userData != null) {
      await _prefs.setString(AppStorageKeys.userId, userData['id'].toString());
      await _prefs.setString(
          AppStorageKeys.userEmail, userData['email'].toString());
      await _prefs.setString(
          AppStorageKeys.userName, userData['name']?.toString() ?? '');
      _logger.debug('User data stored in preferences');
    }
  }

  // Request password reset email - Returns void on success, throws ApiException on failure
  Future<void> requestPasswordReset(String email) async {
    _logger.info('Requesting password reset for email: $email');
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}${AppEndpoints.forgotPassword}',
        data: {
          AppRequestKeys.email: email,
        },
      );

      // Only 200 is success for this endpoint usually
      if (response.statusCode != AppStatusCodes.success) {
        _logger.warn(
            'Request password reset failed with status: ${response.statusCode}, data: ${response.data}');
        String errorMessage =
            response.data?['message'] ?? 'Password reset request failed';
        if (response.statusCode == 404) {
          errorMessage = 'Email not found.';
        }
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
      _logger.info('Password reset request sent successfully for $email');
      // Success
    } on DioException catch (e) {
      _logger.error('Request password reset Dio exception: ${e.message}');
      _handleDioError(e, defaultMessage: 'Password reset request failed');
      rethrow;
    } catch (e, s) {
      _logger.error('Request password reset general exception: $e', e, s);
      throw ApiException(errorGeneric);
    }
  }

  // Confirm password reset with token - Returns void on success, throws ApiException on failure
  Future<void> confirmPasswordReset(
      String email, String token, String newPassword) async {
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

      // Only 200 is success for this endpoint usually
      if (response.statusCode != AppStatusCodes.success) {
        _logger.warn(
            'Confirm password reset failed with status: ${response.statusCode}, data: ${response.data}');
        String errorMessage =
            response.data?['message'] ?? 'Failed to reset password';
        if (response.statusCode == 400) {
          errorMessage = response.data?['message'] ??
              'Invalid token or password criteria not met.';
        } else if (response.statusCode == 404) {
          errorMessage = 'Email or token not found.';
        }
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
      _logger.info('Password reset successful for email: $email');
      // Success
    } on DioException catch (e) {
      _logger.error('Confirm password reset Dio exception: ${e.message}');
      _handleDioError(e, defaultMessage: 'Password reset confirmation failed');
      rethrow;
    } catch (e, s) {
      _logger.error('Confirm password reset general exception: $e', e, s);
      throw ApiException(errorGeneric);
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

      _logger.debug(
          'Making request to ${AppConfig.apiBaseUrl}/users/me with token: ${token.length > 15 ? '${token.substring(0, 15)}...' : token}');

      // Add explicit headers for this specific request to ensure token is included
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final response =
          await _dio.get('${AppConfig.apiBaseUrl}/users/me', options: options);
      _logger.debug('Get user response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data['user'] != null) {
        _logger.info(
            'Successfully retrieved user: ${response.data['user']['email']}');
        return User.fromJson(response.data['user']);
      } else {
        _logger.warn(
            'Get user failed with status: ${response.statusCode}, data: ${response.data}');
        throw ApiException(response.data?['message'] ?? errorGeneric,
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      _logger.error('Get user Dio error: ${e.message}');
      _handleDioError(e, defaultMessage: errorGeneric);
      rethrow;
    } catch (e, s) {
      _logger.error('Get user general error: $e', e, s);
      throw ApiException(errorGeneric);
    }
  }

  // Update user profile
  Future<User> updateProfile(Map<String, dynamic> data) async {
    _logger.info('Updating profile...');
    try {
      final response = await _dio.put(
        '/users/profile',
        data: data,
      );

      if (response.statusCode == 200 && response.data['user'] != null) {
        _logger.info('Successfully updated profile');
        return User.fromJson(response.data['user']);
      } else {
        _logger.warn(
            'Update profile failed with status: ${response.statusCode}, data: ${response.data}');
        throw ApiException(response.data?['message'] ?? errorGeneric,
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      _logger.error('Update profile Dio error: ${e.message}');
      _handleDioError(e, defaultMessage: errorGeneric);
      rethrow;
    } catch (e, s) {
      _logger.error('Update profile general error: $e', e, s);
      throw ApiException(errorGeneric);
    }
  }

  // Delete user account
  Future<bool> deleteAccount() async {
    _logger.info('Deleting user account');
    try {
      final response = await _dio.delete(
        '${AppConfig.apiBaseUrl}/users/me',
      );

      if (response.statusCode == 200) {
        _logger.info('Account deleted successfully');
        // Clear all user data after successful deletion
        await logout();
        return true;
      } else {
        _logger.warn(
            'Account deletion failed with status: ${response.statusCode}');
        throw ApiException(response.data?['message'] ?? errorGeneric,
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      _logger.error('Dio error during account deletion: ${e.message}');
      _handleDioError(e, defaultMessage: 'Failed to delete account');
      rethrow;
    } catch (e, s) {
      _logger.error('Error during account deletion: $e', e, s);
      throw ApiException(errorGeneric);
    }
  }

  // Add user verification request
  Future<bool> requestVerification() async {
    _logger.info('Requesting account verification');
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/users/verify/request',
      );

      if (response.statusCode == 200) {
        _logger.info('Verification request sent successfully');
        return true;
      } else {
        _logger.warn(
            'Verification request failed with status: ${response.statusCode}');
        throw ApiException(
            response.data?['message'] ?? 'Verification request failed',
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      _logger.error('Dio error during verification request: ${e.message}');
      _handleDioError(e, defaultMessage: 'Failed to request verification');
      rethrow;
    } catch (e, s) {
      _logger.error('Error during verification request: $e', e, s);
      throw ApiException(errorGeneric);
    }
  }

  // Confirm verification with token
  Future<bool> confirmVerification(String token) async {
    _logger.info('Confirming account verification');
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/users/verify/confirm',
        data: {'token': token},
      );

      if (response.statusCode == 200) {
        _logger.info('Verification confirmed successfully');
        return true;
      } else {
        _logger.warn(
            'Verification confirmation failed with status: ${response.statusCode}');
        throw ApiException(
            response.data?['message'] ?? 'Verification confirmation failed',
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      _logger.error('Dio error during verification confirmation: ${e.message}');
      _handleDioError(e, defaultMessage: 'Failed to confirm verification');
      rethrow;
    } catch (e, s) {
      _logger.error('Error during verification confirmation: $e', e, s);
      throw ApiException(errorGeneric);
    }
  }

  // Helper method to handle Dio errors and throw ApiException
  void _handleDioError(DioException e, {String? defaultMessage}) {
    String errorMessage = defaultMessage ?? errorGeneric;
    int? statusCode = e.response?.statusCode;

    // Prefer server message if available
    final serverMessage =
        e.response?.data?['message'] ?? e.response?.data?['error'];
    if (serverMessage != null &&
        serverMessage is String &&
        serverMessage.isNotEmpty) {
      errorMessage = serverMessage;
    } else {
      // Fallback to type/status code based messages
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = errorTimeout;
          break;
        case DioExceptionType.badResponse:
          switch (statusCode) {
            case 400:
              // Keep potential server message if more specific, else use constant
              errorMessage = serverMessage ?? errorGeneric;
              break;
            case 401:
              errorMessage = errorAuth; // Specific auth error
              break;
            case 403:
              errorMessage = errorGeneric;
              break;
            case 404:
              errorMessage = errorGeneric;
              break;
            case 409: // Conflict
              errorMessage =
                  serverMessage ?? errorGeneric; // Need a conflict constant
              break;
            case 429:
              errorMessage = errorGeneric; // Need a rate limit constant
              break;
            case 500:
            case 502:
            case 503:
            case 504:
              errorMessage = errorServer;
              break;
            default:
              errorMessage = errorResponseFormat;
          }
          break;
        case DioExceptionType.cancel:
          errorMessage = errorGeneric;
          break;
        case DioExceptionType.connectionError:
          errorMessage = errorNetwork;
          break;
        case DioExceptionType.unknown:
        default:
          errorMessage = errorGeneric;
      }
    }

    _logger.error('API Error ($statusCode): $errorMessage',
        e); // Log original DioException
    throw ApiException(errorMessage, statusCode: statusCode);
  }
}
