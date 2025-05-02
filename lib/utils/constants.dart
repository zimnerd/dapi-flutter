/// Application-wide constants
// Top-level constants for app-wide use
const String appName = 'HeartLink';
const String appVersion = '1.0.0';
const String tokenKey = 'auth_token';
const String refreshTokenKey = 'refresh_token';
const String userIdKey = 'user_id';
const String defaultProfileImage = 'assets/images/default_profile.png';
const String appLogo = 'assets/images/logo.png';
const Duration animationDuration = Duration(milliseconds: 300);
const String errorGeneric = 'An unexpected error occurred.';
const String errorNetwork = 'Network error occurred.';
const String errorServer = 'Server error occurred.';
const String errorUnauthorized = 'Unauthorized access.';
const String errorProfileLoad = 'Failed to load profile.';
const String errorChatLoad = 'Failed to load chat.';
const String errorImageUpload = 'Failed to upload image.';
const String errorVerification = 'Verification failed.';
const String errorUnknown = errorGeneric;
const String errorConnectionLost =
    'Connection lost. Please check your internet connection.';
const String errorNetworkTimeout =
    'Network request timed out. Please try again.';
const String errorTimeout = errorNetworkTimeout;
const String errorResponseFormat =
    'Received an unexpected response from the server.';
const String errorAuth = 'Authentication error. Please log in again.';
const String errorSessionExpired =
    'Your session has expired. Please log in again.';
const String errorFileTooBig = 'File is too big. Maximum size is 5MB.';
const String errorInvalidFileFormat = 'Invalid file format.';
const String errorInvalidEmail = 'Please enter a valid email address.';
const String errorInvalidPassword = 'Password must be at least 6 characters.';
const String errorPasswordsDoNotMatch = 'Passwords do not match.';
const String errorFieldRequired = 'This field is required.';
const String errorProfileUpdate = 'Failed to update profile.';
const String errorProfileIncomplete = 'Please complete your profile.';
const String errorSendMessage = 'Failed to send message.';
const String dateFormat = 'yyyy-MM-dd';
const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
const Duration shortAnimation = Duration(milliseconds: 200);
const Duration mediumAnimation = Duration(milliseconds: 400);
const Duration longAnimation = Duration(milliseconds: 600);
const Duration cacheMaxAge = Duration(hours: 24);
const Duration cacheStaleWhileRevalidate = Duration(hours: 1);
const int statusCodeUnauthorized = 401;
const int statusCodeNotFound = 404;
const int statusCodeServerError = 500;

// Images
// const String defaultProfileImage = 'assets/images/default_profile.png';
// const String appLogo = 'assets/images/logo.png';

// Animation durations
// const Duration animationDuration = Duration(milliseconds: 300); // milliseconds

// --- Error Messages ---
// Generic Errors
// Remove all static consts and commented-out static consts below this line.

// Network & Server Errors
// Remove all static consts and commented-out static consts below this line.

// Authentication & Authorization Errors
// Remove all static consts and commented-out static consts below this line.

// Permission & Resource Errors
// Remove all static consts and commented-out static consts below this line.

// Data Loading/Saving Errors
// Remove all static consts and commented-out static consts below this line.

// File & Upload Errors
// Remove all static consts and commented-out static consts below this line.

// Validation Errors
// Remove all static consts and commented-out static consts below this line.

// == RESTORED SECTION 2: Aliases (if these were separate) ==
// Note: Many of these are now duplicated in the block above,
// this might cause issues but restoring as requested.
// Consider consolidating later.
// Remove all static consts and commented-out static consts below this line.
