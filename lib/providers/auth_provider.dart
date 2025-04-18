import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart'; // Assuming User model exists
import '../models/login_response.dart'; // Import the new login response model
import '../services/api_client.dart';
import '../utils/logger.dart';
import '../config/app_config.dart';
import 'providers.dart'; // Import providers.dart for access to dioProvider and secureStorageProvider

// Enum for Authentication Status
enum AuthStatus { unknown, authenticated, unauthenticated, authenticating }

// Import secureStorageProvider from providers.dart rather than redefining it here
// final secureStorageProvider is now imported from providers.dart

// Import dioProvider from providers.dart rather than redefining it here
// final dioProvider is now imported from providers.dart

// State class for Authentication
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

// StateNotifier for Authentication
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final _logger = Logger('Auth');

  AuthNotifier(this._ref) : super(const AuthState()) {
    _logger.info('Initializing AuthNotifier');
    checkInitialAuthStatus();
  }

  Future<void> checkInitialAuthStatus() async {
    _logger.debug('Checking initial authentication status');
    try {
      final storage = _ref.read(secureStorageProvider);
      final token = await storage.read(key: AppStorageKeys.token);
      
      _logger.debug('Access token exists: ${token != null}');
      
      if (token != null) {
        // Optionally fetch user details here if needed upon app start
        final user = await _getCurrentUserFromPrefs();
        _logger.info('User authenticated from stored token: ${user?.id}');
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        _logger.info('No token found, user is unauthenticated');
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e, stackTrace) {
      _logger.error('Error checking initial auth status: $e');
      _logger.error('Stack trace: $stackTrace');
      state = AuthState(
        status: AuthStatus.unauthenticated, 
        errorMessage: 'Failed to check authentication: $e'
      );
    }
  }

  Future<User?> _getCurrentUserFromPrefs() async {
    _logger.debug('Getting current user from preferences');
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final userId = prefs.getString(AppStorageKeys.userId);
      final userEmail = prefs.getString(AppStorageKeys.userEmail);
      final userName = prefs.getString(AppStorageKeys.userName);
      final profileId = prefs.getString('profileId');

      _logger.debug('User info from prefs - userId: ${userId != null}, email: ${userEmail != null}, name: ${userName != null}, profileId: ${profileId != null}');

      if (userId != null && userEmail != null && userName != null) {
        _logger.debug('Successfully retrieved user from preferences');
        return User(
          id: userId,
          email: userEmail,
          name: userName,
          profileId: profileId,
        );
      }
      _logger.warn('Incomplete user data in preferences');
      return null;
    } catch (e, stackTrace) {
      _logger.error('Error retrieving user from preferences: $e');
      _logger.error('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    _logger.debug('Attempting login for email: $email');
    state = state.copyWith(status: AuthStatus.authenticating);
    
    try {
      final dio = _ref.read(dioProvider);
      final authService = _ref.read(authServiceProvider);
      _logger.debug('Making login API request');
      
      final response = await authService.login(email, password);
      
      if (response['success'] == true) {
        _logger.info('Login successful for: $email');
        
        // Refresh auth status to load user details
        checkAuth();
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e, stackTrace) {
      _logger.error('Login error: $e');
      _logger.error('Stack trace: $stackTrace');
      
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Login failed: ${e.toString()}',
      );
    }
  }

  Future<void> register(String name, String email, String password, [DateTime? birthDate, String? gender]) async {
    _logger.debug('Attempting registration for email: $email');
    state = state.copyWith(status: AuthStatus.authenticating);

    try {
      final authService = _ref.read(authServiceProvider);
      
      String? formattedBirthDate;
      if (birthDate != null) {
        formattedBirthDate = birthDate.toIso8601String();
      }

      final response = await authService.register(
        name, 
        email, 
        password, 
        formattedBirthDate ?? '', 
        gender ?? 'other'
      );
      
      if (response['success'] == true) {
        _logger.info('Registration successful for: $email');
        
        // Refresh auth status to load user details
        checkAuth();
      } else {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } catch (e, stackTrace) {
      _logger.error('Registration error: $e');
      _logger.error('Stack trace: $stackTrace');
      
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Registration failed: ${e.toString()}',
      );
    }
  }

  Future<void> checkAuth() async {
    _logger.debug('Checking authentication status');
    try {
      final user = await _getCurrentUserFromPrefs();
      if (user != null) {
        _logger.info('User authenticated: ${user.id}');
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
        );
      } else {
        _logger.warn('User not authenticated');
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          errorMessage: null,
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Error checking auth: $e');
      _logger.error('Stack trace: $stackTrace');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        errorMessage: 'Authentication check failed: ${e.toString()}',
      );
    }
  }

  Future<void> logout() async {
    _logger.debug('Logging out user');
    try {
      final authService = _ref.read(authServiceProvider);
      await authService.logout();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        errorMessage: null,
      );
      _logger.info('User logged out successfully');
    } catch (e, stackTrace) {
      _logger.error('Error during logout: $e');
      _logger.error('Stack trace: $stackTrace');
      // Still set state to unauthenticated even if logout fails
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        errorMessage: 'Logout error: ${e.toString()}',
      );
    }
  }
}

// Main provider for auth state
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

// --- Derived Providers ---

// Provider to expose just the authentication status
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authStateProvider).status;
});

// Provider to expose just the current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});

// Provider to check if the user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).status == AuthStatus.authenticated;
});

// Provider to check if the user is in the process of authenticating
final isAuthenticatingProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).status == AuthStatus.authenticating;
});

// Provider to expose auth error message
final authErrorMessageProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).errorMessage;
});

// NOTE: We removed the duplicate sharedPreferencesProvider definition here
// It is now only defined in providers.dart 