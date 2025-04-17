// API configuration constants for the dating app

// Base URLs for different environments
const String devApiBaseUrl = 'http://localhost:3001';
const String mockApiBaseUrl = 'http://dapi.pulsetek.co.za:3001';
const String prodApiBaseUrl = 'http://dapi.pulsetek.co.za:3001'; // Update with actual production URL

// Active API base URL - change this to switch environments
const String apiBaseUrl = mockApiBaseUrl;

// API endpoints
class ApiEndpoints {
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  
  // Profile endpoints
  static const String myProfile = '/profiles/me';
  static const String updateProfile = '/profiles';
  static const String uploadPhoto = '/profiles/photo';
  static const String discoverProfiles = '/profiles/discover';
  
  // Matches endpoints
  static const String matches = '/matches';
  static const String like = '/matches/like';
  static const String pass = '/matches/pass';
  static const String unmatch = '/matches/unmatch';
  
  // Messaging endpoints
  static const String conversations = '/conversations';
  static const String messages = '/messages';
  static const String unreadCount = '/messages/unread-count';
  
  // User settings endpoints
  static const String settings = '/settings';
  static const String notifications = '/settings/notifications';
  static const String privacy = '/settings/privacy';
}

// API response keys
class ApiResponseKeys {
  static const String message = 'message';
  static const String data = 'data';
  static const String error = 'error';
  static const String token = 'token';
  static const String refreshToken = 'refreshToken';
  static const String user = 'user';
  static const String profile = 'profile';
} 