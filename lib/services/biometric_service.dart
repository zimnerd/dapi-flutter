import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String BIOMETRIC_ENABLED_KEY = 'biometric_enabled';
  static const String BIOMETRIC_USER_EMAIL_KEY = 'biometric_user_email';

  // Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      // Check if device can use biometrics
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      
      return canAuthenticate;
    } on PlatformException catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Error authenticating with biometrics: $e');
      return false;
    }
  }

  // Enable biometric authentication for a user
  Future<bool> enableBiometrics(String userEmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(BIOMETRIC_ENABLED_KEY, true);
      await prefs.setString(BIOMETRIC_USER_EMAIL_KEY, userEmail);
      return true;
    } catch (e) {
      print('Error enabling biometrics: $e');
      return false;
    }
  }

  // Disable biometric authentication
  Future<bool> disableBiometrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(BIOMETRIC_ENABLED_KEY, false);
      await prefs.remove(BIOMETRIC_USER_EMAIL_KEY);
      return true;
    } catch (e) {
      print('Error disabling biometrics: $e');
      return false;
    }
  }

  // Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(BIOMETRIC_ENABLED_KEY) ?? false;
    } catch (e) {
      print('Error checking if biometric is enabled: $e');
      return false;
    }
  }

  // Get saved user email for biometric authentication
  Future<String?> getBiometricUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(BIOMETRIC_USER_EMAIL_KEY);
    } catch (e) {
      print('Error getting biometric user email: $e');
      return null;
    }
  }
} 