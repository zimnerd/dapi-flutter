import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String biometricUserEmailKey = 'biometric_user_email';

  // Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      // Check if device can use biometrics
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      return canAuthenticate;
    } on PlatformException catch (e) {
      logger.error('Error checking biometric availability: $e');
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      logger.error('Error getting available biometrics: $e');
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
      logger.error('Error authenticating with biometrics: $e');
      return false;
    }
  }

  // Enable biometric authentication for a user
  Future<bool> enableBiometrics(String userEmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(biometricEnabledKey, true);
      await prefs.setString(biometricUserEmailKey, userEmail);
      return true;
    } catch (e) {
      logger.error('Error enabling biometrics: $e');
      return false;
    }
  }

  // Disable biometric authentication
  Future<bool> disableBiometrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(biometricEnabledKey, false);
      await prefs.remove(biometricUserEmailKey);
      return true;
    } catch (e) {
      logger.error('Error disabling biometrics: $e');
      return false;
    }
  }

  // Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(biometricEnabledKey) ?? false;
    } catch (e) {
      logger.error('Error checking if biometric is enabled: $e');
      return false;
    }
  }

  // Get saved user email for biometric authentication
  Future<String?> getBiometricUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(biometricUserEmailKey);
    } catch (e) {
      logger.error('Error getting biometric user email: $e');
      return null;
    }
  }
}
