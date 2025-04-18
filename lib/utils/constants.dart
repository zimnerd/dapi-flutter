/// Application-wide constants
class Constants {
  // Application
  static const String APP_NAME = "Fluttr";
  static const String APP_VERSION = "1.0.0";
  
  // API
  static const String API_BASE_URL = 'http://dapi.pulsetek.co.za:3001';
  
  // Storage Keys
  static const String TOKEN_KEY = "auth_token";
  static const String REFRESH_TOKEN_KEY = "refresh_token";
  static const String USER_ID_KEY = "user_id";
  
  // Images
  static const String DEFAULT_PROFILE_IMAGE = "assets/images/default_profile.png";
  static const String APP_LOGO = "assets/images/logo.png";
  
  // Animation durations
  static const int ANIMATION_DURATION = 300; // milliseconds
  
  // Original Error Messages (for backward compatibility)
  static const String ERROR_GENERIC = "Something went wrong. Please try again.";
  static const String ERROR_NETWORK = "No internet connection. Please check your network.";
  static const String ERROR_SERVER = "Server error. Please try again later.";
  static const String ERROR_UNAUTHORIZED = "Session expired. Please login again.";
  static const String ERROR_PROFILE_LOAD = "Could not load profiles. Please try again.";
  static const String ERROR_CHAT_LOAD = "Could not load messages. Please try again.";
  static const String ERROR_IMAGE_UPLOAD = "Failed to upload image. Please try again.";
  static const String ERROR_VERIFICATION = "Verification failed. Please try again.";
  
  // Enhanced Error Messages (new naming convention)
  static const String errorNetworkUnavailable = ERROR_NETWORK;
  static const String errorServerUnreachable = ERROR_SERVER;
  static const String errorTimeout = "Request timed out. Please try again.";
  static const String errorUnauthorized = ERROR_UNAUTHORIZED;
  static const String errorUnknown = ERROR_GENERIC;
  static const String errorInvalidCredentials = "Invalid email or password.";
  static const String errorEmailAlreadyInUse = "This email is already in use.";
  static const String errorInvalidEmail = "Please enter a valid email address.";
  static const String errorWeakPassword = "Password is too weak. Please use a stronger password.";
  static const String errorPasswordMismatch = "Passwords do not match.";
  static const String errorProfileNotFound = "Profile not found.";
  static const String errorFailedToLoadProfiles = ERROR_PROFILE_LOAD;
  static const String errorFailedToLoadMatches = "Failed to load matches.";
  static const String errorFailedToLoadConversations = "Failed to load conversations.";
  static const String errorFailedToLoadMessages = ERROR_CHAT_LOAD;
  static const String errorFailedToSendMessage = "Failed to send message.";
  static const String errorProfileUpdateFailed = "Failed to update profile.";
  static const String errorPhotoUploadFailed = ERROR_IMAGE_UPLOAD;
  static const String errorVerificationFailed = ERROR_VERIFICATION;
  static const String errorInsufficientPermissions = "You do not have permission to perform this action.";
  static const String errorFileTooBig = "File is too big. Maximum size is 5MB.";
  static const String errorInvalidFileFormat = "Invalid file format.";
  static const String errorEmptyFields = "Please fill all required fields.";
  
  // Defaults
  static const int defaultPageSize = 10;
  static const Duration defaultAnimationDuration = Duration(milliseconds: ANIMATION_DURATION);
  static const String defaultLocale = 'en';
  static const int defaultMaxPhotoCount = 9;
  static const int maxNameLength = 50;
  static const int maxBioLength = 500;
  
  // SharedPreferences Keys
  static const String prefKeyToken = TOKEN_KEY;
  static const String prefKeyUserId = USER_ID_KEY;
  static const String prefKeyUser = 'user_data';
  static const String prefKeyOnboarded = 'onboarded';
  static const String prefKeyThemeMode = 'theme_mode';
  static const String prefKeyAppLocale = 'app_locale';
  static const String prefKeyLastSyncTime = 'last_sync_time';
  
  // Routes
  static const String routeRoot = '/';
  static const String routeAuth = '/auth';
  static const String routeLogin = '/auth/login';
  static const String routeRegister = '/auth/register';
  static const String routeDiscover = '/discover';
  static const String routeProfile = '/profile';
  static const String routeEditProfile = '/profile/edit';
  static const String routeMatches = '/matches';
  static const String routeChat = '/chat';
  static const String routeSettings = '/settings';
  static const String routeVerification = '/verification';
  
  // Asset Paths
  static const String assetPathLogo = APP_LOGO;
  static const String assetPathPlaceholder = 'assets/images/placeholder.png';
  static const String assetPathNoProfileImage = DEFAULT_PROFILE_IMAGE;
  
  // Error Code Constants
  static const int statusCodeBadRequest = 400;
  static const int statusCodeUnauthorized = 401;
  static const int statusCodeForbidden = 403;
  static const int statusCodeNotFound = 404;
  static const int statusCodeTimeout = 408;
  static const int statusCodeServerError = 500;
  
  // Validation Patterns
  static final RegExp emailPattern = 
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp passwordPattern = 
      RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
  
  // API Error Keys
  static const String apiErrorKeyValidation = 'validation_error';
  static const String apiErrorKeyAuthentication = 'authentication_error';
  static const String apiErrorKeyAuthorization = 'authorization_error';
  static const String apiErrorKeyNotFound = 'not_found';
  static const String apiErrorKeyServer = 'server_error';
  
  // Cache Durations
  static const Duration cacheMaxAge = Duration(hours: 24);
  static const Duration cacheStaleWhileRevalidate = Duration(hours: 1);

  // App Constants
  static const String appName = 'Dating App';
  static const String appVersion = '1.0.0';
  
  // Date Formats
  static const String dateFormatFull = 'MMMM dd, yyyy';
  static const String dateFormatShort = 'MM/dd/yyyy';
  static const String timeFormat = 'h:mm a';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);
  
  // Validation Regex
  static final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
  
  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String authError = 'Authentication error. Please log in again.';
  static const String profileLoadError = 'Could not load profile data. Pull down to refresh.';
  static const String chatError = 'Could not load chat messages. Please try again.';
  static const String imageUploadError = 'Failed to upload image. Please try again.';
  static const String verificationError = 'Verification failed. Please try again later.';
  static const String locationError = 'Location services not available. Distance features may not work.';
  static const String permissionError = 'Permission denied. Some features may not work correctly.';
  static const String connectionError = 'Connection lost. Please check your internet connection.';
  static const String sessionExpiredError = 'Your session has expired. Please log in again.';
  
  // Success Messages
  static const String profileUpdated = 'Profile updated successfully.';
  static const String photoUploaded = 'Photo uploaded successfully.';
  static const String messageSent = 'Message sent.';
  static const String matchFound = 'It\'s a match!';
  
  // Cache Keys
  static const String profileCacheKey = 'profile_cache';
  static const String matchesCacheKey = 'matches_cache';
  static const String conversationsCacheKey = 'conversations_cache';
  
  // Misc
  static const int cacheExpirationDays = 2; // Days until cache expiration
  static const int maxImagesPerProfile = 9;
  static const int maxDistanceKm = 100;
} 