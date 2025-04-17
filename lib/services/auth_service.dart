import 'dart:convert';
import 'dart:math' as Math;
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_config.dart';
import 'api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  AuthService(this._dio);

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    print('⟹ [AuthService] Attempting login with email: $email');
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
    
      if (response.statusCode == 200 && response.data['data'] != null) {
        await _saveAuthData(response.data['data']);
        return response.data['data'];
      } else {
        String errorMessage = response.data?['message'] ?? 'Failed to login';
        print('⟹ [AuthService] Login failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      print('⟹ [AuthService] Login Dio exception: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Login failed';
      throw Exception(errorMessage);
    } catch (e) {
      print('⟹ [AuthService] Login general exception: $e');
      throw Exception('An unexpected error occurred during login.');
    }
  }
  
  // Login with biometrics
  Future<Map<String, dynamic>> loginWithBiometrics(String email) async {
    print('⟹ [AuthService] Attempting biometric login with email: $email');
    try {
      final response = await _dio.post(
        '/auth/biometric-login',
        data: {
          'email': email,
          'biometric_authenticated': true,
        },
      );
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        await _saveAuthData(response.data['data']);
        return response.data['data'];
      } else {
        String errorMessage = response.data?['message'] ?? 'Biometric login failed';
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      print('⟹ [AuthService] Biometric Login Dio exception: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Biometric login failed';
      throw Exception(errorMessage);
    } catch (e) {
      print('⟹ [AuthService] Biometric Login general exception: $e');
      throw Exception('An unexpected error occurred during biometric login.');
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
    print('⟹ [AuthService] Attempting registration...');
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'birthDate': birthDate,
          'gender': gender,
        },
      );
      
      if (response.statusCode == 201 && response.data['data'] != null) {
        await _saveAuthData(response.data['data']);
        return response.data['data'];
      } else {
        String errorMessage = response.data?['message'] ?? 'Failed to register';
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      print('⟹ [AuthService] Registration Dio exception: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Registration failed';
      throw Exception(errorMessage);
    } catch (e) {
      print('⟹ [AuthService] Registration general exception: $e');
      throw Exception('An unexpected error occurred during registration.');
    }
  }
  
  // Logout user
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userEmail');
    await prefs.remove('userName');
    await prefs.remove('profileId');
    print('⟹ [AuthService] User logged out and data cleared.');
  }
  
  // Check if user is logged in (by checking for token)
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    print('⟹ [AuthService] Checking isLoggedIn: ${token != null}');
    return token != null;
  }
  
  // Get current user id from SharedPreferences
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Get current user email from SharedPreferences
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  // Get current user name from SharedPreferences
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  // Get auth token from secure storage
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Get refresh token from secure storage
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }
  
  // Refresh token
  Future<bool> refreshToken() async {
    final refreshToken = await getRefreshToken();
    print('⟹ [AuthService] Attempting token refresh (using http)...');
    
    if (refreshToken == null) {
      print('⟹ [AuthService] Refresh failed: No refresh token found.');
      return false;
    }
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );
      
      final responseData = jsonDecode(response.body);
      print('⟹ [AuthService] Refresh response status: ${response.statusCode}');
      
      if (response.statusCode == 200 && responseData['data'] != null) {
        await _storage.write(key: _tokenKey, value: responseData['data']['token']);
        await _storage.write(key: _refreshTokenKey, value: responseData['data']['refreshToken']);
        print('⟹ [AuthService] Token refreshed successfully (using http).');
        return true;
      } else {
        print('⟹ [AuthService] Refresh failed (http): Server response indicated failure. ${responseData['message'] ?? ''}');
        return false;
      }
    } catch (e) {
      print('⟹ [AuthService] Refresh exception (http): $e');
      return false;
    }
  }
  
  // Save authentication data
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    print('⟹ [AuthService] Saving auth data...');
    
    final token = data['token'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    final userJson = data['user'] as Map<String, dynamic>?;
    final profileJson = data['profile'] as Map<String, dynamic>?;

    if (token == null || userJson == null) {
      print('⟹ [AuthService] Error saving auth data: Token or User data missing.');
      throw Exception('Invalid auth data received from server.');
    }

    await _storage.write(key: _tokenKey, value: token);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userJson['id'].toString());
    await prefs.setString('userEmail', userJson['email'] as String);
    await prefs.setString('userName', userJson['name'] as String);
    
    // Save profile ID from the profile object if it exists
    if (profileJson != null && profileJson.containsKey('id')) {
      await prefs.setString('profileId', profileJson['id'].toString());
    }
    
    final tokenPreview = token.substring(0, Math.min(15, token.length));
    print('⟹ [AuthService] Auth data saved successfully. Token: $tokenPreview...');
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    print('⟹ [AuthService] Requesting password reset for email: $email');
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {
          'email': email,
        },
      );
      
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data?['message'] ?? 'Failed to request password reset'
        );
      }
      // Success
    } on DioException catch (e) {
      print('⟹ [AuthService] Reset password Dio exception: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Password reset failed';
      throw Exception(errorMessage);
    } catch (e) {
      print('⟹ [AuthService] Reset password general exception: $e');
      throw Exception('An unexpected error occurred during password reset.');
    }
  }

  // Get current user data
  Future<User> getCurrentUser() async {
    print('⟹ [AuthService] Getting current user...');
    try {
      final response = await _dio.get('/user');
      
      if (response.statusCode == 200 && response.data['user'] != null) {
        return User.fromJson(response.data['user']);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data?['message'] ?? 'Failed to get user data'
        );
      }
    } on DioException catch (e) {
      print('⟹ [AuthService] Get user Dio error: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Failed to get user data';
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please log in again.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('⟹ [AuthService] Get user general error: $e');
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  // Update user profile
  Future<User> updateProfile(Map<String, dynamic> data) async {
    print('⟹ [AuthService] Updating profile...');
    try {
      final response = await _dio.put(
        '/user',
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
      print('⟹ [AuthService] Update profile Dio error: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Failed to update profile';
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please log in again.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('⟹ [AuthService] Update profile general error: $e');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }
}