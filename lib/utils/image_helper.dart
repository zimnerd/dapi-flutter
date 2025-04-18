import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../utils/logger.dart';

/// A utility class for handling images in the app
/// Provides methods for loading images with fallbacks
class ImageHelper {
  static const String _placeholderImagePath = 'assets/images/placeholder.jpg';
  static const String _maleDefaultImagePath = 'assets/images/default_male.png';
  static const String _femaleDefaultImagePath = 'assets/images/default_female.png';
  static const String _defaultImagePath = 'assets/images/default_profile.png';
  
  /// Cache to track which assets exist
  static final Map<String, bool> _assetExistsCache = {};
  
  /// Check if an asset exists in the app bundle
  static Future<bool> assetExists(String assetPath) async {
    if (_assetExistsCache.containsKey(assetPath)) {
      return _assetExistsCache[assetPath]!;
    }
    
    try {
      await rootBundle.load(assetPath);
      _assetExistsCache[assetPath] = true;
      return true;
    } catch (e) {
      logger.error('Asset not found: $assetPath');
      _assetExistsCache[assetPath] = false;
      return false;
    }
  }
  
  /// Get a network image with proper fallbacks
  static Widget getNetworkImageWithFallback({
    required String imageUrl,
    String? gender,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    Widget image = FutureBuilder<bool>(
      future: _verifyPlaceholderExists(),
      builder: (context, snapshot) {
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: Image.network(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoadingIndicator(width, height);
            },
            errorBuilder: (context, error, stackTrace) {
              logger.error('Error loading image: $error for URL: $imageUrl');
              return _getFallbackImage(gender, width, height, fit);
            },
          ),
        );
      }
    );
    
    return image;
  }
  
  /// Get a default image based on gender
  static Widget _getFallbackImage(
    String? gender, 
    double? width, 
    double? height, 
    BoxFit fit
  ) {
    String assetPath;
    
    if (gender?.toLowerCase() == 'male') {
      assetPath = _maleDefaultImagePath;
    } else if (gender?.toLowerCase() == 'female') {
      assetPath = _femaleDefaultImagePath;
    } else {
      assetPath = _defaultImagePath;
    }
    
    return FutureBuilder<bool>(
      future: assetExists(assetPath),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return Image.asset(
            assetPath,
            width: width,
            height: height,
            fit: fit,
          );
        } else {
          // If even the fallback doesn't exist, use a colored container
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Icon(
              Icons.person,
              size: (width ?? 100) * 0.5,
              color: Colors.grey[600],
            ),
          );
        }
      }
    );
  }
  
  /// Build a loading indicator
  static Widget _buildLoadingIndicator(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
        ),
      ),
    );
  }
  
  /// Verify that the placeholder image exists
  static Future<bool> _verifyPlaceholderExists() async {
    return await assetExists(_placeholderImagePath);
  }
} 