import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart'; // Assuming User model exists
import '../models/login_response.dart'; // Import the new login response model
import 'package:shared_preferences/shared_preferences.dart';
import '../services/dio_provider.dart'; // Import the newly created dio_provider

// Enum for Authentication Status
enum AuthStatus { unknown, authenticated, unauthenticated, authenticating }

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

  AuthNotifier(this._ref) : super(const AuthState()) {
    _checkInitialAuthStatus();
  }

  Future<void> _checkInitialAuthStatus() async {
    try {
      final storage = _ref.read(secureStorageProvider);
      final token = await storage.read(key: 'auth_token');
      
      if (token != null) {
        // Optionally fetch user details here if needed upon app start
        final user = await _getCurrentUserFromPrefs();
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      print("Error checking initial auth status: $e");
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<User?> _getCurrentUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final userEmail = prefs.getString('userEmail');
    final userName = prefs.getString('userName');
    final profileId = prefs.getString('profileId');

    if (userId != null && userEmail != null && userName != null) {
      return User(
        id: userId,
        email: userEmail,
        name: userName,
        profileId: profileId,
      );
    }
    return null;
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating);
    
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      print('Login response: ${response.data}');
      
      if (response.statusCode == 200 && response.data != null) {
        try {
          // Safely parse the response
          final loginResponse = LoginResponse.fromJson(response.data);
          
          // Store tokens in secure storage
          final storage = _ref.read(secureStorageProvider);
          await storage.write(key: 'auth_token', value: loginResponse.data.token);
          await storage.write(key: 'refresh_token', value: loginResponse.data.refreshToken);
          
          // Store user data in SharedPreferences for quick access
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', loginResponse.data.user.id);
          await prefs.setString('userEmail', loginResponse.data.user.email);
          await prefs.setString('userName', loginResponse.data.user.name);
          await prefs.setString('profileId', loginResponse.data.profile.id);
          
          // Create User object from response data
          final user = User(
            id: loginResponse.data.user.id,
            email: loginResponse.data.user.email,
            name: loginResponse.data.user.name,
            profileId: loginResponse.data.profile.id,
          );
          
          // Update state with authenticated user
          state = AuthState(
            status: AuthStatus.authenticated,
            user: user,
            errorMessage: null,
          );
          
          print('User logged in successfully: ${state.user?.name}');
        } catch (parseError) {
          print('Error parsing login response: $parseError');
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            errorMessage: 'Error parsing login response: ${parseError.toString()}',
          );
        }
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Login error: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Login failed: ${e.toString()}',
      );
    }
  }

  Future<void> register(String name, String email, String password, [DateTime? birthDate, String? gender]) async {
    state = state.copyWith(status: AuthStatus.authenticating);

    try {
      final dio = _ref.read(dioProvider);
      final Map<String, dynamic> data = {
        'name': name,
        'email': email,
        'password': password,
      };
      
      // Add optional parameters if provided
      if (birthDate != null) {
        data['birth_date'] = birthDate.toIso8601String();
      }
      
      if (gender != null) {
        data['gender'] = gender;
      }
      
      final response = await dio.post('/auth/register', data: data);

      if (response.statusCode == 201) {
        // Extract token and user data
        final token = response.data['token'];
        final userData = response.data['user'];
        
        // Store token in secure storage
        final storage = _ref.read(secureStorageProvider);
        await storage.write(key: 'auth_token', value: token);
        
        // Update state with user data
        state = AuthState(
          status: AuthStatus.authenticated,
          user: User.fromJson(userData),
          errorMessage: null,
        );
        
        print('User registered successfully: ${state.user?.name}');
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Registration error: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Registration failed: ${e.toString()}',
      );
    }
  }

  Future<void> checkAuth() async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.read(key: 'auth_token');

    if (token == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/auth/me');
      
      if (response.statusCode == 200) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: User.fromJson(response.data),
          errorMessage: null,
        );
      } else {
        // Token might be invalid/expired
        await storage.delete(key: 'auth_token');
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      print('Error checking auth: $e');
      // On error, consider user as unauthenticated
      await storage.delete(key: 'auth_token');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Authentication check failed',
      );
    }
  }

  Future<void> logout() async {
    final storage = _ref.read(secureStorageProvider);
    await storage.delete(key: 'auth_token');
    
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      user: null,
      errorMessage: null,
    );
  }
}

// Provider for AuthNotifier
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

// --- Derived Providers ---

// Provider to expose just the authentication status
final authStatusProvider = Provider<AuthStatus>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.status;
});

// Provider to expose the current User object (or null)
final currentUserProvider = Provider<User?>((ref) {
   final authState = ref.watch(authStateProvider);
   return authState.user;
});

// Provider to expose the current user ID (or null)
final userIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id;
});

// Provider to expose the current user email (or null)
final userEmailProvider = Provider<String?>((ref) {
   final user = ref.watch(currentUserProvider);
   return user?.email;
});

// Provider to expose the current user name (or a default)
final userNameProvider = Provider<String>((ref) {
   final user = ref.watch(currentUserProvider);
   return user?.name ?? 'User';
}); 