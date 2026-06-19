import 'package:flutter/material.dart';

class AppTheme {
  // Light Mode Palette (from user palette)
  static const Color primaryColor = Color(0xFF017D3C); // Turf Green
  static const Color primaryDark = Color(0xFF03843B); // Sea Green
  static const Color primaryLight = Color(0xFFFBFCFC);

  static const Color successColor = Color(0xFF059669); // Emerald 600
  static const Color warningColor = Color(0xFFD97706); // Amber 600
  static const Color errorColor = Color(0xFFDC2626); // Red 600

  static const Color backgroundColor = Color(0xFFFBFCFC); // White
  static const Color surfaceColor = Color(0xFFFFFFFF); // White 2
  static const Color borderColor = Color(0x263B4247); // Iron Grey with opacity

  static const Color textPrimary = Color(0xFF000000); // Solid Black
  static const Color textSecondary = Color(0xFF000000); // Solid Black
  static const Color textLight = Color(0xFF000000); // Solid Black

  // Dark Mode Palette (from user palette)
  static const Color _darkBackground = Color(0xFF030804); // Black
  static const Color _darkSurface = Color(0xFF0A0B0B); // Onyx
  static const Color _darkBorder = Color(
    0x3326973C,
  ); // Forest Green with opacity
  static const Color _darkPrimary = Color(0xFF26973C); // Forest Green
  static const Color _darkTextPrimary = Color(0xFFFFFFFF); // Solid White
  static const Color _darkTextSecondary = Color(0xFFFFFFFF); // Solid White
  static const Color _darkTextLight = Color(0xFFFFFFFF); // Solid White

  // --- Light Theme ---
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: backgroundColor,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: primaryDark,
      surface: surfaceColor,
      onSurface: textPrimary,
      surfaceTint: Colors.transparent,
      error: errorColor,
      outline: borderColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderColor, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Colors.grey),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceColor,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: heading2,
      contentTextStyle: bodyMedium,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceColor,
      modalBackgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderColor),
      ),
      elevation: 4,
    ),
    textTheme: const TextTheme(
      headlineLarge: heading1,
      headlineMedium: heading2,
      headlineSmall: heading3,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelSmall: caption,
    ),
  );

  // --- Dark Theme ---
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: _darkBackground,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: _darkPrimary,
      onPrimary: Colors.white, // Text on primary button
      secondary: _darkPrimary,
      surface: _darkSurface,
      onSurface: _darkTextPrimary,
      surfaceTint: Colors.transparent,
      error: Color(0xFFEF4444), // Red 500
      outline: _darkBorder,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBackground,
      foregroundColor: _darkTextPrimary,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: _darkTextPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: _darkTextPrimary),
    ),
    cardTheme: CardThemeData(
      color: _darkSurface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _darkBorder, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _darkPrimary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Colors.grey),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimary, // Brighter indigo
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _darkPrimary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _darkSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: heading2.copyWith(color: _darkTextPrimary),
      contentTextStyle: bodyMedium.copyWith(color: _darkTextSecondary),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _darkSurface,
      modalBackgroundColor: _darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: _darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: _darkBorder),
      ),
      elevation: 4,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _darkPrimary),
    ),
    iconTheme: const IconThemeData(color: _darkTextSecondary),
    listTileTheme: const ListTileThemeData(
      iconColor: _darkTextSecondary,
      textColor: _darkTextPrimary,
    ),
    // APPLY TEXT THEME
    textTheme: const TextTheme(
      headlineLarge: heading1,
      headlineMedium: heading2,
      headlineSmall: heading3,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelSmall: caption,
    ).apply(bodyColor: _darkTextPrimary, displayColor: _darkTextPrimary),
  );

  // Typography - System-like, legible
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.7,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500, // Slightly heavier for readability
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textLight,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textLight,
    letterSpacing: 0.2,
  );
}
