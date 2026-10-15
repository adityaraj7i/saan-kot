import 'package:flutter/material.dart';

class AppColors {
  // Brand Emeralds
  static const Color emeraldPrimary = Color(0xFF059669);
  static const Color emeraldAccent = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFFD1FAE5);
  static const Color emeraldDark = Color(0xFF065F46);

  // Amber / Warm Accents
  static const Color amberOrange = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFEF3C7);
  static const Color amberDark = Color(0xFFB45309);

  // Backgrounds & Surface
  static const Color alabasterBg = Color(0xFFF8FAFC);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);

  // Danger & Due
  static const Color roseRed = Color(0xFFE11D48);
  static const Color roseLight = Color(0xFFFFE4E6);

  // Tint Accents for Bento Grid
  static const Color blueTint = Color(0xFFEFF6FF);
  static const Color blueText = Color(0xFF2563EB);
  static const Color purpleTint = Color(0xFFF5F3FF);
  static const Color purpleText = Color(0xFF7C3AED);
  static const Color pinkTint = Color(0xFFFFF1F2);
  static const Color greenTint = Color(0xFFECFDF5);
}

class AppGradients {
  static const LinearGradient emeraldHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.emeraldPrimary, AppColors.emeraldAccent],
  );

  static const LinearGradient amberBadge = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );
}

class CurrencyHelper {
  static String format(double amount) {
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }
}
