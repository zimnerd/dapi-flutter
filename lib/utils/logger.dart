import 'package:flutter/foundation.dart';

/// A utility class that provides consistent logging throughout the app.
///
/// This logger uses a structured format to make logs more readable and filterable:
/// ⟹ [ServiceName] Message
///
/// It provides specialized methods for different features and log levels
/// while also handling debug vs release mode appropriately.
class Logger {
  final String tag;

  // Singleton instance for global access
  static final Logger _instance = Logger._internal('App');
  static Logger get instance => _instance;

  // Constructor that allows tag specification for backward compatibility
  Logger([this.tag = 'App']);

  // Internal constructor for singleton
  Logger._internal(this.tag);

  /// Generic info log
  void log(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag] $message');
    }
  }

  /// Info level logging
  void info(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag][INFO] $message');
    }
  }

  /// Debug level logging
  void debug(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag][DEBUG] $message');
    }
  }

  /// Warning alias for compatibility
  void warn(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag][WARN] $message');
    }
  }

  /// Warning method
  void warning(String message) {
    warn(message);
  }

  /// Error logs with more visibility
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('⟹ [$tag][ERROR] $message');
    if (error != null) {
      debugPrint('⟹ [$tag][ERROR] Details: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('⟹ [$tag][ERROR] Stack: $stackTrace');
    }
  }

  /// Log HTTP/Dio related events
  void dio(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag][DIO] $message');
    }
  }

  /// Log authentication related events
  void auth(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag][AUTH] $message');
    }
  }

  /// Log chat/messaging related events
  void chat(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag][CHAT] $message');
    }
  }

  /// Log profile related events
  void profile(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag][PROFILE] $message');
    }
  }

  /// Log navigation/route related events
  void navigation(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag][NAV] $message');
    }
  }

  /// Log network related events
  void network(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag][NETWORK] $message');
    }
  }

  /// Log storage related events
  void storage(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag][STORAGE] $message');
    }
  }

  /// Log UI related events
  void ui(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag][UI] $message');
    }
  }

  /// Log analytics related events
  void analytics(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag][ANALYTICS] $message');
    }
  }

  /// Log verification related events
  void verification(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag][VERIFICATION] $message');
    }
  }

  /// Log match related events
  void match(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag][MATCH] $message');
    }
  }

  /// Log settings related events
  void settings(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag][SETTINGS] $message');
    }
  }

  /// Log lifecycle related events
  void lifecycle(String message) {
    if (kDebugMode) {
      debugPrint('⟹ [$tag][LIFECYCLE] $message');
    }
  }
}

// Global logger instance
final logger = Logger();

// A simple logger utility that provides structured logging
// Format: ⟹ [Service] Message

void log(String service, String message) {
  debugPrint('⟹ [$service] $message');
}

void logError(String service, String message,
    [dynamic error, StackTrace? stackTrace]) {
  debugPrint('⟹ [$service] ERROR: $message');
  if (error != null) {
    debugPrint('⟹ [$service] Error details: $error');
  }
  if (stackTrace != null) {
    debugPrint('⟹ [$service] Stack trace:\n$stackTrace');
  }
}

void logWarning(String service, String message) {
  debugPrint('⟹ [$service] WARNING: $message');
}

void logInfo(String service, String message) {
  debugPrint('⟹ [$service] INFO: $message');
}

void logDebug(String service, String message) {
  assert(() {
    debugPrint('⟹ [$service] DEBUG: $message');
    return true;
  }());
}
