import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web implementation of SharedPreferences using localStorage with a prefix
class SharedPreferencesService {
  static const String _storagePrefix = 'dating_app_prefs_';

  /// Set string value
  Future<bool> setString(String key, String value) async {
    final prefKey = '$_storagePrefix$key';
    html.window.localStorage[prefKey] = value;
    debugPrint('⟹ [SharedPrefs Web] Set string: $key');
    return true;
  }

  /// Get string value
  String? getString(String key) {
    final prefKey = '$_storagePrefix$key';
    return html.window.localStorage[prefKey];
  }

  /// Set bool value
  Future<bool> setBool(String key, bool value) async {
    final prefKey = '$_storagePrefix$key';
    html.window.localStorage[prefKey] = value.toString();
    debugPrint('⟹ [SharedPrefs Web] Set bool: $key');
    return true;
  }

  /// Get bool value
  bool? getBool(String key) {
    final prefKey = '$_storagePrefix$key';
    final value = html.window.localStorage[prefKey];
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  /// Set int value
  Future<bool> setInt(String key, int value) async {
    final prefKey = '$_storagePrefix$key';
    html.window.localStorage[prefKey] = value.toString();
    debugPrint('⟹ [SharedPrefs Web] Set int: $key');
    return true;
  }

  /// Get int value
  int? getInt(String key) {
    final prefKey = '$_storagePrefix$key';
    final value = html.window.localStorage[prefKey];
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// Set double value
  Future<bool> setDouble(String key, double value) async {
    final prefKey = '$_storagePrefix$key';
    html.window.localStorage[prefKey] = value.toString();
    debugPrint('⟹ [SharedPrefs Web] Set double: $key');
    return true;
  }

  /// Get double value
  double? getDouble(String key) {
    final prefKey = '$_storagePrefix$key';
    final value = html.window.localStorage[prefKey];
    if (value == null) return null;
    return double.tryParse(value);
  }

  /// Set string list value
  Future<bool> setStringList(String key, List<String> value) async {
    final prefKey = '$_storagePrefix$key';
    html.window.localStorage[prefKey] = value.join('|||');
    debugPrint('⟹ [SharedPrefs Web] Set string list: $key');
    return true;
  }

  /// Get string list value
  List<String>? getStringList(String key) {
    final prefKey = '$_storagePrefix$key';
    final value = html.window.localStorage[prefKey];
    if (value == null) return null;
    return value.split('|||');
  }

  /// Remove value
  Future<bool> remove(String key) async {
    final prefKey = '$_storagePrefix$key';
    html.window.localStorage.remove(prefKey);
    debugPrint('⟹ [SharedPrefs Web] Removed: $key');
    return true;
  }

  /// Clear all preferences
  Future<bool> clear() async {
    final keysToRemove = <String>[];
    
    html.window.localStorage.forEach((key, value) {
      if (key.startsWith(_storagePrefix)) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      html.window.localStorage.remove(key);
    }
    
    debugPrint('⟹ [SharedPrefs Web] Cleared all preferences');
    return true;
  }

  /// Check if key exists
  bool containsKey(String key) {
    final prefKey = '$_storagePrefix$key';
    return html.window.localStorage.containsKey(prefKey);
  }
}

/// Provider for web implementation of shared preferences
final sharedPreferencesProvider = Provider<SharedPreferencesService>((ref) {
  return SharedPreferencesService();
}); 