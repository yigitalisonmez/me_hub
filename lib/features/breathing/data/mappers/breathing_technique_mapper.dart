import 'package:flutter/material.dart';
import '../../domain/entities/breathing_technique.dart';

/// Mapper for converting between domain entity and JSON for persistence
class BreathingTechniqueMapper {
  /// Convert domain entity to JSON
  static Map<String, dynamic> toJson(BreathingTechnique technique) {
    return {
      'id': technique.id,
      'name': technique.name,
      'nameEn': technique.nameEn,
      'description': technique.description,
      'descriptionEn': technique.descriptionEn,
      'category': technique.category,
      'inhaleSeconds': technique.inhaleSeconds,
      'holdAfterInhaleSeconds': technique.holdAfterInhaleSeconds,
      'exhaleSeconds': technique.exhaleSeconds,
      'holdAfterExhaleSeconds': technique.holdAfterExhaleSeconds,
      'primaryColor': technique.primaryColor.toARGB32(),
      'iconCodePoint': technique.icon.codePoint,
      'isCustom': technique.isCustom,
    };
  }

  /// Create domain entity from JSON
  static BreathingTechnique fromJson(Map<String, dynamic> json) {
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
