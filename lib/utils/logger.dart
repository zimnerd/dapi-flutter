import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// A utility class that provides consistent logging throughout the app.
/// 
/// This logger uses a structured format to make logs more readable and filterable:
/// ⟹ [ServiceName] Message
///
/// It provides specialized methods for different features and log levels
/// while also handling debug vs release mode appropriately.
class Logger {
  final String _tag;
  
  // Singleton instance for global access
  static final Logger _instance = Logger._internal('App');
  static Logger get instance => _instance;
  
  // Constructor that allows tag specification for backward compatibility
  Logger(this._tag);
  
  // Internal constructor for singleton
  Logger._internal(this._tag);

  /// Generic info log
  void log(String message) {
    _log('INFO', message);
  }

  /// Info level logging
  void info(String message) {
    _log('INFO', message);
  }
  
  /// Debug level logging
  void debug(String message) {
    _log('DEBUG', message);
  }
  
  /// Warning alias for compatibility
  void warn(String message) {
    _log('WARN', message);
  }
  
  /// Warning method
  void warning(String message) {
    warn(message);
  }

  /// Error logs with more visibility
  void error(String message) {
    _log('ERROR', message);
  }

  /// Log HTTP/Dio related events
  void dio(String message) {
    _log('DIO', message);
  }

  /// Log authentication related events
  void auth(String message) {
    _log('AUTH', message);
  }

  /// Log chat/messaging related events
  void chat(String message) {
    _log('CHAT', message);
  }

  /// Log profile related events
  void profile(String message) {
    _log('PROFILE', message);
  }

  /// Log navigation/route related events
  void navigation(String message) {
    _log('NAV', message);
  }
  
  /// Log network related events
  void network(String message) {
    _log('NETWORK', message);
  }
  
  /// Log storage related events
  void storage(String message) {
    _log('STORAGE', message);
  }
  
  /// Log UI related events
  void ui(String message) {
    _log('UI', message);
  }
  
  /// Log analytics related events
  void analytics(String message) {
    _log('ANALYTICS', message);
  }
  
  /// Log verification related events
  void verification(String message) {
    _log('VERIFICATION', message);
  }
  
  /// Log match related events
  void match(String message) {
    _log('MATCH', message);
  }
  
  /// Log settings related events
  void settings(String message) {
    _log('SETTINGS', message);
  }
  
  /// Log lifecycle related events
  void lifecycle(String message) {
    _log('LIFECYCLE', message);
  }

  /// Internal logging implementation
  void _log(String level, String message) {
    final logMessage = '⟹ [$_tag] $message';
    
    if (kDebugMode) {
      developer.log(logMessage, name: level);
      print(logMessage);
    }
  }
}

// Global logger instance
final logger = Logger('App');

// A simple logger utility that provides structured logging
// Format: ⟹ [Service] Message

void log(String service, String message) {
  print('⟹ [$service] $message');
}

void logError(String service, String message, [dynamic error, StackTrace? stackTrace]) {
  print('⟹ [$service] ERROR: $message');
  if (error != null) {
    print('⟹ [$service] Error details: $error');
  }
  if (stackTrace != null) {
    print('⟹ [$service] Stack trace:\n$stackTrace');
  }
}

void logWarning(String service, String message) {
  print('⟹ [$service] WARNING: $message');
}

void logInfo(String service, String message) {
  print('⟹ [$service] INFO: $message');
}

void logDebug(String service, String message) {
  assert(() {
    print('⟹ [$service] DEBUG: $message');
    return true;
  }());
} 