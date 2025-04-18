// API base URLs
final String apiBaseUrl = 'http://dapi.pulsetek.co.za:3001';
final String socketUrl = 'ws://localhost:3000';

// API Endpoints
class AppEndpoints {
  static const String login = '/api/auth/login';
  static const String biometricLogin = '/api/auth/biometric-login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String refreshToken = '/api/auth/refresh';
  static const String resetPassword = '/api/auth/reset-password';
  
  // Profile endpoints
  static const String profile = '/api/profile';
  static const String profiles = '/api/profiles';
  static const String updateProfile = '/api/profile/update';
  static const String uploadPhoto = '/api/profile/upload-photo';
  
  // Matching endpoints
  static const String matches = '/api/matches';
  static const String like = '/api/matches/like';
  static const String likeWithBody = '/api/matches/like-body';
  static const String dislike = '/api/matches/dislike';
  static const String superlike = '/api/matches/superlike';
  
  // Chat endpoints
  static const String conversations = '/api/conversations';
  static const String messages = '/api/messages';
}

// Status codes
class AppStatusCodes {
  static const int success = 200;
  static const int created = 201;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int conflict = 409;
  static const int serverError = 500;
}

// Request and response keys
class AppRequestKeys {
  static const String email = 'email';
  static const String password = 'password';
  static const String name = 'name';
  static const String birthDate = 'birth_date';
  static const String gender = 'gender';
  static const String refreshToken = 'refresh_token';
  static const String biometricAuthenticated = 'biometric_authenticated';
}

class AppResponseKeys {
  static const String token = 'token';
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String message = 'message';
  static const String data = 'data';
  static const String user = 'user';
  static const String profile = 'profile';
}

// Storage keys
class AppStorageKeys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String profileId = 'profile_id';
}

// Error messages
class AppErrorMessages {
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String loginFailed = 'Login failed. Please check your credentials.';
  static const String registrationFailed = 'Registration failed. Please try again.';
  static const String biometricLoginFailed = 'Biometric login failed. Please try again.';
  static const String invalidCredentials = 'Invalid credentials.';
  static const String emailAlreadyExists = 'Email already exists.';
  static const String unexpectedError = 'An unexpected error occurred.';
} 