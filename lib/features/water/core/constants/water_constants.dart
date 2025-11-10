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

  // Theme-compatible Colors (Orange/Pastel)
  static const Color waterOrange = Color(0xFFD2691E); // Primary orange
  static const Color waterOrangeLight = Color(0xFFE8A87C); // Light orange
  static const Color waterCream = Color(0xFFF5E6D3); // Cream
  static const Color waterPeach = Color(0xFFFFB347); // Peachy orange
  
  // Gradient (Orange theme)
  static const Gradient waterGradient = LinearGradient(
    colors: [
      Color(0xFFE8A87C), // Light orange
      Color(0xFFD2691E), // Primary orange
      Color(0xFFB8860B), // Dark orange
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Progress gradient
  static const Gradient progressGradient = LinearGradient(
    colors: [
      Color(0xFFFFB347), // Peach
      Color(0xFFE8A87C), // Light orange
      Color(0xFFD2691E), // Primary orange
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

