import 'package:flutter/foundation.dart' show kDebugMode;

/// API endpoints configuration
///
/// This class defines all API endpoints used in the application.
/// Endpoints are organized by functional area (auth, profiles, matches, etc.)
///
/// Naming convention:
/// - Use camelCase for endpoint constants
/// - Group related endpoints together
/// - Use descriptive names that reflect the endpoint's purpose
///
/// Base URL configuration is in the AppConfig class at the bottom of this file.
/// The actual URL used in requests will be: `AppConfig.apiBaseUrl + AppEndpoints.endpointName`
class AppEndpoints {
  // Auth endpoints - User authentication and account management
  static const String login = '/auth/login';
  static const String biometricLogin = '/auth/biometric-login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String verifyEmail = '/auth/verify-email';
  static const String resetPassword = '/auth/reset-password';
  static const String forgotPassword = '/auth/forgot-password';

  // Profile endpoints - User profile management
  static const String profiles = '/profiles';
  static const String currentProfile = '/profiles/me';
  static const String discoverProfiles = '/profiles/discover';
  static const String uploadPhoto = '/profiles/photo';
  static const String deletePhoto = '/profiles/photo/delete';
  static const String profilePhotos = '/profiles/photos';
  static const String profileVerification = '/profiles/verify';
  static const String updatePreferences = '/profiles/preferences';
  static const String profileAction = '/profiles/action';

  // Match endpoints - Match management and interactions
  static const String matches = '/matches';
  static const String like = '/matches/like';
  static const String dislike = '/matches/dislike';
  static const String pass = '/matches/pass';
  static const String superlike = '/matches/superlike';
  static const String unmatch = '/matches/unmatch';
  static const String undoAction = '/matches/undo';

  // Chat endpoints - Conversation and message management
  static const String conversations = '/conversations';
  static const String messages = '/messages';
  static const String readMessages = '/messages/read';
  static const String deleteMessage = '/messages/delete';
  static const String reactToMessage = '/messages/react';

  // Method to get messages for a specific conversation
  static String conversationMessages(String conversationId) {
    return '/conversations/$conversationId/messages';
  }

  // Settings endpoints - User settings and preferences
  static const String settings = '/settings';
  static const String notifications = '/settings/notifications';
  static const String privacy = '/settings/privacy';
  static const String blockedUsers = '/settings/blocked';
  static const String reportUser = '/settings/report';

  /// Legacy Profile API endpoints (to be deprecated)
  static const String userProfile = '/profiles/me';
  static const String likeProfile = '/profiles/:id/like';
  static const String dislikeProfile = '/profiles/:id/dislike';
  static const String superlikeProfile = '/profiles/:id/superlike';
  static const String verificationStatus = '/profiles/verification/status';
  static const String requestVerification = '/profiles/verification/request';
  static const String completeVerification = '/profiles/verification/complete';
}

/// Request key constants
class AppRequestKeys {
  static const String email = 'email';
  static const String password = 'password';
  static const String name = 'name';
  static const String birthDate = 'birth_date';
  static const String gender = 'gender';
  static const String refreshToken = 'refresh_token';
  static const String token = 'token';
  static const String profileId = 'profile_id';
  static const String message = 'message';
  static const String photos = 'photos';
  static const String interests = 'interests';
  static const String location = 'location';
  static const String maxDistance = 'max_distance';
  static const String ageRange = 'age_range';
  static const String genderPreference = 'gender_preference';
  static const String biometricAuthenticated = 'biometric_authenticated';
}

/// Response key constants
class AppResponseKeys {
  static const String data = 'data';
  static const String message = 'message';
  static const String error = 'error';
  static const String token = 'token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String profileId = 'profile_id';
  static const String conversationId = 'conversation_id';
  static const String messageId = 'message_id';
  static const String timestamp = 'timestamp';
  static const String pagination = 'pagination';
  static const String total = 'total';
  static const String page = 'page';
  static const String perPage = 'per_page';
  static const String lastPage = 'last_page';
  static const String status = 'status';
  static const String code = 'code';
  static const String profiles = 'profiles';
  static const String matches = 'matches';
  static const String chat = 'chat';
}

