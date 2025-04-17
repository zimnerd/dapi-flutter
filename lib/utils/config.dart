import '../services/api_config.dart';

class Config {
  // API endpoints
  static String get apiUrl => ApiConfig.apiBaseUrl;
  static String get socketUrl => ApiConfig.socketUrl;
  static String get API_BASE_URL => ApiConfig.apiBaseUrl;
  
  // External API keys - Replace these with your actual keys in a real app
  static const String giphyApiKey = 'pLURtkhVrUXr3KG25Gy5IvzziV5OrZGa'; // Public GIPHY beta key (use real key in prod)
  
  // App constants
  static const String appName = 'Dating App';
  static const String appVersion = '1.0.0';
  
  // Storage keys
  static const String tokenKey = 'token';
  static const String userKey = 'user';
  
  // Feature flags
  static const bool enablePushNotifications = true;
  static const bool enableOfflineMode = true;
} 