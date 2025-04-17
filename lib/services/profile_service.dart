import 'dart:convert';
import 'dart:math';
import 'dart:io'; // Import File for upload
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import 'api_config.dart';
import 'auth_service.dart';
import 'api_client.dart';
import 'package:dating_app/utils/constants.dart';

class ProfileService {
  final Dio _dio;
  
  ProfileService(this._dio);
  
  // Get profile by ID
  Future<Profile> getProfile(int id) async {
    try {
      final response = await _dio.get('/profiles/$id');
      
      if (response.statusCode == 200 && response.data != null) {
        final profileData = response.data;
        return Profile.fromJson(profileData);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to load profile (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      print('⟹ [ProfileService] Get Profile Dio error: ${e.message}');
       String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Failed to load profile';
       if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please log in again.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('⟹ [ProfileService] Get Profile general error: $e');
      throw Exception('Failed to load profile: ${e.toString()}');
    }
  }
  
  // Get profiles for discover screen
  Future<List<Profile>> getDiscoverProfiles({Map<String, String>? queryParams}) async {
    print('⟹ [ProfileService] Getting discover profiles...');
    try {
      final response = await _dio.get(
        '/profiles/discover', 
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        print('⟹ [ProfileService] Found ${data.length} profiles from API');
        return data.map((json) => Profile.fromJson(json)).toList();
      } else {
         print('⟹ [ProfileService] Discover API failed or returned invalid data: ${response.statusCode}');
         return _getMockDiscoverProfiles();
      }
    } on DioException catch (e) {
      print('⟹ [ProfileService] Discover Dio error: ${e.message}');
      print('⟹ [ProfileService] Falling back to mock data due to API error.');
      return _getMockDiscoverProfiles(); 
    } catch (e) {
      print('⟹ [ProfileService] Discover general error: $e');
      print('⟹ [ProfileService] Falling back to mock data due to general error.');
      return _getMockDiscoverProfiles(); 
    }
  }
  
  // Generate mock profiles for development
  List<Profile> _getMockDiscoverProfiles() {
    print("⚠️ Using Mock Discover Profiles");
    return List.generate(10, (index) {
       final gender = index % 2 == 0 ? 'male' : 'female';
       return Profile(
        id: 1000 + index,
        name: 'User ${index + 1}',
        age: 20 + (index % 15),
        gender: gender,
        photoUrls: _getMultiplePhotos(index, gender),
        interests: _getRandomInterests(index),
        birthDate: DateTime.now().subtract(Duration(days: 365 * (20 + (index % 15)))),
        bio: "Just a mock profile looking for connection! Love ${ _getRandomInterests(index).first.toLowerCase()} and exploring.",
        location: "Mock City, MC",
        distance: Random().nextDouble() * 50,
        isVerified: index % 3 == 0,
      );
    });
  }
  
  // Generate multiple photos for each profile
  List<String> _getMultiplePhotos(int index, String gender) {
    final photoCount = 2 + (index % 4);
    final List<String> photos = [];
    
    for (int i = 1; i <= photoCount; i++) {
      final photoId = ((index * 3 + i) % 99) + 1;
      photos.add('https://randomuser.me/api/portraits/$gender/$photoId.jpg');
    }
    
    return photos;
  }
  
  List<String> _getRandomInterests(int seed) {
    final allInterests = [
      'Hiking', 'Reading', 'Cooking', 'Travel', 'Photography',
      'Movies', 'Music', 'Sports', 'Art', 'Technology',
      'Fitness', 'Dancing', 'Gaming', 'Yoga', 'Meditation',
    ];
    
    final count = 3 + (seed % 3);
    final selected = <String>[];
    final random = Random(seed);
    final available = List<String>.from(allInterests);
    for (int i = 0; i < count; i++) {
       if (available.isEmpty) break;
       final randomIndex = random.nextInt(available.length);
       selected.add(available.removeAt(randomIndex));
    }
    return selected;
  }
  
  // Update profile
  Future<Profile> updateProfile(int id, Map<String, dynamic> data) async {
    print('⟹ [ProfileService] Updating profile $id...');
    try {
      final response = await _dio.patch(
        '/profiles/$id',
        data: data,
      );
      
      if (response.statusCode == 200 && response.data != null) {
         print('⟹ [ProfileService] Profile $id updated successfully.');
        return Profile.fromJson(response.data);
      } else {
         throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to update profile (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      print('⟹ [ProfileService] Update Profile Dio error: ${e.message}');
       String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Failed to update profile';
       if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please log in again.';
      }
      throw Exception(errorMessage);
    } catch (e) { 
       print('⟹ [ProfileService] Update Profile general error: $e');
       throw Exception('Failed to update profile: ${e.toString()}');
    }
  }
  
  // Create profile
  Future<Profile> createProfile(Map<String, dynamic> profileData) async {
     print('⟹ [ProfileService] Creating profile...');
    try {
      final response = await _dio.post(
        '/profiles',
        data: profileData,
      );
      
      if (response.statusCode == 201 && response.data != null) {
         print('⟹ [ProfileService] Profile created successfully with ID: ${response.data['id']}');
        return Profile.fromJson(response.data);
      } else {
         throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to create profile (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      print('⟹ [ProfileService] Create Profile Dio error: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Failed to create profile';
       if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please log in again.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('⟹ [ProfileService] Create Profile general error: $e');
      throw Exception('Failed to create profile: ${e.toString()}');
    }
  }

  // Method to get current user profile (might use AuthService or a dedicated endpoint)
  Future<Profile> getCurrentUserProfile() async {
     print('⟹ [ProfileService] Getting current user profile...');
     try {
       final response = await _dio.get('/profiles/me');
       if (response.statusCode == 200 && response.data != null) {
         return Profile.fromJson(response.data);
       } else {
          throw DioException(requestOptions: response.requestOptions, response: response);
       }
     } on DioException catch (e) {
       print('⟹ [ProfileService] Get Current Profile Dio error: ${e.message}');
       return _getMockCurrentUserProfile();
     } catch (e) {
       print('⟹ [ProfileService] Get Current Profile general error: $e');
       return _getMockCurrentUserProfile();
     }
  }

  // Mock current user profile for fallback
  Profile _getMockCurrentUserProfile() {
      print("⚠️ Using Mock Current User Profile");
      return Profile(
          id: 0,
          name: 'Current User',
          age: 28,
          gender: 'non-binary',
          photoUrls: ['https://randomuser.me/api/portraits/lego/1.jpg'],
          interests: ['Flutter', 'Testing'],
          birthDate: DateTime.now().subtract(const Duration(days: 365 * 28)),
          bio: 'App developer creating this mock profile.',
          location: 'Localhost',
          isVerified: true,
      );
  }

  // Fetch photos for a profile (if not included in main profile response)
  Future<List<String>> _getProfilePhotos(int profileId) async {
     print('⟹ [ProfileService] Getting photos for profile $profileId...');
     try {
       final response = await _dio.get('/photos', queryParameters: {'profile_id': profileId});
       if (response.statusCode == 200 && response.data is List) {
         return (response.data as List).map((photo) => photo['url'].toString()).toList();
       }
       return [];
     } catch (e) {
       print('Error fetching photos for $profileId: $e');
       return [];
     }
  }

  // Fetch interests for a profile (if not included)
  Future<List<String>> _getProfileInterests(int profileId) async {
     print('⟹ [ProfileService] Getting interests for profile $profileId...');
    try {
        final response = await _dio.get('/profile-interests', queryParameters: {'profile_id': profileId}); 
       if (response.statusCode == 200 && response.data is List) {
         return (response.data as List)
                .map((item) => item?['interest']?['name']?.toString())
                .where((name) => name != null)
                .cast<String>()
                .toList();
       }
       return [];
     } catch (e) {
       print('Error fetching interests for $profileId: $e');
       return [];
     }
  }

  // Fetch gender preferences (if needed separately)
  Future<Map<String, dynamic>> _getGenderPreferences(int profileId) async {
    return {};
  }
  
  // Like/Dislike/Superlike actions

  Future<void> likeProfile(int profileId) async {
     print('⟹ [ProfileService] Liking profile $profileId...');
     try {
       await _dio.post('/profiles/$profileId/like');
     } on DioException catch (e) {
        print('⟹ [ProfileService] Like Profile Dio error: ${e.message}');
        throw Exception(e.response?.data?['message'] ?? 'Failed to like profile');
     } catch (e) {
        print('⟹ [ProfileService] Like Profile general error: $e');
        throw Exception('Failed to like profile');
     }
  }

  Future<void> dislikeProfile(int profileId) async {
     print('⟹ [ProfileService] Disliking profile $profileId...');
     try {
       await _dio.post('/profiles/$profileId/pass');
     } on DioException catch (e) {
       throw Exception(e.response?.data?['message'] ?? 'Failed to dislike profile');
     } catch (e) {
       throw Exception('Failed to dislike profile');
     }
  }

  Future<void> superlikeProfile(int profileId) async {
    print('⟹ [ProfileService] Superliking profile $profileId...');
    try {
      await _dio.post('/profiles/$profileId/superlike');
    } on DioException catch (e) {
       throw Exception(e.response?.data?['message'] ?? 'Failed to superlike profile');
    } catch (e) {
       throw Exception('Failed to superlike profile');
    }
  }

  // Upload profile photo
  Future<String?> uploadProfilePhoto(int profileId, File imageFile) async {
    print('⟹ [ProfileService] Uploading photo for profile $profileId...');
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        // Adjust the field name ("photo", "file", "image", etc.) 
        // based on your backend API requirements.
        "photo": await MultipartFile.fromFile(
          imageFile.path, 
          filename: fileName
        ),
        // You might need to send the profile ID as part of the form data
        // depending on the endpoint structure.
        // "profile_id": profileId,
      });

      // Adjust the endpoint path ('/profiles/$profileId/photo', '/photos', etc.) 
      // based on your API design.
      final response = await _dio.post(
        '/profiles/$profileId/photos', // Example endpoint
        data: formData,
        options: Options(
           headers: {
             // Ensure content-type is multipart/form-data
             Headers.contentTypeHeader: Headers.multipartFormDataContentType,
             // Add any other required headers like Authorization
           }
        )
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Assuming the backend returns the URL of the uploaded photo
        // Adjust the response parsing based on your actual API response structure.
        final String? photoUrl = response.data?['url'];
        print('⟹ [ProfileService] Photo uploaded successfully. URL: $photoUrl');
        return photoUrl; 
      } else {
        print('⟹ [ProfileService] Photo upload failed with status ${response.statusCode}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to upload photo (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      print('⟹ [ProfileService] Photo Upload Dio error: ${e.response?.data ?? e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Failed to upload photo';
      throw Exception(errorMessage);
    } catch (e) {
      print('⟹ [ProfileService] Photo Upload general error: $e');
      throw Exception('Failed to upload photo: ${e.toString()}');
    }
  }
}