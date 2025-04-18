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
  
  // Create a custom ProviderContainer to override the SharedPreferences provider
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  
  // Run the app within an UncontrolledProviderScope using our custom container
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
  appLogger.info('App successfully initialized and running');
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.debug('Building MyApp widget');
    
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: _buildHome(ref, authState),
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
      onGenerateRoute: (settings) {
        if (settings.name == '/conversation') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ConversationScreen(
              conversation: args['conversation'],
            ),
          );
        }
        if (settings.name == '/reset-password-confirmation') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => ResetPasswordConfirmationScreen(
              email: args?['email'],
              token: args?['token'],
            ),
          );
        }
        return null;
      },
    );
  }

  Widget _buildHome(WidgetRef ref, AuthState authState) {
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