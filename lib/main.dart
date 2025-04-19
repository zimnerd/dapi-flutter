import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_creation_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/conversation_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/reset_password_confirmation_screen.dart';
import 'utils/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'utils/theme.dart';
import 'providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config/app_config.dart';
import 'utils/logger.dart';
import 'utils/mock_shared_preferences.dart';
import 'providers/providers.dart'; // Import the centralized providers file
import 'config/theme_config.dart';
import 'services/notification_service.dart';
import 'utils/connectivity/network_manager.dart';
import 'providers/notification_provider.dart';
import 'package:dating_app/config/routes.dart';
import 'package:dating_app/screens/splash_screen.dart';
import 'package:dating_app/providers/navigator_key_provider.dart';

final appLogger = Logger('App');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appLogger.info('Application starting...');
  
  // Add retry logic for SharedPreferences initialization
  SharedPreferences? prefs;
  int maxRetries = 3;
  int retryCount = 0;
  
  while (prefs == null && retryCount < maxRetries) {
    try {
      prefs = await SharedPreferences.getInstance();
      appLogger.debug('⟹ [Main] SharedPreferences initialized successfully');
    } catch (e) {
      retryCount++;
      appLogger.warn('⟹ [Main] Error initializing SharedPreferences: $e (Attempt $retryCount/$maxRetries)');
      await Future.delayed(Duration(milliseconds: 500)); // Wait before retry
    }
  }
  
  if (prefs == null) {
    appLogger.warn('⟹ [Main] Failed to initialize SharedPreferences after $maxRetries attempts, using MockSharedPreferences as fallback');
    // Use the mock implementation as a fallback
    prefs = MockSharedPreferences();
  }
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Create a custom ProviderContainer to override the SharedPreferences provider
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationServiceProvider.overrideWithValue(notificationService),
    ],
  );
  
  // Run the app within an UncontrolledProviderScope using our custom container
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(),
    ),
  );
  appLogger.info('App successfully initialized and running');
}

/// Main app widget
class App extends ConsumerStatefulWidget {
  const App({Key? key}) : super(key: key);
  
  @override
  _AppState createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // Initialize services
    final prefs = ref.read(sharedPreferencesProvider);
    final secureStorage = ref.read(secureStorageProvider);
    
    // Initialize notifications
    // This will set up listeners for socket events
    ref.read(notificationManagerProvider);
    
    // Check auth state
    final authService = ref.read(authServiceProvider);
    if (await authService.isAuthenticated()) {
      // If user is authenticated, connect to socket
      ref.read(socketServiceProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    appLogger.debug('Building App widget');
    
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Initialize network connectivity monitor
    ref.watch(networkStatusProvider);

    // Auto-connect socket when user is authenticated
    // This activates the side effect provider to manage socket connections
    ref.watch(socketConnectionProvider);
    
    // Get the global navigator key from the provider
    final navigatorKey = ref.watch(navigatorKeyProvider);

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      navigatorKey: navigatorKey,
      home: _buildHome(authState),
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/profile-creation': (context) => ProfileCreationScreen(),
        '/messages': (context) => MessagesScreen(),
        '/discover': (context) => DiscoverScreen(),
        '/matches': (context) => MatchesScreen(),
        '/settings': (context) => SettingsScreen(),
        '/reset-password-confirmation': (context) => ResetPasswordConfirmationScreen(),
      },
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }

  Widget _buildHome(AuthState authState) {
    appLogger.debug('Building home screen based on auth state: ${authState.status}');
    
    switch (authState.status) {
      case AuthStatus.authenticated:
        appLogger.info('User is authenticated, showing HomeScreen');
        return HomeScreen();
      case AuthStatus.authenticating:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      case AuthStatus.unauthenticated:
        appLogger.info('User is unauthenticated, showing WelcomeScreen');
        return WelcomeScreen();
      case AuthStatus.unknown:
      default:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
    }
  }
}