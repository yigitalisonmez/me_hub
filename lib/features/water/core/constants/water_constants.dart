import 'package:flutter/material.dart';

class WaterConstants {
  WaterConstants._();

  // Daily goal in milliliters
  static const int dailyGoalMl = 2000;

  // Quick add amounts (in ml)
  static const List<int> quickAddAmounts = [100, 200, 250, 500];

  // Quick add labels
  static const Map<int, String> quickAddLabels = {
    100: '100ml',
    200: '1 Glass',
    250: '1 Cup',
    500: '1 Bottle',
  };

  // Quick add icons
  static const Map<int, IconData> quickAddIcons = {
    100: Icons.local_drink,
    200: Icons.wine_bar,
    250: Icons.coffee,
    500: Icons.water_drop,
  };

  // Theme-compatible Colors (Orange/Pastel) - Use AppColors
  static const Color waterOrange = Color(0xFFD2691E); // Primary orange
  static const Color waterOrangeLight = Color(0xFFE8A87C); // Light orange
  static const Color waterCream = Color(0xFFF5E6D3); // Cream
  static const Color waterPeach = Color(0xFFFFB347); // Peachy orange
  
  // Water liquid colors (Blue theme for water)
  static const Color waterBlue = Color(0xFF81D4FA); // Pastel blue (lighter)
  static const Color waterBlueLight = Color(0xFFB3E5FC); // Very light pastel blue
  static const Color waterBlueDark = Color(0xFF4FC3F7); // Medium blue
  
  // Water gradient for liquid
  static const Gradient waterLiquidGradient = LinearGradient(
    colors: [
      Color(0xFFB3E5FC), // Very light pastel blue
      Color(0xFF81D4FA), // Light pastel blue
      Color(0xFF4FC3F7), // Medium blue
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

