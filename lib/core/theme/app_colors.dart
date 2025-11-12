import 'package:flutter/material.dart';

/// Global renk paleti - Me Hub uygulaması için özel renkler
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Ana renk paleti - Sidequest uygulaması tarzı
  static const Color primaryOrange = Color(
    0xFFD97D45,
  ); // Sıcak turuncu-kahverengi
  static const Color secondaryCream = Color(0xFFF5E6D3); // Açık bej/krem
  static const Color accentGrey = Color(0xFFE8E8E8); // Açık gri
  static const Color backgroundCream = Color(0xFFFDF5E6); // Arka plan krem

  // Renk varyasyonları
  static const Color primaryOrangeLight = Color(0xFFE8A87C);
  static const Color primaryOrangeDark = Color(0xFFB8860B);

  static const Color secondaryCreamLight = Color(0xFFFEF9F3);
  static const Color secondaryCreamDark = Color(0xFFE6D4C4);

  static const Color accentGreyLight = Color(0xFFF0F0F0);
  static const Color accentGreyDark = Color(0xFFD0D0D0);

  static const Color backgroundCreamLight = Color(0xFFFFFEF7);
  static const Color backgroundCreamDark = Color(0xFFF5E6D3);

  // Nötr renkler
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF6B7280);
  static const Color lightGrey = Color(0xFFF3F4F6);
  static const Color darkGrey = Color(0xFF374151);

  // Durum renkleri
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradient renkleri - Sidequest tarzı
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrangeLight, primaryOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [white, secondaryCreamLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundCream, backgroundCreamLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
