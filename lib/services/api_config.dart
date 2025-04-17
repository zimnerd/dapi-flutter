// Legacy API config file
// We're keeping the original ApiConfig class to avoid breaking changes
// but use the new constants from the central config file
import '../config/api_config.dart' as newConfig;

class ApiConfig {
  // API URLs
  static const String mockApiBaseUrl = newConfig.mockApiBaseUrl;
  static const String prodApiBaseUrl = newConfig.prodApiBaseUrl;
  static const bool useMockServer = true; // Set to true to use the mock server

  static String get apiBaseUrl => useMockServer ? mockApiBaseUrl : prodApiBaseUrl;
  
  // For WebSocket
  static const String mockSocketUrl = 'ws://localhost:3001';
  static const String prodSocketUrl = 'wss://dapi.pulsetek.co.za:3001';
  
  static String get socketUrl => useMockServer ? mockSocketUrl : prodSocketUrl;
  
  // Test account credentials
  static const String testEmail = 'testuser123@example.com';
  static const String testPassword = 'Password123!';
}