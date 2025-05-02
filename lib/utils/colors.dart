import 'package:flutter/material.dart';

/// App color palette for consistent theming across the application
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF4ECDC4); // Teal Blue
  static const Color primaryLight = Color(0xFF6FDFD8);
  static const Color primaryDark = Color(0xFF37B3AC);

  static const Color secondary = Color(0xFFFF6F61); // Coral Peach
  static const Color secondaryLight = Color(0xFFFF8F83);
  static const Color secondaryDark = Color(0xFFD55A4E);

  // Secondary Colors
  static const Color tertiary = Color(0xFFB388EB); // Lavender Purple
  static const Color tertiaryLight = Color(0xFFC8A7F0);
  static const Color tertiaryDark = Color(0xFF9A6AD3);

  static const Color notification = Color(0xFFFFE66D); // Soft Yellow

  // Neutral Colors (Light Theme)
  static const Color textPrimary = Color(0xFF333333); // Charcoal Gray
  static const Color textSecondary = Color(0xFF555555);
  static const Color textHint = Color(0xFF888888);

  static const Color background = Color(0xFFF7F7F7); // Off-White
  static const Color card = Colors.white;
  static const Color divider = Color(0xFFE0E0E0);

  // Neutral Colors (Dark Theme)
  static const Color textPrimaryDark = Color(0xFFEAEAEA); // Light Gray
  static const Color textSecondaryDark = Color(0xFFB0B0B0); // Medium Gray
  static const Color textHintDark =
      Color(0xFF888888); // Keep same hint color or slightly lighter
  static const Color backgroundDark =
      Color(0xFF121212); // Very Dark Gray (Material Guideline)
  static const Color backgroundDarkElevated =
      Color(0xFF1E1E1E); // Slightly lighter for elevated surfaces
  static const Color cardDark = Color(0xFF1E1E1E); // Dark Gray for cards
  static const Color dividerDark = Color(0xFF3A3A3A); // Darker Divider

  // Accent Colors
  static const Color success = Color(0xFFA8E6CF); // Mint Green
  static const Color accent = Color(0xFFF8B195); // Blush Pink

  // Functional Colors
  static const Color like = Color(0xFF4ECDC4); // Teal Blue for likes
  static const Color dislike =
      Color(0xFFB388EB); // Lavender Purple for dislikes
  static const Color superLike =
      Color(0xFFFFE66D); // Soft Yellow for super likes
  static const Color boost = Color(0xFFFF6F61); // Coral Peach for boost

  // Status Colors
  static const Color error = Color(0xFFFF6F61); // Coral Peach for errors
  static const Color warning = Color(0xFFFFE66D); // Soft Yellow for warnings
  static const Color info = Color(0xFF4ECDC4); // Teal Blue for info

  // Gradient Presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryLight, secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tertiaryGradient = LinearGradient(
    colors: [tertiaryLight, tertiary, tertiaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient matchGradient = LinearGradient(
    colors: [
      secondary.withAlpha((0.8 * 255).toInt()),
      secondary,
      secondaryDark,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient profileGradient = LinearGradient(
    colors: [
      accent.withAlpha((0.6 * 255).toInt()),
      accent,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Get a color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withAlpha((opacity * 255).toInt());
  }
}
