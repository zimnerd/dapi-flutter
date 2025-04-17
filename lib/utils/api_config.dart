import 'constants.dart';

class ApiConfig {
  // Use the correct URL from constants
  static final String apiBaseUrl = Constants.API_BASE_URL;
  
  // Create URL for a specific endpoint
  static String endpoint(String path) {
    return '$apiBaseUrl/$path';
  }
} 