import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Represents a background sound that can be played with affirmations
class BackgroundSound {
  final String id;
  final String name;
  final String nameEn;
  final String assetPath;
  final IconData icon;

  const BackgroundSound({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.assetPath,
    required this.icon,
  });

  /// Predefined background sounds available in the app
  static const List<BackgroundSound> presets = [
    BackgroundSound(
      id: 'ambient_pads',
      name: 'Ambient Sesler',
      nameEn: 'Ambient Pads',
      assetPath: 'assets/audio/backgrounds/ambient-pads.mp3',
      icon: LucideIcons.music,
    ),
    BackgroundSound(
      id: 'rain_wind_chimes',
      name: 'Yağmur & Rüzgar Çanları',
      nameEn: 'Rain & Wind Chimes',
      assetPath: 'assets/audio/backgrounds/rain-and-wind-chimes.mp3',
      icon: LucideIcons.cloudRain,
    ),
    BackgroundSound(
      id: 'summer_night',
      name: 'Yaz Gecesi',
      nameEn: 'Summer Night',
      assetPath: 'assets/audio/backgrounds/summer-night.mp3',
      icon: LucideIcons.moon,
    ),
  ];

  /// Find a background sound by its ID
  static BackgroundSound? findById(String id) {
    try {
      return presets.firstWhere((bg) => bg.id == id);
    } catch (_) {
      return null;
    }
  }
}
