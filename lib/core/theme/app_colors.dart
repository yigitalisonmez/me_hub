import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Kora warm clay palette ---
  static const Color background = Color(0xFFF1ECE5);
  static const Color backgroundAlt = Color(0xFFECE5DC);
  static const Color surface = Color(0xFFFDFBF7);
  static const Color surfaceAlt = Color(0xFFF7F1E9);
  static const Color elevated = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFFE08E6D);
  static const Color primaryDeep = Color(0xFFC9714F);
  static const Color primarySoft = Color(0xFFF0B79E);
  static const Color textPrimary = Color(0xFF423A31);
  static const Color textSecondary = Color(0xFF7D7264);
  static const Color textTertiary = Color(0xFFA89C8C);

  // Category accents from the Claude Design handoff.
  static const Color water = Color(0xFF6FA3C7);
  static const Color waterDeep = Color(0xFF4E84AA);
  static const Color waterTint = Color(0xFFE7EFF4);
  static const Color mood = Color(0xFFE0AC62);
  static const Color moodDeep = Color(0xFFC9912F);
  static const Color moodTint = Color(0xFFF6ECDC);
  static const Color routine = Color(0xFF8FA87C);
  static const Color routineDeep = Color(0xFF6E895B);
  static const Color routineTint = Color(0xFFEBF0E5);
  static const Color mindful = Color(0xFF9D93C4);
  static const Color mindfulDeep = Color(0xFF7C70AC);
  static const Color mindfulTint = Color(0xFFECE9F3);
  static const Color terraTint = Color(0xFFF8E7DD);

  // Neutral / Utility
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color darkGrey = textPrimary;
  static const Color accentGrey = Color(0xFFD7CCC8);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFFBC02D);
  static const Color info = Color(0xFF1976D2);

  // Warm dark mode, kept close to the redesign prototype.
  static const Color darkBackground = Color(0xFF1C1916);
  static const Color darkBackgroundAlt = Color(0xFF221E1A);
  static const Color darkCard = Color(0xFF2A2622);
  static const Color darkSurface = Color(0xFF322D28);
  static const Color darkElevated = Color(0xFF312C27);
  static const Color primaryDark = primary;
  static const Color darkTextPrimary = Color(0xFFF2EADF);
  static const Color darkTextSecondary = Color(0xFFB9AD9E);
  static const Color darkTextTertiary = Color(0xFF8B8073);
  static const Color darkBorder = Color(0xFF4B4239);
  static const Color darkTertiary = Color(0xFF3A342E);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDeep],
  );
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceAlt],
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, backgroundAlt],
  );
  static const LinearGradient darkPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryDeep],
  );
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkBackground, darkBackgroundAlt],
  );
}
