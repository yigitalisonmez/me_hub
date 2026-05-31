import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

part 'event_category.g.dart';

/// Predefined event categories
enum PredefinedCategory {
  subscription,
  bill,
  exam,
  meeting,
  birthday,
  appointment,
  reminder,
  other,
}

/// Extension for predefined categories
extension PredefinedCategoryExtension on PredefinedCategory {
  String get name {
    switch (this) {
      case PredefinedCategory.subscription:
        return 'Subscription';
      case PredefinedCategory.bill:
        return 'Bill';
      case PredefinedCategory.exam:
        return 'Exam';
      case PredefinedCategory.meeting:
        return 'Meeting';
      case PredefinedCategory.birthday:
        return 'Birthday';
      case PredefinedCategory.appointment:
        return 'Appointment';
      case PredefinedCategory.reminder:
        return 'Reminder';
      case PredefinedCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case PredefinedCategory.subscription:
        return LucideIcons.creditCard;
      case PredefinedCategory.bill:
        return LucideIcons.receipt;
      case PredefinedCategory.exam:
        return LucideIcons.graduationCap;
      case PredefinedCategory.meeting:
        return LucideIcons.users;
      case PredefinedCategory.birthday:
        return LucideIcons.cake;
      case PredefinedCategory.appointment:
        return LucideIcons.stethoscope;
      case PredefinedCategory.reminder:
        return LucideIcons.bell;
      case PredefinedCategory.other:
        return LucideIcons.tag;
    }
  }

  Color get color {
    switch (this) {
      case PredefinedCategory.subscription:
        return const Color(0xFF7E57C2); // Purple
      case PredefinedCategory.bill:
        return const Color(0xFFE57373); // Red
      case PredefinedCategory.exam:
        return const Color(0xFF64B5F6); // Blue
      case PredefinedCategory.meeting:
        return const Color(0xFF81C784); // Green
      case PredefinedCategory.birthday:
        return const Color(0xFFFFB74D); // Orange
      case PredefinedCategory.appointment:
        return const Color(0xFF4DD0E1); // Cyan
      case PredefinedCategory.reminder:
        return const Color(0xFFBA68C8); // Pink
      case PredefinedCategory.other:
        return const Color(0xFF90A4AE); // Grey
    }
  }
}

/// Event category - can be predefined or custom
@HiveType(typeId: 62)
class EventCategory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? iconName; // For custom categories

  @HiveField(3)
  final int colorValue; // Store color as int

  @HiveField(4)
  final bool isPredefined;

  EventCategory({
    required this.id,
    required this.name,
    this.iconName,
    required this.colorValue,
    this.isPredefined = false,
  });

  /// Get color from stored value
  Color get color => Color(colorValue);

  /// Get icon (default for custom categories)
  IconData get icon {
    if (isPredefined) {
      // Match predefined category by id
      final predefined = PredefinedCategory.values.firstWhere(
        (p) => p.name.toLowerCase() == id.toLowerCase(),
        orElse: () => PredefinedCategory.other,
      );
      return predefined.icon;
    }
    return LucideIcons.tag; // Default icon for custom
  }

  /// Create from predefined category
  factory EventCategory.fromPredefined(PredefinedCategory category) {
    return EventCategory(
      id: category.name.toLowerCase(),
      name: category.name,
      colorValue: category.color.toARGB32(),
      isPredefined: true,
    );
  }

  /// Create custom category
  factory EventCategory.custom({
    required String name,
    Color color = const Color(0xFF90A4AE),
  }) {
    return EventCategory(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      colorValue: color.toARGB32(),
      isPredefined: false,
    );
  }

  /// Get all predefined categories
  static List<EventCategory> get predefinedCategories {
    return PredefinedCategory.values
        .map((p) => EventCategory.fromPredefined(p))
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
