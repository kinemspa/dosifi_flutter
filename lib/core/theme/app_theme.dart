import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Centralized app theme for Dosifi (clean and SDK-compatible)
class AppTheme {
  // Brand colors
  static const _primaryColor = Color(0xFF1b7292);
  static const _secondaryColor = Color(0xFFc76223);
  static const _accentColor = Color(0xFF4CAF50);
  static const _errorColor = Color(0xFFD32F2F);
  static const _successColor = Color(0xFF388E3C);

  // Surfaces
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightBackground = Color(0xFFF5F7FA);
  static const _lightOnSurface = Color(0xFF1A1C1E);
  static const _darkSurface = Color(0xFF1E1E1E);
  static const _darkBackground = Color(0xFF121212);
  static const _darkSurfaceVariant = Color(0xFF2D2D2D);

  // App bar
  static const _appBarTextColor = Color(0xFFFFFFFF);

  static ThemeData lightTheme() {
    const scheme = ColorScheme.light(
      primary: _primaryColor,
      secondary: _secondaryColor,
      tertiary: _accentColor,
      error: _errorColor,
      surface: _lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onError: Colors.white,
      onSurface: _lightOnSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _lightBackground,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        // Soften titles/headings more per feedback
        displayLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface.withValues(alpha: 0.85),
        ),
        displayMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface.withValues(alpha: 0.85),
        ),
        displaySmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface.withValues(alpha: 0.85),
        ),
        headlineLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface.withValues(alpha: 0.82),
        ),
        headlineMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface.withValues(alpha: 0.82),
        ),
        headlineSmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface.withValues(alpha: 0.82),
        ),
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface.withValues(alpha: 0.8),
        ),
        titleMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface.withValues(alpha: 0.78),
        ),
        titleSmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface.withValues(alpha: 0.76),
        ),
        bodyLarge: GoogleFonts.poppins(
          color: scheme.onSurface.withValues(alpha: 0.78),
        ),
        bodyMedium: GoogleFonts.poppins(
          color: scheme.onSurface.withValues(alpha: 0.75),
        ),
        bodySmall: GoogleFonts.poppins(
          color: scheme.onSurface.withValues(alpha: 0.62),
        ),
        labelLarge: GoogleFonts.poppins(
          color: scheme.onSurface.withValues(alpha: 0.78),
        ),
        labelMedium: GoogleFonts.poppins(
          color: scheme.onSurface.withValues(alpha: 0.7),
        ),
        labelSmall: GoogleFonts.poppins(
          color: scheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 2,
        centerTitle: true,
        backgroundColor: _primaryColor,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface.withValues(alpha: 0.85),
          side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.25)),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          backgroundColor: scheme.surface,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          // Transparent by default so icons work on colored surfaces (no white circles)
          backgroundColor: Colors.transparent,
          foregroundColor: scheme.onSurface.withValues(alpha: 0.8),
          padding: const EdgeInsets.all(10),
          shape: const StadiumBorder(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFFCBD5E1).withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _errorColor),
        ),
        hintStyle: GoogleFonts.poppins(
          color: scheme.onSurface.withValues(alpha: 0.32),
          fontSize: 13,
        ),
        labelStyle: GoogleFonts.poppins(
          color: scheme.onSurface.withValues(alpha: 0.55),
        ),
        floatingLabelStyle: GoogleFonts.poppins(
          color: scheme.onSurface.withValues(alpha: 0.65),
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurface.withValues(alpha: 0.6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary,
        disabledColor: const Color(0xFFECEFF3),
        labelStyle: GoogleFonts.poppins(fontSize: 14, color: scheme.onSurface),
        secondaryLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: scheme.onPrimary,
        ),
        deleteIconColor: scheme.onSurface,
        selectedShadowColor: Colors.transparent,
        showCheckmark: false,
        checkmarkColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  static ThemeData darkTheme() {
    const scheme = ColorScheme.dark(
      primary: _primaryColor,
      secondary: _secondaryColor,
      tertiary: _accentColor,
      error: _errorColor,
      surface: _darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onError: Colors.white,
      onSurface: Color(0xFFE0E0E0),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _darkBackground,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.88),
            ),
            displayMedium: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.88),
            ),
            displaySmall: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.88),
            ),
            headlineLarge: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.86),
            ),
            headlineMedium: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.86),
            ),
            headlineSmall: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.86),
            ),
            titleLarge: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.84),
            ),
            titleMedium: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.82),
            ),
            titleSmall: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.8),
            ),
            bodyLarge: GoogleFonts.poppins(
              color: scheme.onSurface.withValues(alpha: 0.85),
            ),
            bodyMedium: GoogleFonts.poppins(
              color: scheme.onSurface.withValues(alpha: 0.82),
            ),
            bodySmall: GoogleFonts.poppins(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
            labelLarge: GoogleFonts.poppins(
              color: scheme.onSurface.withValues(alpha: 0.85),
            ),
            labelMedium: GoogleFonts.poppins(
              color: scheme.onSurface.withValues(alpha: 0.82),
            ),
            labelSmall: GoogleFonts.poppins(
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
      appBarTheme: const AppBarTheme(
        elevation: 2,
        centerTitle: true,
        backgroundColor: _primaryColor,
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
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface.withValues(alpha: 0.9),
          side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.35)),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          backgroundColor: scheme.surface,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          // Transparent by default in dark as well
          backgroundColor: Colors.transparent,
          foregroundColor: scheme.onSurface.withValues(alpha: 0.85),
          padding: const EdgeInsets.all(10),
          shape: const StadiumBorder(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: (Colors.grey[600] ?? Colors.grey).withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _errorColor),
        ),
        hintStyle: GoogleFonts.poppins(
          color: scheme.onSurface.withValues(alpha: 0.35),
          fontSize: 13,
        ),
        labelStyle: GoogleFonts.poppins(
          color: scheme.onSurface.withValues(alpha: 0.65),
        ),
        floatingLabelStyle: GoogleFonts.poppins(
          color: scheme.onSurface.withValues(alpha: 0.72),
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurface.withValues(alpha: 0.6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary,
        disabledColor: _darkSurfaceVariant,
        labelStyle: GoogleFonts.poppins(fontSize: 14, color: scheme.onSurface),
        secondaryLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: scheme.onPrimary,
        ),
        deleteIconColor: scheme.onSurface,
        selectedShadowColor: Colors.transparent,
        showCheckmark: false,
        checkmarkColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  // Custom colors for special states
  static Color get successColor => _successColor;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primaryColor, Color(0xFF2A8BA3)],
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_lightBackground, Color(0xFFE8F4F6)],
  );

  // Convenience getters (optional)
  static Color get accentColor => _accentColor;
  static Color get appBarColor => _primaryColor;
  static Color get appBarTextColor => _appBarTextColor;
  static Color get lightSurface => _lightSurface;
  static Color get lightBackground => _lightBackground;
  static Color get darkSurface => _darkSurface;
  static Color get darkBackground => _darkBackground;

  // Shadows
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}
