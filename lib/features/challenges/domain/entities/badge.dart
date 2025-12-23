import 'package:hive_flutter/hive_flutter.dart';

/// Badge tier levels
enum BadgeTier { bronze, silver, gold, platinum }

/// Badge requirement type
enum BadgeRequirementType {
  streak, // X days in a row
  totalWater, // Total water consumed
  totalTasks, // Total tasks completed
  challengesCompleted, // Number of challenges completed
  specialAction, // Special one-time actions
}

/// Unlockable achievement badge
class Badge {
  final String id;
  final String name;
  final String description;
  final BadgeTier tier;
  final int iconCodePoint;
  final BadgeRequirementType requirementType;
  final int requirementValue; // e.g., 7 for "7 day streak"
  final int? unlockedAtTimestamp;
  final bool isUnlocked;
  final int xpReward;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.iconCodePoint,
    required this.requirementType,
    required this.requirementValue,
    this.unlockedAtTimestamp,
    this.isUnlocked = false,
    this.xpReward = 25,
  });

  DateTime? get unlockedAt => unlockedAtTimestamp != null
      ? DateTime.fromMillisecondsSinceEpoch(unlockedAtTimestamp!)
      : null;

  Badge copyWith({
    String? id,
    String? name,
    String? description,
    BadgeTier? tier,
    int? iconCodePoint,
    BadgeRequirementType? requirementType,
    int? requirementValue,
    int? unlockedAtTimestamp,
    bool clearUnlockedAt = false,
    bool? isUnlocked,
    int? xpReward,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tier: tier ?? this.tier,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      requirementType: requirementType ?? this.requirementType,
      requirementValue: requirementValue ?? this.requirementValue,
      unlockedAtTimestamp: clearUnlockedAt
          ? null
          : (unlockedAtTimestamp ?? this.unlockedAtTimestamp),
      isUnlocked: isUnlocked ?? this.isUnlocked,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  /// Unlock this badge
  Badge unlock() {
    return copyWith(
      isUnlocked: true,
      unlockedAtTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

// ============ HIVE ADAPTERS ============

class BadgeTierAdapter extends TypeAdapter<BadgeTier> {
  @override
  final int typeId = 58;

  @override
  BadgeTier read(BinaryReader reader) {
    return BadgeTier.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, BadgeTier obj) {
    writer.writeByte(obj.index);
  }
}

class BadgeRequirementTypeAdapter extends TypeAdapter<BadgeRequirementType> {
  @override
  final int typeId = 59;

  @override
  BadgeRequirementType read(BinaryReader reader) {
    return BadgeRequirementType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, BadgeRequirementType obj) {
    writer.writeByte(obj.index);
  }
}

class BadgeAdapter extends TypeAdapter<Badge> {
  @override
  final int typeId = 52;

  @override
  Badge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Badge(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      tier: fields[3] as BadgeTier,
      iconCodePoint: fields[4] as int,
      requirementType: fields[5] as BadgeRequirementType,
      requirementValue: fields[6] as int,
      unlockedAtTimestamp: fields[7] as int?,
      isUnlocked: fields[8] as bool? ?? false,
      xpReward: fields[9] as int? ?? 25,
    );
  }

  @override
  void write(BinaryWriter writer, Badge obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.tier)
      ..writeByte(4)
      ..write(obj.iconCodePoint)
      ..writeByte(5)
      ..write(obj.requirementType)
      ..writeByte(6)
      ..write(obj.requirementValue)
      ..writeByte(7)
      ..write(obj.unlockedAtTimestamp)
      ..writeByte(8)
      ..write(obj.isUnlocked)
      ..writeByte(9)
      ..write(obj.xpReward);
  }
}
