import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for voice command settings (language preference)
class VoiceSettingsProvider with ChangeNotifier {
  static const String _localeKey = 'voice_locale';
  String _selectedLocale = 'tr_TR'; // Default to Turkish

  VoiceSettingsProvider() {
    _loadSettings();
  }

  String get selectedLocale => _selectedLocale;

  /// Get display name for the current locale
  String get localeDisplayName {
    switch (_selectedLocale) {
      case 'tr_TR':
        return 'Türkçe';
      case 'en_US':
        return 'English';
      default:
        return _selectedLocale;
    }
  }

  /// Available locales for voice recognition
  static const List<Map<String, String>> availableLocales = [
    {'code': 'tr_TR', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en_US', 'name': 'English', 'flag': '🇬🇧'},
  ];

  /// Set the voice recognition locale
  Future<void> setLocale(String locale) async {
    if (_selectedLocale != locale) {
      _selectedLocale = locale;
      notifyListeners();
      await _saveSettings();
    }
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedLocale = prefs.getString(_localeKey) ?? 'tr_TR';
      notifyListeners();
    } catch (e) {
      // If error, use default
      _selectedLocale = 'tr_TR';
    }
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, _selectedLocale);
    } catch (e) {
      // Ignore save errors
    }
  }
}
