import 'package:flutter/material.dart';

/// Global renk paleti - Me Hub uygulaması için özel renkler
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Ana renk paleti - Sidequest uygulaması tarzı
  static const Color primaryOrange = Color(
    0xFFD97D45,
  ); // Sıcak turuncu-kahverengi
  static const Color backgroundCream = Color(0xFFFFF5ED);
  static const Color secondaryCream = Color(0xFFFFF9F5); // Açık bej/krem
  static const Color accentGrey = Color(0xFFE8E8E8); // Açık gri
  // Arka plan krem

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

  // Dark Mode Renkleri - Figma AI tasarımından
  static const Color darkBackground = Color(
    0xFF1E1E1E,
  ); // Çok koyu gri - ana arka plan
  static const Color darkCard = Color(
    0xFF2A2A2A,
  ); // Orta koyu gri - kart arka planı
  static const Color darkSurface = Color(
    0xFF343434,
  ); // Açık koyu gri - yüzeyler (stat cards, log items)
  static const Color darkOrange = Color(
    0xFFFF8A65,
  ); // Canlı coral/salmon turuncu - accent
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Beyaz - ana metin
  static const Color darkTextSecondary = Color(
    0xFFB0B0B0,
  ); // Açık gri - ikincil metin
  static const Color darkBorder = Color(
    0xFFFF8A65,
  ); // Border rengi (aynı orange)

  // Dark Mode Gradient - uses same orange as light mode
  static const LinearGradient darkPrimaryGradient = LinearGradient(
    colors: [primaryOrangeLight, primaryOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
