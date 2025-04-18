import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/auth_service.dart';
import 'services/api_client.dart';
import 'models/user.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models/user.dart';
import 'providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/logger.dart';

/// A simple widget to test authentication flow
class AuthTest extends ConsumerStatefulWidget {
  const AuthTest({super.key});

  @override
  ConsumerState<AuthTest> createState() => _AuthTestState();
}

class _AuthTestState extends ConsumerState<AuthTest> {
  String _status = 'Not logged in';
  String _token = 'No token';
  User? _user;
  bool _isLoading = false;
  
  final _emailController = TextEditingController(text: 'eddienyagano@gmail.com');
  final _passwordController = TextEditingController(text: 'password123');

  @override
  void initState() {
    super.initState();
    _checkExistingToken();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingToken() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking for existing token...';
    });
    
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    
    setState(() {
      if (token != null) {
        _token = token.length > 15 ? '${token.substring(0, 15)}...' : token;
        _status = 'Found existing token';
      } else {
        _token = 'No token found';
        _status = 'No existing token';
      }
      _isLoading = false;
    });
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _status = 'Logging in...';
    });
    
    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.login(
        _emailController.text,
        _passwordController.text,
      );
      
      // Check token storage
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      
      setState(() {
        _status = 'Login successful';
        _token = token != null ? '${token.substring(0, 15)}...' : 'No token found after login';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Login failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUser() async {
    setState(() {
      _isLoading = true;
      _status = 'Fetching user data...';
    });
    
    try {
      // Get token from secure storage
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      setState(() {
        _token = token ?? 'No token';
      });
      
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required: No token available');
      }
      
      // Use Dio instance from provider
      final dio = ref.read(dioProvider);
      
      // Add explicit headers for this request
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      final response = await dio.get('/api/users/me', options: options);
      
      if (response.statusCode == 200 && response.data['user'] != null) {
        final user = User.fromJson(response.data['user']);
        
        setState(() {
          _user = user;
          _status = 'User fetched successfully';
          _isLoading = false;
        });
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to get user data');
      }
    } catch (e) {
      setState(() {
        _status = 'Failed to fetch user: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearTokens() async {
    setState(() {
      _isLoading = true;
      _status = 'Clearing tokens...';
    });
    
    final storage = const FlutterSecureStorage();
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'refresh_token');
    
    setState(() {
      _token = 'No token (cleared)';
      _user = null;
      _status = 'Tokens cleared';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: $_status', 
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Token: $_token'),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Login Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // API Test buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _fetchUser,
                    child: const Text('Fetch User (/api/users/me)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _clearTokens,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear Tokens'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // User Data Display
            if (_user != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('User Data:', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('ID: ${_user!.id}'),
                      Text('Email: ${_user!.email}'),
                      Text('Name: ${_user!.name}'),
                      if (_user!.profileId != null) Text('Profile ID: ${_user!.profileId}'),
                      if (_user!.profilePictures != null) 
                        Text('Profile Pictures: ${_user!.profilePictures!.length}'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Test script to validate AuthService functionality
/// Run with: flutter run -d chrome lib/test_auth.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize test app
  runApp(TestAuthApp(prefs: prefs));
}

class TestAuthApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const TestAuthApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Service Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: TestAuthScreen(prefs: prefs),
    );
  }
}

class TestAuthScreen extends StatefulWidget {
  final SharedPreferences prefs;
  
  const TestAuthScreen({super.key, required this.prefs});

  @override
  State<TestAuthScreen> createState() => _TestAuthScreenState();
}

class _TestAuthScreenState extends State<TestAuthScreen> {
  final TextEditingController _emailController = TextEditingController(text: 'eddienyagano@gmail.com');
  final TextEditingController _passwordController = TextEditingController(text: 'password123');
  final Logger _logger = Logger('TestAuth');
  late AuthService _authService;
  final List<String> _logs = [];
  bool _isLoggedIn = false;
  String? _token;
  String? _refreshToken;
  
  @override
  void initState() {
    super.initState();
    _setupAuthService();
    _checkInitialAuth();
  }
  
  void _setupAuthService() {
    // Create Dio instance with default configuration
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    
    // Setup Auth Service
    _authService = AuthService(dio, const FlutterSecureStorage(), widget.prefs);
    
    _log("Auth Service initialized");
  }
  
  Future<void> _checkInitialAuth() async {
    _log("Checking initial auth state...");
    final isLoggedIn = await _authService.isLoggedIn();
    final token = await _authService.getAccessToken();
    
    setState(() {
      _isLoggedIn = isLoggedIn;
      _token = token;
      _log("Initial auth state: ${isLoggedIn ? 'Logged in' : 'Not logged in'}");
      if (token != null) {
        _log("Existing token: ${token.substring(0, min(token.length, 15))}...");
      }
    });
  }
  
  Future<void> _login() async {
    _log("Attempting login with email: ${_emailController.text}");
    
    try {
      final response = await _authService.login(
        _emailController.text, 
        _passwordController.text
      );
      
      if (response['success'] == true) {
        _log("Login successful!");
        final token = await _authService.getAccessToken();
        final refreshToken = await _authService.getRefreshToken();
        
        setState(() {
          _isLoggedIn = true;
          _token = token;
          _refreshToken = refreshToken;
          if (token != null) {
            _log("Token: ${token.substring(0, min(token.length, 15))}...");
          }
          if (refreshToken != null) {
            _log("Refresh token: ${refreshToken.substring(0, min(refreshToken.length, 15))}...");
          }
        });
      } else {
        _log("Login failed: ${response['message']}");
      }
    } catch (e) {
      _log("Login error: $e");
    }
  }
  
  Future<void> _refreshTokenAction() async {
    _log("Attempting to refresh token...");
    
    try {
      final success = await _authService.refreshToken();
      
      if (success) {
        _log("Token refresh successful!");
        final token = await _authService.getAccessToken();
        final refreshToken = await _authService.getRefreshToken();
        
        setState(() {
          _token = token;
          _refreshToken = refreshToken;
          if (token != null) {
            _log("New token: ${token.substring(0, min(token.length, 15))}...");
          }
          if (refreshToken != null) {
            _log("New refresh token: ${refreshToken.substring(0, min(refreshToken.length, 15))}...");
          }
        });
      } else {
        _log("Token refresh failed");
      }
    } catch (e) {
      _log("Token refresh error: $e");
    }
  }
  
  Future<void> _logout() async {
    _log("Logging out...");
    
    try {
      await _authService.logout();
      setState(() {
        _isLoggedIn = false;
        _token = null;
        _refreshToken = null;
        _log("Logged out successfully");
      });
    } catch (e) {
      _log("Logout error: $e");
    }
  }
  
  void _log(String message) {
    _logger.info(message);
    setState(() {
      _logs.add("[${DateTime.now().toString().split('.').first}] $message");
    });
  }
  
  int min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Service Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Login status
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: _isLoggedIn ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    _isLoggedIn ? Icons.check_circle : Icons.error_outline,
                    color: _isLoggedIn ? Colors.green[800] : Colors.red[800],
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    _isLoggedIn ? 'Logged In' : 'Not Logged In',
                    style: TextStyle(
                      color: _isLoggedIn ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16.0),
            
            // Login form
            if (!_isLoggedIn) ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Login'),
              ),
            ],
            
            // Logged in actions
            if (_isLoggedIn) ...[
              ElevatedButton(
                onPressed: _refreshTokenAction,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Refresh Token'),
              ),
              const SizedBox(height: 8.0),
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ],
            
            const SizedBox(height: 16.0),
            
            // Log viewer
            const Text(
              'Logs:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _logs[_logs.length - 1 - index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.0,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 