import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00D09E);
  static const Color secondaryColor = Color(0xFF1E293B);
  static const Color backgroundColor = Color(0xFF0F172A);
  static const Color cardColor = Color(0xFF1E293B);
  static const Color textPrimaryColor = Color(0xFFF8FAFC);
  static const Color textSecondaryColor = Color(0xFF94A3B8);
  static const Color accentColor = Color(0xFF8B5CF6);
  static const Color dangerColor = Color(0xFFEF4444);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: const TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 32),
        displayMedium: const TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 24),
        bodyLarge: const TextStyle(color: textPrimaryColor, fontSize: 16),
        bodyMedium: const TextStyle(color: textSecondaryColor, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
        error: dangerColor,
      ).copyWith(background: backgroundColor),
    );
  }
}
