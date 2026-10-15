import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF26B14C);
  static const Color activeOrange = Color(0xFFF58216);
  static const Color scaffoldBg = Color(0xFFF2F4F7);
  static const Color cardWhite = Colors.white;

  // Cached text theme to eliminate scroll lag
  static final TextTheme _cachedTextTheme = GoogleFonts.interTextTheme();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primaryGreen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: activeOrange,
      ),
      textTheme: _cachedTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
