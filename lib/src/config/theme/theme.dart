import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF9575CD); // Lavender
  static const Color backgroundColor = Color.fromARGB(255, 30, 19, 87); // Deep Purple
  static const Color cardColor = Color(0xFF4527A0); // A slightly lighter purple
  static const Color textColor = Color(0xFFE6E6FA); // Lavender
  static const Color secondaryTextColor = Color(0xFFB39DDB); // Lighter Lavender

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dividerColor: Colors.grey.shade800,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      textTheme: GoogleFonts.latoTextTheme().apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        background: backgroundColor,
        surface: cardColor,
        onPrimary: textColor,
        onSecondary: textColor,
        onBackground: textColor,
        onSurface: textColor,
        error: Colors.redAccent,
        brightness: Brightness.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        labelStyle: const TextStyle(color: secondaryTextColor),
        hintStyle: const TextStyle(color: secondaryTextColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
        ),
      ),
    );
  }
}
