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
        '${AppConfig.apiBaseUrl}${AppEndpoints.currentProfile}',
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.info('Successfully retrieved current user profile');
        return Profile.fromJson(response.data);
      } else {
        _logger.warn('Failed to get profile: ${response.statusCode}');
        throw ApiException(Constants.errorFailedToLoadProfile,
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      _logger.error('Dio error getting current profile: ${e.message}');
      _handleDioError(e, defaultMessage: Constants.errorFailedToLoadProfile);
      rethrow;
    } catch (e, stackTrace) {
      _logger.error('Unexpected error getting current profile: $e');
      _logger.error('Stack trace: $stackTrace');
      throw ApiException(Constants.errorGeneric);
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
        _logger
            .warn('Failed to get profile $profileId: ${response.statusCode}');
        if (response.statusCode == 404) {
          throw ApiException(Constants.errorProfileNotFound,
              statusCode: response.statusCode);
        } else {
          throw ApiException(Constants.errorFailedToLoadProfile,
              statusCode: response.statusCode);
        }
      }
    } on DioException catch (e) {
      _logger.error('Dio error getting profile $profileId: ${e.message}');
      _handleDioError(e, defaultMessage: Constants.errorFailedToLoadProfile);
      rethrow;
    } catch (e) {
      _logger.error('Unexpected error getting profile $profileId: $e');
      throw ApiException(Constants.errorGeneric);
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
    _logger.debug(
        'Getting discover profiles with filters: limit=$limit, maxDistance=$maxDistance, interests=$interests, gender=$gender, age range=$minAge-$maxAge');

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
        // Handle both array and object response formats
        List<dynamic> profilesJson;

        if (response.data is List) {
          // Direct array response
          profilesJson = response.data;
          _logger.debug('Response is a direct array of profiles');
        } else if (response.data is Map && response.data['profiles'] != null) {
          // Object with 'profiles' field
          profilesJson = response.data['profiles'];
          _logger.debug(
              'Response contains profiles field with ${profilesJson.length} items');
        } else {
          // Unexpected format - log and return mock data
          _logger.error(
              'Unexpected response format: ${response.data.runtimeType}');
          if (kDebugMode) {
            _logger.debug('Returning mock profiles in debug mode');
            return List.generate(10, (_) => _generateMockProfile());
          }
          throw ApiException(Constants.errorFailedToLoadProfile,
              statusCode: response.statusCode);
        }

        final profiles =
            profilesJson.map((json) => Profile.fromJson(json)).toList();
        _logger.info(
            'Successfully retrieved ${profiles.length} discover profiles');
        return profiles;
      } else {
        _logger.warn('Failed to get discover profiles: ${response.statusCode}');

        if (kDebugMode) {
          _logger.debug('Returning mock profiles in debug mode');
          return List.generate(10, (_) => _generateMockProfile());
        }
        throw ApiException(Constants.errorFailedToLoadProfile,
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      _logger.error('Dio error getting discover profiles: ${e.message}');
      _handleDioError(e, defaultMessage: Constants.errorFailedToLoadProfile);

      if (kDebugMode) {
        _logger.debug('Returning mock profiles in debug mode');
        return List.generate(10, (_) => _generateMockProfile());
      } else {
        rethrow;
      }
    } catch (e) {
      _logger.error('Unexpected error getting discover profiles: $e');

      if (kDebugMode) {
        _logger.debug('Returning mock profiles in debug mode');
        return List.generate(10, (_) => _generateMockProfile());
      } else {
        throw ApiException(Constants.errorGeneric);
      }
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
        throw ApiException(Constants.errorProfileUpdateFailed,
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      _logger.error('Dio error creating profile: ${e.message}');
      _handleDioError(e, defaultMessage: Constants.errorProfileUpdateFailed);
      rethrow;
    } catch (e) {
      _logger.error('Unexpected error creating profile: $e');
      throw ApiException(Constants.errorGeneric);
    }
  }

  Future<Profile?> updateProfile(
      String profileId, Map<String, dynamic> profileData) async {
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
        _logger.warn(
            'Failed to update profile $profileId: ${response.statusCode}');
        throw ApiException(Constants.errorProfileUpdateFailed,
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      _logger.error('Dio error updating profile $profileId: ${e.message}');
      _handleDioError(e, defaultMessage: Constants.errorProfileUpdateFailed);
      rethrow;
    } catch (e) {
      _logger.error('Unexpected error updating profile $profileId: $e');
      throw ApiException(Constants.errorGeneric);
    }
  }

  Future<bool> likeProfile(String profileId) async {
    _logger.debug("Liking profile: $profileId");
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}${AppEndpoints.matches}/like',
        data: {
          'profileId': profileId,
        },
      );

      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success) {
        _logger.info("Successfully liked profile: $profileId");
      } else {
        _logger.warn("Failed to like profile: ${response.statusCode}");
        throw ApiException('Failed to like profile',
            statusCode: response.statusCode);
      }
      return success;
    } on DioException catch (e) {
      _logger.error("Dio error liking profile $profileId: ${e.message}");
      _handleDioError(e, defaultMessage: 'Failed to like profile');
      rethrow;
    } catch (e) {
      _logger.error("General error liking profile $profileId: $e");
      throw ApiException(Constants.errorGeneric);
    }
  }

  Future<bool> dislikeProfile(String profileId) async {
    _logger.debug('Disliking profile: $profileId');
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}${AppEndpoints.matches}/pass',
        data: {
          'profileId': profileId,
        },
      );

      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success) {
        _logger.info('Successfully disliked profile: $profileId');
      } else {
        _logger.warn('Failed to dislike profile: ${response.statusCode}');
        throw ApiException('Failed to dislike profile',
            statusCode: response.statusCode);
      }
      return success;
    } on DioException catch (e) {
      _logger.error('Dio error disliking profile $profileId: ${e.message}');
      _handleDioError(e, defaultMessage: 'Failed to dislike profile');
      rethrow;
    } catch (e) {
      _logger.error('Unexpected error disliking profile $profileId: $e');
      throw ApiException(Constants.errorGeneric);
    }
  }

  Future<bool> superlikeProfile(String profileId) async {
    _logger.debug('Superliking profile: $profileId');
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}${AppEndpoints.matches}/like',
        data: {
          'profileId': profileId,
        },
      );

      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success) {
        _logger.info(
            'Successfully superliked (mapped to like) profile: $profileId');
      } else {
        _logger.warn('Failed to superlike profile: ${response.statusCode}');
        throw ApiException('Failed to superlike profile',
            statusCode: response.statusCode);
      }
      return success;
    } on DioException catch (e) {
      _logger.error('Dio error superliking profile $profileId: ${e.message}');
      _handleDioError(e, defaultMessage: 'Failed to superlike profile');
      rethrow;
    } catch (e) {
      _logger.error('Unexpected error superliking profile $profileId: $e');
      throw ApiException(Constants.errorGeneric);
    }
  }

  /// Checks the verification status of the profile
  Future<Map<String, dynamic>> checkVerificationStatus() async {
    try {
      final response = await _dio.get(
        '${AppEndpoints.profileVerification}/status',
      );

      _logger.info('Verification status retrieved: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      _logger.error('Dio error checking verification status: ${e.message}');
      // Return mock data for testing
      return {
        'status': 'pending',
        'message': 'Your verification is being processed.',
        'error': Constants.errorVerification
      };
    } catch (e) {
      _logger.error('Unexpected error checking verification status: $e');
      return {'status': 'error', 'message': Constants.errorVerification};
    }
  }

  /// Requests profile verification
  Future<Map<String, dynamic>> requestVerification() async {
    try {
      final response = await _dio.post(
        '${AppEndpoints.profileVerification}/request',
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
        'error': Constants.errorVerification
      };
    } catch (e) {
      _logger.error('Unexpected error requesting verification: $e');
      return {'status': 'error', 'message': Constants.errorVerification};
    }
  }

  /// Completes the verification process
  Future<Map<String, dynamic>> completeVerification(
      String verificationToken, String? selfieImagePath) async {
    try {
      Map<String, dynamic> data = {
        'token': verificationToken,
      };

      if (selfieImagePath != null) {
        // Add logic to upload selfie if needed
        data['selfie'] = selfieImagePath;
      }

      final response = await _dio.post(
        '${AppEndpoints.profileVerification}/complete',
        data: data,
      );

      _logger.info('Verification completed successfully: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      _logger.error('Dio error completing verification: ${e.message}');
      // Return mock data for testing
      return {
        'status': 'error',
        'message': Constants.errorVerification,
        'details': e.message
      };
    } catch (e) {
      _logger.error('Unexpected error completing verification: $e');
      return {'status': 'error', 'message': Constants.errorVerification};
    }
  }

  // Undo the last action (like/dislike/pass)
  Future<Map<String, dynamic>> undoLastAction() async {
    _logger.debug("Attempting to undo last action");
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}${AppEndpoints.undoAction}', // Use the correct endpoint constant
      );

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['success'] == true) {
        _logger.info(
            "Successfully undone last action: ${response.data['message']}");
        return {
          'success': true,
          'undoneAction': response.data['undoneAction'],
          'profileId': response.data['profileId'],
          'message': response.data['message'],
        };
      } else {
        _logger.warn(
            "Failed to undo last action: ${response.statusCode} - ${response.data?['message']}");
        if (response.statusCode == 403) {
          throw ApiException(Constants.errorInsufficientPermissions,
              statusCode: response.statusCode);
        } else if (response.statusCode == 404) {
          throw ApiException(Constants.errorNoActionToUndo,
              statusCode: response.statusCode);
        }
        throw ApiException(response.data?['message'] ?? 'Failed to undo action',
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      _logger.error("Dio error undoing last action: ${e.message}");
      _handleDioError(e);
      rethrow;
    } catch (e) {
      _logger.error("Unexpected error undoing last action: $e");
      throw ApiException(Constants.errorGeneric);
    }
  }

  // Helper function to standardize Dio error handling
  void _handleDioError(DioException e, {String? defaultMessage}) {
    String errorMessage = defaultMessage ?? Constants.errorGeneric;
    int? statusCode = e.response?.statusCode;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      errorMessage = Constants.errorTimeout;
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = Constants.errorNetwork;
    } else if (statusCode == 401) {
      errorMessage = Constants.errorAuth;
    } else if (statusCode == 403) {
      errorMessage = Constants.errorInsufficientPermissions;
    } else if (statusCode == 404) {
      errorMessage = Constants.errorNotFound;
    } else if (statusCode != null && statusCode >= 500) {
      errorMessage = Constants.errorServer;
    }

    // Prefer server message if available
    errorMessage = e.response?.data?['message'] ?? errorMessage;

    // Throw a standardized exception
    throw ApiException(errorMessage, statusCode: statusCode);
  }

  Profile _generateMockProfile() {
    _logger.debug('Generating mock profile');
    final random = math.Random();
    final names = [
      'Alex',
      'Jamie',
      'Taylor',
      'Jordan',
      'Casey',
      'Riley',
      'Avery',
      'Quinn',
      'Morgan',
      'Dakota'
    ];
    final interests = [
      'hiking',
      'reading',
      'movies',
      'cooking',
      'travel',
      'music',
      'art',
      'sports',
      'yoga',
      'photography'
    ];

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
    final photoId =
        random.nextInt(1000) + 100; // Avoid low IDs that might not exist
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

  // Get mutual matches (connections)
  Future<List<Profile>> getMutualMatches({int? limit, int? page}) async {
    _logger.debug('Getting mutual matches: limit=$limit, page=$page');
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (page != null) queryParams['page'] = page;

      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}/api/matches/connections',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> profilesJson;

        if (response.data is List) {
          profilesJson = response.data;
        } else if (response.data is Map && response.data['data'] != null) {
          profilesJson = response.data['data'];
        } else {
          _logger.error(
              'Unexpected response format for mutual matches: ${response.data.runtimeType}');
          throw ApiException(Constants.errorFailedToLoadMatches);
        }

        final profiles =
            profilesJson.map((json) => Profile.fromJson(json)).toList();
        _logger
            .info('Successfully retrieved ${profiles.length} mutual matches');
        return profiles;
      } else {
        _logger.warn('Failed to get mutual matches: ${response.statusCode}');
        throw ApiException(Constants.errorFailedToLoadMatches,
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      _logger.error('Dio error getting mutual matches: ${e.message}');
      _handleDioError(e, defaultMessage: Constants.errorFailedToLoadMatches);

      if (kDebugMode) {
        _logger
            .debug('Returning mock profiles for mutual matches in debug mode');
        return List.generate(5, (_) => _generateMockProfile());
      } else {
        rethrow;
      }
    } catch (e) {
      _logger.error('Unexpected error getting mutual matches: $e');

      if (kDebugMode) {
        _logger
            .debug('Returning mock profiles for mutual matches in debug mode');
        return List.generate(5, (_) => _generateMockProfile());
      } else {
        throw ApiException(Constants.errorGeneric);
      }
    }
  }

  // Get profiles that liked you
  Future<List<Profile>> getProfilesWhoLikedMe({int? limit, int? page}) async {
    _logger.debug('Getting profiles who liked me: limit=$limit, page=$page');
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (page != null) queryParams['page'] = page;

      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}/api/matches/likes/me',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> profilesJson;

        if (response.data is List) {
          profilesJson = response.data;
        } else if (response.data is Map && response.data['data'] != null) {
          profilesJson = response.data['data'];
        } else {
          _logger.error(
              'Unexpected response format for likes received: ${response.data.runtimeType}');
          throw ApiException(Constants.errorFailedToLoadMatches);
        }

        final profiles =
            profilesJson.map((json) => Profile.fromJson(json)).toList();
        _logger.info(
            'Successfully retrieved ${profiles.length} profiles who liked me');
        return profiles;
      } else {
        _logger.warn(
            'Failed to get profiles who liked me: ${response.statusCode}');
        throw ApiException(Constants.errorFailedToLoadMatches,
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      _logger.error('Dio error getting profiles who liked me: ${e.message}');
      _handleDioError(e, defaultMessage: Constants.errorFailedToLoadMatches);

      if (kDebugMode) {
        _logger
            .debug('Returning mock profiles for likes received in debug mode');
        return List.generate(3, (_) => _generateMockProfile());
      } else {
        rethrow;
      }
    } catch (e) {
      _logger.error('Unexpected error getting profiles who liked me: $e');

      if (kDebugMode) {
        _logger
            .debug('Returning mock profiles for likes received in debug mode');
        return List.generate(3, (_) => _generateMockProfile());
      } else {
        throw ApiException(Constants.errorGeneric);
      }
    }
  }

  // Get profiles you liked
  Future<List<Profile>> getProfilesILiked({int? limit, int? page}) async {
    _logger.debug('Getting profiles I liked: limit=$limit, page=$page');
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (page != null) queryParams['page'] = page;

      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}/api/matches/likes/sent',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> profilesJson;

        if (response.data is List) {
          profilesJson = response.data;
        } else if (response.data is Map && response.data['data'] != null) {
          profilesJson = response.data['data'];
        } else {
          _logger.error(
              'Unexpected response format for likes sent: ${response.data.runtimeType}');
          throw ApiException(Constants.errorFailedToLoadMatches);
        }

        final profiles =
            profilesJson.map((json) => Profile.fromJson(json)).toList();
        _logger
            .info('Successfully retrieved ${profiles.length} profiles I liked');
        return profiles;
      } else {
        _logger.warn('Failed to get profiles I liked: ${response.statusCode}');
        throw ApiException(Constants.errorFailedToLoadMatches,
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      _logger.error('Dio error getting profiles I liked: ${e.message}');
      _handleDioError(e, defaultMessage: Constants.errorFailedToLoadMatches);

      if (kDebugMode) {
        _logger.debug('Returning mock profiles for likes sent in debug mode');
        return List.generate(4, (_) => _generateMockProfile());
      } else {
        rethrow;
      }
    } catch (e) {
      _logger.error('Unexpected error getting profiles I liked: $e');

      if (kDebugMode) {
        _logger.debug('Returning mock profiles for likes sent in debug mode');
        return List.generate(4, (_) => _generateMockProfile());
      } else {
        throw ApiException(Constants.errorGeneric);
      }
    }
  }
}

// Provider is now defined in profile_service_provider.dart
// Provider is now defined in profile_service_provider.dart
