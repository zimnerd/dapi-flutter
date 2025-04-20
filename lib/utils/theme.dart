import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// App theme utility class for generating consistent theme data
class AppTheme {
  /// Get the light theme
  static ThemeData get lightTheme {
    // Get the base text theme
    final baseTextTheme =
        GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      primaryColor: AppColors.primary,
      colorScheme: _lightColorScheme,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.card,
      dividerColor: AppColors.divider,
      appBarTheme: _appBarTheme.copyWith(
        // Apply font to AppBar title
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      buttonTheme: _buttonTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      textButtonTheme: _textButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      // Apply the Inter font theme
      textTheme: baseTextTheme.copyWith(
        // Customize specific text styles if needed
        bodyLarge:
            baseTextTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
        bodyMedium:
            baseTextTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        labelLarge: baseTextTheme.labelLarge
            ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: _inputDecorationTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: GoogleFonts.inter().fontFamily, // Set default font family
      useMaterial3: true,
      bottomNavigationBarTheme: _bottomNavBarTheme,
      chipTheme: _chipTheme.copyWith(
        labelStyle: baseTextTheme.labelMedium, // Apply font to chips
      ),
      floatingActionButtonTheme: _fabTheme,
      switchTheme: _switchTheme,
      checkboxTheme: _checkboxTheme,
      radioTheme: _radioTheme,
      sliderTheme: _sliderTheme,
      snackBarTheme: _snackBarTheme,
    );
  }

  /// Light color scheme
  static ColorScheme get _lightColorScheme {
    return ColorScheme(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.secondaryDark,
      surface: AppColors.card,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
      brightness: Brightness.light,
      tertiary: AppColors.tertiary,
      tertiaryContainer: AppColors.tertiaryDark,
      onTertiary: Colors.white,
    );
  }

  /// App bar theme
  static AppBarTheme get _appBarTheme {
    return AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  /// Button theme
  static ButtonThemeData get _buttonTheme {
    return ButtonThemeData(
      buttonColor: AppColors.primary,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 24),
    );
  }

  /// Elevated button theme
  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 2,
        textStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Text button theme
  static TextButtonThemeData get _textButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Outlined button theme
  static OutlinedButtonThemeData get _outlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary, width: 1.5),
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Input decoration theme
  static InputDecorationTheme get _inputDecorationTheme {
    return InputDecorationTheme(
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: AppColors.textSecondary),
      hintStyle: TextStyle(color: AppColors.textHint),
      prefixIconColor: AppColors.primary,
      suffixIconColor: AppColors.primary,
    );
  }

  /// Bottom navigation bar theme
  static BottomNavigationBarThemeData get _bottomNavBarTheme {
    return BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedIconTheme: IconThemeData(size: 28),
      unselectedIconTheme: IconThemeData(size: 24),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    );
  }

  /// Chip theme
  static ChipThemeData get _chipTheme {
    return ChipThemeData(
      backgroundColor: AppColors.background,
      disabledColor: AppColors.divider,
      selectedColor: AppColors.primary,
      secondarySelectedColor: AppColors.secondary,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(color: AppColors.textPrimary),
      secondaryLabelStyle: TextStyle(color: Colors.white),
      brightness: Brightness.light,
    );
  }

  /// FAB theme
  static FloatingActionButtonThemeData get _fabTheme {
    return FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.white,
      extendedTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Switch theme
  static SwitchThemeData get _switchTheme {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary.withOpacity(0.4);
        }
        return AppColors.divider;
      }),
    );
  }

  /// Checkbox theme
  static CheckboxThemeData get _checkboxTheme {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return null;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// Radio theme
  static RadioThemeData get _radioTheme {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.textSecondary;
      }),
    );
  }

  /// Slider theme
  static SliderThemeData get _sliderTheme {
    return SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.divider,
      thumbColor: AppColors.primary,
      overlayColor: AppColors.primary.withOpacity(0.2),
      valueIndicatorColor: AppColors.primary,
      valueIndicatorTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Snackbar theme
  static SnackBarThemeData get _snackBarTheme {
    return SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontFamily: 'Poppins',
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    );
  }

  /// Get the dark theme
  static ThemeData get darkTheme {
    // Get the base dark text theme
    final baseTextTheme =
        GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      brightness: Brightness.dark, // Set brightness to dark
      primaryColor: AppColors.primary, // Keep primary for branding
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      cardColor: AppColors.cardDark,
      dividerColor: AppColors.dividerDark,
      appBarTheme: _appBarTheme.copyWith(
        backgroundColor: AppColors.backgroundDarkElevated, // Darker AppBar
        foregroundColor: AppColors.textPrimaryDark, // Light text on dark AppBar
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: AppColors.textPrimaryDark,
          fontWeight: FontWeight.bold,
        ),
      ),
      buttonTheme: _buttonTheme.copyWith(
          // Adjust button colors if needed for dark theme
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: _elevatedButtonTheme.style?.copyWith(
        backgroundColor: WidgetStateProperty.all(
            AppColors.primary), // Keep primary button color
        foregroundColor: WidgetStateProperty.all(
            AppColors.textPrimaryDark), // Ensure text is readable
      )),
      textButtonTheme: TextButtonThemeData(
          style: _textButtonTheme.style?.copyWith(
        foregroundColor: WidgetStateProperty.all(
            AppColors.primaryLight), // Lighter primary for text button
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: _outlinedButtonTheme.style?.copyWith(
        foregroundColor:
            WidgetStateProperty.all(AppColors.primaryLight), // Lighter primary
        side:
            WidgetStateProperty.all(BorderSide(color: AppColors.primaryLight)),
      )),
      textTheme: baseTextTheme.copyWith(
        // Apply dark theme text colors
        bodyLarge:
            baseTextTheme.bodyLarge?.copyWith(color: AppColors.textPrimaryDark),
        bodyMedium: baseTextTheme.bodyMedium
            ?.copyWith(color: AppColors.textSecondaryDark),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
            color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
            color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold),
        // Ensure hint colors are appropriate
        bodySmall:
            baseTextTheme.bodySmall?.copyWith(color: AppColors.textHintDark),
      ),
      inputDecorationTheme: _inputDecorationTheme.copyWith(
        fillColor: AppColors.backgroundDarkElevated,
        labelStyle: TextStyle(color: AppColors.textSecondaryDark),
        hintStyle: TextStyle(color: AppColors.textHintDark),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
              color: AppColors.primaryLight, width: 2), // Lighter focus border
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.dividerDark),
        ),
        prefixIconColor: AppColors.primaryLight,
        suffixIconColor: AppColors.primaryLight,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: GoogleFonts.inter().fontFamily,
      useMaterial3: true,
      bottomNavigationBarTheme: _bottomNavBarTheme.copyWith(
        backgroundColor: AppColors.backgroundDarkElevated,
        selectedItemColor:
            AppColors.primaryLight, // Lighter primary for selected items
        unselectedItemColor: AppColors.textSecondaryDark,
      ),
      chipTheme: _chipTheme.copyWith(
        backgroundColor: AppColors.backgroundDarkElevated,
        selectedColor: AppColors.primaryLight,
        labelStyle: baseTextTheme.labelMedium
            ?.copyWith(color: AppColors.textPrimaryDark),
        secondaryLabelStyle: TextStyle(color: AppColors.backgroundDark),
        brightness: Brightness.dark,
      ),
      floatingActionButtonTheme: _fabTheme.copyWith(
        backgroundColor: AppColors.secondaryLight, // Adjust FAB color if needed
        foregroundColor: AppColors.backgroundDark,
      ),
      switchTheme: _switchTheme.copyWith(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.dividerDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight.withOpacity(0.4);
          }
          return AppColors.dividerDark.withOpacity(0.6);
        }),
      ),
      checkboxTheme: _checkboxTheme.copyWith(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.textSecondaryDark;
        }),
        checkColor: WidgetStateProperty.all(AppColors.backgroundDark),
      ),
      radioTheme: _radioTheme.copyWith(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.textSecondaryDark;
        }),
      ),
      sliderTheme: _sliderTheme.copyWith(
          activeTrackColor: AppColors.primaryLight,
          inactiveTrackColor: AppColors.dividerDark,
          thumbColor: AppColors.primaryLight,
          overlayColor: AppColors.primaryLight.withOpacity(0.2),
          valueIndicatorColor: AppColors.primaryLight,
          valueIndicatorTextStyle: TextStyle(
            color: AppColors.backgroundDark, // Dark text on light indicator
          )),
      snackBarTheme: _snackBarTheme.copyWith(
        backgroundColor: AppColors.backgroundDarkElevated, // Darker snackbar
        contentTextStyle: TextStyle(
          color: AppColors.textPrimaryDark,
          fontFamily: GoogleFonts.inter().fontFamily,
          fontSize: 14,
        ),
      ),
    );
  }

  /// Dark color scheme
  static ColorScheme get _darkColorScheme {
    return ColorScheme(
      primary: AppColors
          .primaryLight, // Use lighter primary for dark theme interactions
      primaryContainer:
          AppColors.primary, // Can keep original primary for accents
      secondary: AppColors.secondaryLight, // Use lighter secondary
      secondaryContainer: AppColors.secondary,
      surface: AppColors.cardDark, // Dark background
      error: AppColors.error, // Keep error color vibrant
      onPrimary: AppColors.backgroundDark, // Dark text on light primary
      onSecondary: AppColors.backgroundDark, // Dark text on light secondary
      onSurface: AppColors.textPrimaryDark, // Light text on dark background
      onError: Colors.white, // Light text on error color
      brightness: Brightness.dark,
      tertiary: AppColors.tertiaryLight, // Lighter tertiary
      tertiaryContainer: AppColors.tertiary,
      onTertiary: AppColors.backgroundDark, // Dark text on light tertiary
    );
  }
}
