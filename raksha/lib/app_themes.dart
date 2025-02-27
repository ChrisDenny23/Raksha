import 'package:flutter/material.dart';

class AppThemes {
  // Light Theme Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF424242);
  static const Color errorRed = Color(0xFFE53935);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: lightGrey,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: darkGrey,
      error: errorRed,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryBlue,
    secondaryHeaderColor: Colors.black,
    scaffoldBackgroundColor: Colors.black54,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkGrey,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark(
      primary: darkGrey,
      secondary: Colors.white70,
      error: errorRed,
    ),
  );
}