/// Storage key constants
class AppStorageKeys {
  static const String token = 'auth_token';
  static const String accessToken =
      'auth_token'; // Alias for token for compatibility
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String profileId = 'profile_id';
  static const String filters = 'filters';
  static const String theme = 'theme';
  static const String onboardingComplete = 'onboarding_complete';
  static const String authToken =
      'auth_token'; // Another alias for compatibility
}

/// HTTP header constants
class AppHeaders {
  static const String contentType = 'Content-Type';
  static const String accept = 'Accept';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
  static const String applicationJson = 'application/json';
}

/// HTTP status code constants
class AppStatusCodes {
  static const int success = 200;
  static const int created = 201;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int serverError = 500;
}

/// Error message constants
class AppErrorMessages {
  static const String networkError = 'Network error occurred';
  static const String serverError = 'Server error occurred';
  static const String unauthorized = 'Unauthorized access';
  static const String invalidCredentials = 'Invalid credentials';
  static const String profileNotFound = 'Profile not found';
  static const String matchError = 'Error processing match action';
  static const String chatError = 'Error in chat operation';
  static const String loginFailed =
      'Login failed. Please check your credentials.';
  static const String biometricLoginFailed =
      'Biometric login failed. Please try again.';
  static const String registrationFailed =
      'Registration failed. Please try again.';
  static const String unexpectedError = 'An unexpected error occurred.';
}

/// Animation duration constants
class AppAnimationDurations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration long = Duration(milliseconds: 600);
}

/// Asset path constants
class AppAssets {
  static const String defaultAvatar = 'assets/images/user_placeholder.png';
  static const String logo = 'assets/images/logo.png';
  static const String placeholder = 'assets/images/user_placeholder.png';
  static const String loadingAnimation = 'assets/animations/loading.json';
  static const String matchAnimation = 'assets/animations/match.json';
  static const String defaultFemale = 'assets/images/user_placeholder.png';
  static const String defaultMale = 'assets/images/user_placeholder.png';
}

/// Application-wide configuration and constants
class AppConfig {
  // App metadata
  static const String appName = 'Dating App';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String environment = 'development';

  /// API URL Configuration
  ///
  /// The app uses different base URLs depending on the environment:
  /// - Development: Local development server or test server
  /// - Mock: Mock API server for testing with dummy data
  /// - Production: Live production API
  ///
  /// The actual URL used is determined by the apiBaseUrl getter below,
  /// which selects the appropriate URL based on the build mode.
  // static const String _devApiBaseUrl =
  //     'https://dapi.pulsetek.co.za:3000/api/v1';
  static const String _mockApiBaseUrl =
      'https://dapi.pulsetek.co.za:3000/api/v1';
  static const String _prodApiBaseUrl =
      'https://dapi.pulsetek.co.za:3000/api/v1';

  // WebSocket URLs for real-time features
  // static const String _devSocketUrl = 'wss://dapi.pulsetek.co.za:3000';
  static const String _mockSocketUrl = 'wss://dapi.pulsetek.co.za:3000';
  static const String _prodSocketUrl = 'wss://dapi.pulsetek.co.za:3000';

  // Dynamic getters for environment-specific values
  static String get apiBaseUrl {
    if (kDebugMode) {
      return _mockApiBaseUrl;
    }
    return _prodApiBaseUrl;
  }

  static String get socketUrl {
    if (kDebugMode) {
      return _mockSocketUrl;
    }
    return _prodSocketUrl;
  }

  // Network timeouts in milliseconds
  static const int networkTimeoutMs = 30000;

  // UI configuration
  static const double defaultBorderRadius = 8.0;
  static const double defaultPadding = 16.0;

  // Default values
  static const double maxDistance = 100.0;
  static const double minAge = 18.0;
  static const double maxAge = 50.0;
  static const double defaultAgeMin = 18.0;
  static const double defaultAgeMax = 50.0;

  // Test account for development
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'password123';

  // External API keys
  static const String giphyApiKey = 'your_giphy_api_key_here';
}
