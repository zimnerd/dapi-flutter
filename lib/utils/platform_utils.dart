import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'logger.dart';

// Create a wrapper class for CroppedFile so we don't need to import image_cropper on Android
class SimpleCroppedFile {
  final String path;
  SimpleCroppedFile(this.path);
}

class PlatformUtils {
  // Check if we're on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  // Check if we're on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  // Check if we're on web
  static bool get isWeb => kIsWeb;

  // Safe image cropper that bypasses actual cropping on Android
  static Future<SimpleCroppedFile?> cropImage(XFile? pickedFile) async {
    if (pickedFile == null) return null;

    // All platforms: just return the original file
    // This is a temporary solution until image_cropper is fixed
    logger.error('Image cropping skipped - returning original file');
    return SimpleCroppedFile(pickedFile.path);
  }
}
