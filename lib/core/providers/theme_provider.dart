import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

/// Theme provider for managing light/dark mode
class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = false;

  ThemeProvider() {
    _loadTheme();
  }

  bool get isDarkMode => _isDarkMode;

  /// Get background color based on current theme
  Color get backgroundColor =>
      _isDarkMode ? AppColors.darkBackground : AppColors.background;

  /// Get card background color
  Color get cardColor => _isDarkMode ? AppColors.darkCard : AppColors.white;

  /// Get surface color (for stat cards, log items, etc.)
  Color get surfaceColor =>
      _isDarkMode ? AppColors.darkSurface : AppColors.surface;

  /// Get input field fill color - elevated/lighter than card for depth
  Color get inputFillColor => _isDarkMode
      ? const Color(0xFF3A3A3A) // Lighter than darkCard for depth
      : const Color(0xFFFAFAFA); // Lighter than white for subtle depth

  /// Get primary color (orange) - same for both light and dark mode
  Color get primaryColor => AppColors.primary;

  /// Get primary gradient - same for both light and dark mode
  LinearGradient get primaryGradient => AppColors.primaryGradient;

  /// Get text primary color
  Color get textPrimary =>
      _isDarkMode ? AppColors.darkTextPrimary : AppColors.darkGrey;

  /// Get text secondary color
  Color get textSecondary =>
      _isDarkMode ? AppColors.darkTextSecondary : AppColors.grey;

  /// Get border color - same primary for both modes
  Color get borderColor => AppColors.primary;

  /// Toggle theme mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _saveTheme();
  }

  /// Set theme mode
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      notifyListeners();
      await _saveTheme();
    }
  }

  /// Load theme preference from SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      // If error, use default (light mode)
      _isDarkMode = false;
    }
  }

  /// Save theme preference to SharedPreferences
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      // Ignore save errors
    }
  }
}
