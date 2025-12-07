import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Claymorphism Palette ---
  static const Color background = Color(0xFFF0EBE5); // Warm beige
  static const Color surface = Color(0xFFFDFBF7); // Lighter beige
  static const Color primary = Color(0xFFE08E6D); // Terracotta
  static const Color textPrimary = Color(0xFF4A3F35); // Dark Brown
  static const Color textSecondary = Color(0xFF8D8377); // Lighter Brown

  // Neutral / Utility
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color darkGrey = Color(0xFF4A3F35); // Mapped to textPrimary
  static const Color accentGrey = Color(
    0xFFD7CCC8,
  ); // Mapped to a light clay color
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFFBC02D);
  static const Color info = Color(0xFF1976D2);

  // Dark Mode Mappings (To prevent build errors, though Claymorphism is usually light)
  static const Color darkBackground = Color(0xFF2C2C2C);
  static const Color darkCard = Color(0xFF383838);
  static const Color darkSurface = Color(0xFF383838);
  static const Color primaryDark = Color(0xFFE08E6D);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);
  static const Color darkBorder = Color(0xFF505050);
  static const Color darkTertiary = Color(0xFF404040);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primary],
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [surface, surface],
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, background],
  );
  static const LinearGradient darkPrimaryGradient = LinearGradient(
    colors: [primaryDark, primaryDark],
  );
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [darkBackground, darkBackground],
  );
}
