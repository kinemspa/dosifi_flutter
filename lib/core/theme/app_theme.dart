import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Medical app color palette - professional and calming
  static const _primaryColor = Color(0xFF1b7292); // Primary color as requested
  static const _primaryDark = Color(0xFF135663); // Darker variant
  static const _secondaryColor = Color(0xFFc76223); // Secondary color as requested
  static const _accentColor = Color(0xFF4CAF50); // Success green
  static const _errorColor = Color(0xFFD32F2F);
  static const _warningColor = Color(0xFFFF9800);
  static const _successColor = Color(0xFF388E3C);
  
  // App bar colors
  static const _appBarColor = Color(0xFF135663); // Dark primary variant
  static const _appBarTextColor = Color(0xFFFFFFFF); // White text
  
  // Light theme colors
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightBackground = Color(0xFFF5F7FA);
  static const _lightSurfaceVariant = Color(0xFFECEFF3);
  static const _lightOnSurface = Color(0xFF1A1C1E);
  static const _lightOnBackground = Color(0xFF2C2F33);
  
  // Dark theme colors
  static const _darkSurface = Color(0xFF1E1E1E);
  static const _darkBackground = Color(0xFF121212);
  static const _darkSurfaceVariant = Color(0xFF2D2D2D);
  static const _darkOnSurface = Color(0xFFE1E3E6);
  static const _darkOnBackground = Color(0xFFE1E3E6);

  static ThemeData lightTheme() {
    final ColorScheme colorScheme = const ColorScheme.light(
      primary: _primaryColor,
      primaryContainer: Color(0xFFB8E0ED), // Light primary container
      secondary: _secondaryColor,
      secondaryContainer: Color(0xFFFFDBCC), // Light secondary container
      tertiary: _accentColor,
      tertiaryContainer: Color(0xFFE8F5E8),
      error: _errorColor,
      errorContainer: Color(0xFFFECDD3),
      surface: _lightSurface,
      surfaceVariant: _lightSurfaceVariant,
      background: _lightBackground,
      onPrimary: Colors.white,
      onPrimaryContainer: Color(0xFF003544), // Dark text on light primary container
      onSecondary: Colors.white,
      onSecondaryContainer: Color(0xFF2D1B00), // Dark text on light secondary container
      onTertiary: Colors.white,
      onError: Colors.white,
      onSurface: _lightOnSurface,
      onBackground: _lightOnBackground,
      outline: Color(0xFFCBD5E1),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        elevation: 2,
        centerTitle: true,
        backgroundColor: _appBarColor,
        foregroundColor: _appBarTextColor,
        titleTextStyle: TextStyle(
          color: _appBarTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: _appBarTextColor),
        actionsIconTheme: IconThemeData(color: _appBarTextColor),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primary,
        labelStyle: GoogleFonts.inter(fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    final ColorScheme colorScheme = const ColorScheme.dark(
      primary: _primaryColor,
      primaryContainer: Color(0xFF003544), // Dark primary container
      secondary: _secondaryColor,
      secondaryContainer: Color(0xFF5D3A00), // Dark secondary container
      tertiary: _accentColor,
      error: _errorColor,
      surface: Color(0xFF1E1E1E),
      surfaceVariant: _darkSurfaceVariant,
      background: _darkBackground,
      onPrimary: Colors.white,
      onPrimaryContainer: Color(0xFFB8E0ED), // Light text on dark primary container
      onSecondary: Colors.white,
      onSecondaryContainer: Color(0xFFFFDBCC), // Light text on dark secondary container
      onTertiary: Colors.white,
      onError: Colors.white,
      onSurface: Color(0xFFE0E0E0),
      onBackground: _darkOnBackground,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        elevation: 2,
        centerTitle: true,
        backgroundColor: _appBarColor,
        foregroundColor: _appBarTextColor,
        titleTextStyle: TextStyle(
          color: _appBarTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: _appBarTextColor),
        actionsIconTheme: IconThemeData(color: _appBarTextColor),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primary,
        labelStyle: GoogleFonts.inter(fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Custom colors for special states
  static Color get warningColor => _warningColor;
  static Color get successColor => _successColor;
  
  // Gradient definitions for modern UI - using primary to lighter primary
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primaryColor, Color(0xFF2A8BA3)], // Primary to lighter primary
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [_secondaryColor, Color(0xFFD4753A)], // Secondary to lighter secondary
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_lightBackground, Color(0xFFE8F4F6)], // Light background to light primary tint
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_darkBackground, Color(0xFF1A2832)], // Dark background to dark primary tint
  );

  // Shadow definitions
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A6200EE),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x336200EE),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);

  // Custom getters
  static Color get accentColor => _accentColor;
  static Color get appBarColor => _appBarColor;
  static Color get appBarTextColor => _appBarTextColor;
  static Color get lightSurface => _lightSurface;
  static Color get lightBackground => _lightBackground;
  static Color get darkSurface => _darkSurface;
  static Color get darkBackground => _darkBackground;
}
