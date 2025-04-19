import 'dart:io' as io;
import 'package:flutter/foundation.dart';

class PlatformChecker {
  /// Returns true if running on web platform
  static bool get isWeb => kIsWeb;
  
  /// Returns true if running on Android
  static bool get isAndroid => !kIsWeb && io.Platform.isAndroid;
  
  /// Returns true if running on iOS
  static bool get isIOS => !kIsWeb && io.Platform.isIOS;
  
  /// Returns true if running on macOS
  static bool get isMacOS => !kIsWeb && io.Platform.isMacOS;
  
  /// Returns true if running on Windows
  static bool get isWindows => !kIsWeb && io.Platform.isWindows;
  
  /// Returns true if running on Linux
  static bool get isLinux => !kIsWeb && io.Platform.isLinux;
  
  /// Returns true if running on a mobile platform (Android or iOS)
  static bool get isMobile => isAndroid || isIOS;
  
  /// Returns true if running on a desktop platform (Windows, macOS, or Linux)
  static bool get isDesktop => isMacOS || isWindows || isLinux;
  
  /// Returns the current platform name
  static String get platformName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isMacOS) return 'macOS';
    if (isWindows) return 'Windows';
    if (isLinux) return 'Linux';
    return 'Unknown';
  }
} 