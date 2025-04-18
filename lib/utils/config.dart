import '../config/app_config.dart';

// Re-export all configuration from app_config.dart
export '../config/app_config.dart';

// Note: This file is kept for backward compatibility.
// New code should import AppConfig directly from '../config/app_config.dart'

// Config class for backward compatibility
class Config {
  static String get apiBaseUrl => AppConfig.apiBaseUrl;
  static String get socketUrl => AppConfig.socketUrl;
  static String get giphyApiKey => AppConfig.giphyApiKey;
} 