import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF3A7BF2);
  static const secondaryColor = Color(0xFF2A4D8F);
  static const accentColor = Color(0xFF25CED1);
  static const errorColor = Color(0xFFE63946);
  static const warningColor = Color(0xFFFFB703);
  static const successColor = Color(0xFF52B788);

  static const lightBackgroundColor = Color(0xFFF8F9FA);
  static const darkBackgroundColor = Color(0xFF121212);

  static const lightSurfaceColor = Color(0xFFFFFFFF);
  static const darkSurfaceColor = Color(0xFF1E1E1E);

  static const lightTextColor = Color(0xFF212529);
  static const darkTextColor = Color(0xFFF8F9FA);
  static const lightTextSecondaryColor = Color(0xFF6C757D);
  static const darkTextSecondaryColor = Color(0xFFADB5BD);

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      background: lightBackgroundColor,
      surface: lightSurfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: darkTextColor,
      onError: Colors.white,
      onBackground: lightTextColor,
      onSurface: lightTextColor,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      TextTheme(
        displayLarge: TextStyle(color: lightTextColor),
        displayMedium: TextStyle(color: lightTextColor),
        displaySmall: TextStyle(color: lightTextColor),
        headlineLarge: TextStyle(color: lightTextColor),
        headlineMedium: TextStyle(color: lightTextColor),
        headlineSmall: TextStyle(color: lightTextColor),
        titleLarge: TextStyle(color: lightTextColor),
        titleMedium: TextStyle(color: lightTextColor),
        titleSmall: TextStyle(color: lightTextColor),
        bodyLarge: TextStyle(color: lightTextColor),
        bodyMedium: TextStyle(color: lightTextColor),
        bodySmall: TextStyle(color: lightTextSecondaryColor),
        labelLarge: TextStyle(color: lightTextColor),
        labelMedium: TextStyle(color: lightTextColor),
        labelSmall: TextStyle(color: lightTextColor),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: lightSurfaceColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: const BorderSide(color: primaryColor, width: 2),
        foregroundColor: primaryColor,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        foregroundColor: primaryColor,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    iconTheme: const IconThemeData(color: primaryColor),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightSurfaceColor,
      foregroundColor: lightTextColor,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: errorColor),
      ),
    ),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: lightSurfaceColor,
      elevation: 5,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE9ECEF),
      thickness: 1,
      space: 1,
    ),
    scaffoldBackgroundColor: lightBackgroundColor,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: lightTextSecondaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      background: darkBackgroundColor,
      surface: darkSurfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onError: Colors.white,
      onBackground: darkTextColor,
      onSurface: darkTextColor,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      TextTheme(
        displayLarge: TextStyle(color: darkTextColor),
        displayMedium: TextStyle(color: darkTextColor),
        displaySmall: TextStyle(color: darkTextColor),
        headlineLarge: TextStyle(color: darkTextColor),
        headlineMedium: TextStyle(color: darkTextColor),
        headlineSmall: TextStyle(color: darkTextColor),
        titleLarge: TextStyle(color: darkTextColor),
        titleMedium: TextStyle(color: darkTextColor),
        titleSmall: TextStyle(color: darkTextColor),
        bodyLarge: TextStyle(color: darkTextColor),
        bodyMedium: TextStyle(color: darkTextColor),
        bodySmall: TextStyle(color: darkTextSecondaryColor),
        labelLarge: TextStyle(color: darkTextColor),
        labelMedium: TextStyle(color: darkTextColor),
        labelSmall: TextStyle(color: darkTextColor),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: darkSurfaceColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: const BorderSide(color: primaryColor, width: 2),
        foregroundColor: primaryColor,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        foregroundColor: primaryColor,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    iconTheme: const IconThemeData(color: primaryColor),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurfaceColor,
      foregroundColor: darkTextColor,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: errorColor),
      ),
    ),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: darkSurfaceColor,
      elevation: 5,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF343A40),
      thickness: 1,
      space: 1,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: darkTextSecondaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}
