import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web implementation of secure storage using localStorage with a prefix
class SecureStorage {
  static const String _storagePrefix = 'dating_app_secure_';

  /// Write data to localStorage with the secure prefix
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      delete(key: key);
      return;
    }
    
    final secureKey = '$_storagePrefix$key';
    html.window.localStorage[secureKey] = value;
    debugPrint('⟹ [SecureStorage Web] Stored key: $key');
  }

  /// Read data from localStorage with the secure prefix
  Future<String?> read({required String key}) async {
    final secureKey = '$_storagePrefix$key';
    final value = html.window.localStorage[secureKey];
    debugPrint('⟹ [SecureStorage Web] Read key: $key');
    return value;
  }

  /// Delete data from localStorage
  Future<void> delete({required String key}) async {
    final secureKey = '$_storagePrefix$key';
    html.window.localStorage.remove(secureKey);
    debugPrint('⟹ [SecureStorage Web] Deleted key: $key');
  }

  /// Delete all data with the secure prefix
  Future<void> deleteAll() async {
    final keysToRemove = <String>[];
    
    html.window.localStorage.forEach((key, value) {
      if (key.startsWith(_storagePrefix)) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      html.window.localStorage.remove(key);
    }
    
    debugPrint('⟹ [SecureStorage Web] Deleted all keys');
  }
}

/// Provider for web implementation of secure storage
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
}); 