import 'dart:convert';
import 'dart:math' as math;
import 'dart:io'; // Import File for upload
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../config/app_config.dart';
import '../utils/exceptions.dart';
import '../utils/dummy_data.dart';
import 'auth_service.dart';
import 'api_client.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  final Dio _dio;
  final SharedPreferences _prefs;
  final _logger = Logger('Profile');
  
  ProfileService(this._dio, this._prefs);

  Future<Profile?> getCurrentUserProfile() async {
    _logger.debug('Getting current user profile');
    try {
      final userId = _prefs.getString(AppStorageKeys.userId);
      if (userId == null) {
        _logger.warn('No user ID found when getting current profile');
        return null;
      }

      _logger.debug('Fetching profile for user ID: $userId');
      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}${AppEndpoints.myProfile}',
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.info('Successfully retrieved current user profile');
        return Profile.fromJson(response.data);
      } else {
        _logger.warn('Failed to get profile: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      _logger.error('Dio error getting current profile: ${e.message}');
      _logger.error('Response: ${e.response?.statusCode} - ${e.response?.data}');
      
      if (kDebugMode) {
        _logger.debug('Returning mock profile in debug mode');
        return _generateMockProfile();
      }
      return null;
    } catch (e, stackTrace) {
      _logger.error('Unexpected error getting current profile: $e');
      _logger.error('Stack trace: $stackTrace');
      
      if (kDebugMode) {
        _logger.debug('Returning mock profile in debug mode');
        return _generateMockProfile();
      }
      return null;
    }
  }

  Future<Profile?> getProfile(String profileId) async {
    _logger.debug('Getting profile by ID: $profileId');
    try {
      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}${AppEndpoints.profiles}/$profileId',
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.info('Successfully retrieved profile: $profileId');
        return Profile.fromJson(response.data);
      } else {
        _logger.warn('Failed to get profile: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      _logger.error('Dio error getting profile $profileId: ${e.message}');
      _logger.error('Response: ${e.response?.statusCode} - ${e.response?.data}');
      return null;
    } catch (e) {
      _logger.error('Unexpected error getting profile $profileId: $e');
      return null;
    }
  }

  Future<List<Profile>> getDiscoverProfiles({
    int limit = 10,
    double? maxDistance,
    List<String>? interests,
    String? gender,
    int? minAge,
    int? maxAge,
  }) async {
    _logger.debug('Getting discover profiles with filters: limit=$limit, maxDistance=$maxDistance, interests=$interests, gender=$gender, age range=$minAge-$maxAge');
    
    try {
      final queryParams = {
        'limit': limit.toString(),
        if (maxDistance != null) 'maxDistance': maxDistance.toString(),
        if (gender != null) 'gender': gender,
        if (minAge != null) 'minAge': minAge.toString(),
        if (maxAge != null) 'maxAge': maxAge.toString(),
      };
      
      if (interests != null && interests.isNotEmpty) {
        queryParams['interests'] = interests.join(',');
      }
      
      _logger.debug('Query params: $queryParams');
      
      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}${AppEndpoints.discoverProfiles}',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> profilesJson = response.data['profiles'];
        final profiles = profilesJson.map((json) => Profile.fromJson(json)).toList();
        _logger.info('Successfully retrieved ${profiles.length} discover profiles');
        return profiles;
      } else {
        _logger.warn('Failed to get discover profiles: ${response.statusCode}');
        
        if (kDebugMode) {
          _logger.debug('Returning mock profiles in debug mode');
          return List.generate(10, (_) => _generateMockProfile());
        }
        return [];
      }
    } on DioException catch (e) {
      _logger.error('Dio error getting discover profiles: ${e.message}');
      _logger.error('Response: ${e.response?.statusCode} - ${e.response?.data}');
      
      if (kDebugMode) {
        _logger.debug('Returning mock profiles in debug mode');
        return List.generate(10, (_) => _generateMockProfile());
      }
      return [];
    } catch (e) {
      _logger.error('Unexpected error getting discover profiles: $e');
      
      if (kDebugMode) {
        _logger.debug('Returning mock profiles in debug mode');
        return List.generate(10, (_) => _generateMockProfile());
      }
      return [];
    }
  }

  Future<Profile?> createProfile(Map<String, dynamic> profileData) async {
    _logger.debug('Creating new profile');
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}${AppEndpoints.profiles}',
        data: profileData,
      );

      if (response.statusCode == 201 && response.data != null) {
        _logger.info('Successfully created profile');
        return Profile.fromJson(response.data);
      } else {
        _logger.warn('Failed to create profile: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      _logger.error('Dio error creating profile: ${e.message}');
      _logger.error('Response: ${e.response?.statusCode} - ${e.response?.data}');
      return null;
    } catch (e) {
      _logger.error('Unexpected error creating profile: $e');
      return null;
    }
  }

  Future<Profile?> updateProfile(String profileId, Map<String, dynamic> profileData) async {
    _logger.debug('Updating profile: $profileId');
    try {
      final response = await _dio.patch(
        '${AppConfig.apiBaseUrl}${AppEndpoints.profiles}/$profileId',
        data: profileData,
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.info('Successfully updated profile: $profileId');
        return Profile.fromJson(response.data);
      } else {
        _logger.warn('Failed to update profile: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      _logger.error('Dio error updating profile $profileId: ${e.message}');
      _logger.error('Response: ${e.response?.statusCode} - ${e.response?.data}');
      return null;
    } catch (e) {
      _logger.error('Unexpected error updating profile $profileId: $e');
      return null;
    }
  }

  Future<bool> likeProfile(String profileId) async {
    _logger.debug("Liking profile: $profileId");
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}${AppEndpoints.profileAction}',
        data: {
          'targetProfileId': profileId,
          'action': 'like',
        },
      );
      
      _logger.info("Successfully liked profile: $profileId");
      return true;
    } on DioException catch (e) {
      _logger.error("Dio error liking profile $profileId: ${e.message}");
      
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.sendTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw Exception(Constants.networkError);
      } else if (e.response?.statusCode == 401) {
        throw Exception(Constants.authError);
      } else if (e.response?.statusCode == 500) {
        throw Exception(Constants.serverError);
      } else {
        _logger.error("Response: ${e.response?.statusCode} - ${e.response?.data}");
        // Return error message from server or fallback to generic
        final errorMessage = e.response?.data?['message'] ?? Constants.genericError;
        throw Exception(errorMessage);
      }
    } catch (e) {
      _logger.error("General error liking profile $profileId: $e");
      
      if (kDebugMode) {
        _logger.debug("Returning mock success in debug mode");
        return true;
      }
      
      throw Exception(Constants.genericError);
    }
  }

  Future<bool> dislikeProfile(String profileId) async {
    _logger.debug('Disliking profile: $profileId');
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}${AppEndpoints.profileAction}',
        data: {
          'targetProfileId': profileId,
          'action': 'dislike',
        },
      );

      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success) {
        _logger.info('Successfully disliked profile: $profileId');
      } else {
        _logger.warn('Failed to dislike profile: ${response.statusCode}');
      }
      return success;
    } on DioException catch (e) {
      _logger.error('Dio error disliking profile $profileId: ${e.message}');
      return false;
    } catch (e) {
      _logger.error('Unexpected error disliking profile $profileId: $e');
      return false;
    }
  }

  Future<bool> superlikeProfile(String profileId) async {
    _logger.debug('Superliking profile: $profileId');
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}${AppEndpoints.profileAction}',
        data: {
          'targetProfileId': profileId,
          'action': 'superlike',
        },
      );

      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success) {
        _logger.info('Successfully superliked profile: $profileId');
      } else {
        _logger.warn('Failed to superlike profile: ${response.statusCode}');
      }
      return success;
    } on DioException catch (e) {
      _logger.error('Dio error superliking profile $profileId: ${e.message}');
      return false;
    } catch (e) {
      _logger.error('Unexpected error superliking profile $profileId: $e');
      return false;
    }
  }

  /// Checks the verification status of the profile
  Future<Map<String, dynamic>> checkVerificationStatus() async {
    try {
      final response = await _dio.get(
        AppEndpoints.profileVerification + '/status',
      );

      _logger.info('Verification status retrieved: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      _logger.error('Dio error checking verification status: ${e.message}');
      // Return mock data for testing
      return {
        'status': 'pending',
        'message': 'Your verification is being processed.',
        'error': Constants.ERROR_VERIFICATION
      };
    } catch (e) {
      _logger.error('Unexpected error checking verification status: $e');
      return {
        'status': 'error',
        'message': Constants.ERROR_VERIFICATION
      };
    }
  }

  /// Requests profile verification
  Future<Map<String, dynamic>> requestVerification() async {
    try {
      final response = await _dio.post(
        AppEndpoints.profileVerification + '/request',
      );

      _logger.info('Verification requested successfully: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      _logger.error('Dio error requesting verification: ${e.message}');
      // Return mock data for testing
      return {
        'status': 'requested',
        'token': 'mock-verification-token',
        'message': 'Verification has been requested successfully.',
        'error': Constants.ERROR_VERIFICATION
      };
    } catch (e) {
      _logger.error('Unexpected error requesting verification: $e');
      return {
        'status': 'error',
        'message': Constants.ERROR_VERIFICATION
      };
    }
  }

  /// Completes the verification process
  Future<Map<String, dynamic>> completeVerification(String verificationToken, String? selfieImagePath) async {
    try {
      Map<String, dynamic> data = {
        'token': verificationToken,
      };
      
      if (selfieImagePath != null) {
        // Add logic to upload selfie if needed
        data['selfie'] = selfieImagePath;
      }
      
      final response = await _dio.post(
        AppEndpoints.profileVerification + '/complete',
        data: data,
      );

      _logger.info('Verification completed successfully: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      _logger.error('Dio error completing verification: ${e.message}');
      // Return mock data for testing
      return {
        'status': 'error',
        'message': Constants.ERROR_VERIFICATION,
        'details': e.message
      };
    } catch (e) {
      _logger.error('Unexpected error completing verification: $e');
      return {
        'status': 'error',
        'message': Constants.ERROR_VERIFICATION
      };
    }
  }

  Profile _generateMockProfile() {
    _logger.debug('Generating mock profile');
    final random = math.Random();
    final names = ['Alex', 'Jamie', 'Taylor', 'Jordan', 'Casey', 'Riley', 'Avery', 'Quinn', 'Morgan', 'Dakota'];
    final interests = ['hiking', 'reading', 'movies', 'cooking', 'travel', 'music', 'art', 'sports', 'yoga', 'photography'];
    
    final name = names[random.nextInt(names.length)];
    final id = 'mock-${random.nextInt(10000)}';
    final age = 20 + random.nextInt(15);
    
    // Generate a date of birth to match the age
    final now = DateTime.now();
    final birthYear = now.year - age;
    final birthMonth = 1 + random.nextInt(12);
    final birthDay = 1 + random.nextInt(28);
    final birthDate = DateTime(birthYear, birthMonth, birthDay);
    
    final userInterests = List.generate(
      3 + random.nextInt(3),
      (_) => interests[random.nextInt(interests.length)],
    ).toSet().toList(); // Remove duplicates
    
    // Use more reliable image URLs that are less likely to 404
    // Using Lorem Picsum with a seed for consistent images
    final photoId = random.nextInt(1000) + 100; // Avoid low IDs that might not exist
    final photo = 'https://picsum.photos/seed/$photoId/300/400';
    final secondPhotoId = random.nextInt(1000) + 100;
    final secondPhoto = 'https://picsum.photos/seed/$secondPhotoId/300/400';
    
    return Profile(
      id: id,
      name: name,
      birthDate: birthDate,
      bio: 'This is a mock profile for $name, age $age.',
      interests: userInterests,
      photoUrls: [photo, secondPhoto],
      location: {'city': 'Mock City', 'country': 'Mockland'},
      occupation: 'Professional Mock',
      education: 'University of Mocking',
      gender: random.nextBool() ? 'male' : 'female',
      isVerified: false,
      prompts: [
        {'question': 'About me', 'answer': 'I am a mock profile'},
        {'question': 'Looking for', 'answer': 'Someone to test this app with'},
      ],
      minAgePreference: 18,
      maxAgePreference: 45,
      maxDistance: 50,
      genderPreference: 'all',
    );
  }
}

// Provider is now defined in profile_service_provider.dart
// Provider is now defined in profile_service_provider.dart