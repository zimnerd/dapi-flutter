import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:collection';
import 'logger.dart';

/// A mock implementation of SharedPreferences that works in-memory
/// This is used when the actual SharedPreferences initialization fails
class MockSharedPreferences implements SharedPreferences {
  final Map<String, Object> _data = HashMap<String, Object>();
  final _logger = Logger('MockPrefs');

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  Set<String> getKeys() {
    _logger.debug('getKeys()');
    return Set<String>.from(_data.keys);
  }

  @override
  Object? get(String key) {
    _logger.debug('get($key)');
    return _data[key];
  }

  @override
  bool? getBool(String key) {
    _logger.debug('getBool($key)');
    return _data[key] as bool?;
  }

  @override
  int? getInt(String key) {
    _logger.debug('getInt($key)');
    return _data[key] as int?;
  }

  @override
  double? getDouble(String key) {
    _logger.debug('getDouble($key)');
    return _data[key] as double?;
  }

  @override
  String? getString(String key) {
    _logger.debug('getString($key)');
    return _data[key] as String?;
  }

  @override
  List<String>? getStringList(String key) {
    _logger.debug('getStringList($key)');
    return _data[key] as List<String>?;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _logger.debug('setBool($key, $value)');
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _logger.debug('setInt($key, $value)');
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _logger.debug('setDouble($key, $value)');
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _logger.debug('setString($key, $value)');
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _logger.debug('setStringList($key, $value)');
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _logger.debug('remove($key)');
    _data.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _logger.debug('clear()');
    _data.clear();
    return true;
  }

  @override
  bool containsKey(String key) {
    _logger.debug('containsKey($key)');
    return _data.containsKey(key);
  }

  @override
  Future<void> reload() async {
    _logger.debug('reload() - no-op in mock implementation');
    // No-op for mock
  }

  @override
  Future<bool> commit() async {
    _logger.debug('commit() - no-op in mock implementation');
    return true;
  }

  bool get isMock => true;

  bool get isFake => true;
}
