import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Represents a breathing technique with configurable phases
class BreathingTechnique {
  final String id;
  final String name;
  final String nameEn;
  final String description;
  final String descriptionEn;
  final String category; // 'relax', 'focus', 'energy', 'sleep', 'custom'
  final int inhaleSeconds;
  final int holdAfterInhaleSeconds;
  final int exhaleSeconds;
  final int holdAfterExhaleSeconds;
  final Color primaryColor;
  final IconData icon;
  final bool isCustom;

  const BreathingTechnique({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.descriptionEn,
    required this.category,
    required this.inhaleSeconds,
    required this.holdAfterInhaleSeconds,
    required this.exhaleSeconds,
    required this.holdAfterExhaleSeconds,
    required this.primaryColor,
    required this.icon,
    this.isCustom = false,
  });

  /// Total duration of one breathing cycle in seconds
  int get cycleDuration =>
      inhaleSeconds +
      holdAfterInhaleSeconds +
      exhaleSeconds +
      holdAfterExhaleSeconds;

  /// Number of active phases (determines polygon shape)
  int get phaseCount {
    int count = 0;
    if (inhaleSeconds > 0) count++;
    if (holdAfterInhaleSeconds > 0) count++;
    if (exhaleSeconds > 0) count++;
    if (holdAfterExhaleSeconds > 0) count++;
    return count;
  }

  /// Get list of phases with their durations
  List<({String label, int duration})> get phases {
    final result = <({String label, int duration})>[];
    if (inhaleSeconds > 0) {
      result.add((label: 'Breathe In', duration: inhaleSeconds));
    }
    if (holdAfterInhaleSeconds > 0) {
      result.add((label: 'Hold', duration: holdAfterInhaleSeconds));
    }
    if (exhaleSeconds > 0) {
      result.add((label: 'Breathe Out', duration: exhaleSeconds));
    }
    if (holdAfterExhaleSeconds > 0) {
      result.add((label: 'Hold', duration: holdAfterExhaleSeconds));
    }
    return result;
  }

  /// Calculate how many cycles fit in a given duration
  int cyclesInDuration(int minutes) {
    final totalSeconds = minutes * 60;
    return (totalSeconds / cycleDuration).floor();
  }

  /// Preset breathing techniques
  static const List<BreathingTechnique> presets = [
    // 4-7-8 Technique - Relaxation / Sleep
    BreathingTechnique(
      id: '4-7-8',
      name: '4-7-8 Tekniği',
      nameEn: '4-7-8 Technique',
      description: 'Rahatlatıcı nefes tekniği. Uyku öncesi idealdir.',
      descriptionEn: 'Relaxing breath technique. Ideal before sleep.',
      category: 'sleep',
      inhaleSeconds: 4,
      holdAfterInhaleSeconds: 7,
      exhaleSeconds: 8,
      holdAfterExhaleSeconds: 0,
      primaryColor: Color(0xFF7E57C2), // Purple for sleep
      icon: LucideIcons.moon,
    ),

    // Box Breathing - Focus
    BreathingTechnique(
      id: 'box',
      name: 'Kutu Nefesi',
      nameEn: 'Box Breathing',
      description: 'Navy SEALs tarafından kullanılan odaklanma tekniği.',
      descriptionEn: 'Focus technique used by Navy SEALs.',
      category: 'focus',
      inhaleSeconds: 4,
      holdAfterInhaleSeconds: 4,
      exhaleSeconds: 4,
      holdAfterExhaleSeconds: 4,
      primaryColor: Color(0xFF42A5F5), // Blue for focus
      icon: LucideIcons.square,
    ),

    // Resonance Breathing - Balance
    BreathingTechnique(
      id: 'resonance',
      name: 'Rezonans Nefesi',
      nameEn: 'Resonance Breathing',
      description: 'Kalp ritmi ile senkronize denge tekniği.',
      descriptionEn: 'Balance technique synchronized with heart rhythm.',
      category: 'relax',
      inhaleSeconds: 6,
      holdAfterInhaleSeconds: 0,
      exhaleSeconds: 6,
      holdAfterExhaleSeconds: 0,
      primaryColor: Color(0xFF26A69A), // Teal for balance
      icon: LucideIcons.waves,
    ),

    // Energizing Breath - Energy
    BreathingTechnique(
      id: 'energy',
      name: 'Enerji Nefesi',
      nameEn: 'Energizing Breath',
      description: 'Hızlı ve canlandırıcı nefes tekniği.',
      descriptionEn: 'Fast and invigorating breathing technique.',
      category: 'energy',
      inhaleSeconds: 2,
      holdAfterInhaleSeconds: 0,
      exhaleSeconds: 2,
      holdAfterExhaleSeconds: 0,
      primaryColor: Color(0xFFFF7043), // Orange for energy
      icon: LucideIcons.zap,
    ),

    // Calming Breath - Quick Relaxation
    BreathingTechnique(
      id: 'calm',
      name: 'Sakinleştirici Nefes',
      nameEn: 'Calming Breath',
      description: 'Kısa ve etkili sakinleşme tekniği.',
      descriptionEn: 'Short and effective calming technique.',
      category: 'relax',
      inhaleSeconds: 4,
      holdAfterInhaleSeconds: 2,
      exhaleSeconds: 6,
      holdAfterExhaleSeconds: 0,
      primaryColor: Color(0xFF4DB6AC), // Light teal for calm
      icon: LucideIcons.heart,
    ),
  ];

  /// Find a technique by its ID
  static BreathingTechnique? findById(String id) {
    try {
      return presets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get techniques by category
  static List<BreathingTechnique> byCategory(String category) {
    return presets.where((t) => t.category == category).toList();
  }

  /// Create a custom technique
  factory BreathingTechnique.custom({
    required String name,
    required int inhale,
    required int holdIn,
    required int exhale,
    required int holdOut,
  }) {
    return BreathingTechnique(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      nameEn: name,
      description: 'Özel nefes tekniği',
      descriptionEn: 'Custom breathing technique',
      category: 'custom',
      inhaleSeconds: inhale,
      holdAfterInhaleSeconds: holdIn,
      exhaleSeconds: exhale,
      holdAfterExhaleSeconds: holdOut,
      primaryColor: const Color(0xFFE08E6D), // Terracotta
      icon: LucideIcons.settings,
      isCustom: true,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'description': description,
      'descriptionEn': descriptionEn,
      'category': category,
      'inhaleSeconds': inhaleSeconds,
      'holdAfterInhaleSeconds': holdAfterInhaleSeconds,
      'exhaleSeconds': exhaleSeconds,
      'holdAfterExhaleSeconds': holdAfterExhaleSeconds,
      'primaryColor': primaryColor.toARGB32(),
      'iconCodePoint': icon.codePoint,
      'isCustom': isCustom,
    };
  }

  /// Create from JSON
  factory BreathingTechnique.fromJson(Map<String, dynamic> json) {
    return BreathingTechnique(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String,
      description: json['description'] as String,
      descriptionEn: json['descriptionEn'] as String,
      category: json['category'] as String,
      inhaleSeconds: json['inhaleSeconds'] as int,
      holdAfterInhaleSeconds: json['holdAfterInhaleSeconds'] as int,
      exhaleSeconds: json['exhaleSeconds'] as int,
      holdAfterExhaleSeconds: json['holdAfterExhaleSeconds'] as int,
      primaryColor: Color(json['primaryColor'] as int),
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: 'LucideIcons',
        fontPackage: 'lucide_icons_flutter',
      ),
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}
