import 'package:hive_flutter/hive_flutter.dart';

/// Category for challenges
enum ChallengeCategory { health, mindfulness, productivity, social }

/// Daily progress entry for a challenge
class DailyProgress {
  final int dateTimestamp; // DateTime as milliseconds since epoch
  final bool completed;
  final bool usedFreeze; // Whether a streak freeze was used

  const DailyProgress({
    required this.dateTimestamp,
    required this.completed,
    this.usedFreeze = false,
  });

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(dateTimestamp);

  DailyProgress copyWith({
    int? dateTimestamp,
    bool? completed,
    bool? usedFreeze,
  }) {
    return DailyProgress(
      dateTimestamp: dateTimestamp ?? this.dateTimestamp,
      completed: completed ?? this.completed,
      usedFreeze: usedFreeze ?? this.usedFreeze,
    );
  }
}

/// 30-day challenge with progress tracking
class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeCategory category;
  final int durationDays; // Usually 30
  final int startDateTimestamp; // DateTime as milliseconds
  final List<DailyProgress> dailyProgress;
  final bool isActive;
  final int streakFreezeCount; // Earned freeze tokens
  final int iconCodePoint; // Material icon code point
  final int xpReward;
  final String? linkedFeature; // 'water', 'routines', 'todos', etc.

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.durationDays = 30,
    required this.startDateTimestamp,
    required this.dailyProgress,
    this.isActive = true,
    this.streakFreezeCount = 0,
    required this.iconCodePoint,
    this.xpReward = 100,
    this.linkedFeature,
  });

  DateTime get startDate =>
      DateTime.fromMillisecondsSinceEpoch(startDateTimestamp);

  /// Get current streak count
  int get currentStreak {
    if (dailyProgress.isEmpty) return 0;

    int streak = 0;
    final sortedProgress = List<DailyProgress>.from(dailyProgress)
      ..sort((a, b) => b.dateTimestamp.compareTo(a.dateTimestamp));

    for (final progress in sortedProgress) {
      if (progress.completed || progress.usedFreeze) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Get completion percentage
  double get completionPercentage {
    if (dailyProgress.isEmpty) return 0.0;
    final completedDays = dailyProgress
        .where((p) => p.completed || p.usedFreeze)
        .length;
    return (completedDays / durationDays).clamp(0.0, 1.0);
  }

  /// Get days completed
  int get daysCompleted {
    return dailyProgress.where((p) => p.completed || p.usedFreeze).length;
  }

  /// Check if challenge is completed
  bool get isCompleted => daysCompleted >= durationDays;

  /// Check if today is marked as complete
  bool isTodayCompleted(DateTime today) {
    final normalizedToday = DateTime(today.year, today.month, today.day);
    return dailyProgress.any((p) {
      final date = DateTime(p.date.year, p.date.month, p.date.day);
      return date == normalizedToday && (p.completed || p.usedFreeze);
    });
  }

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeCategory? category,
    int? durationDays,
    int? startDateTimestamp,
    List<DailyProgress>? dailyProgress,
    bool? isActive,
    int? streakFreezeCount,
    int? iconCodePoint,
    int? xpReward,
    String? linkedFeature,
    bool clearLinkedFeature = false,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      durationDays: durationDays ?? this.durationDays,
      startDateTimestamp: startDateTimestamp ?? this.startDateTimestamp,
      dailyProgress: dailyProgress ?? this.dailyProgress,
      isActive: isActive ?? this.isActive,
      streakFreezeCount: streakFreezeCount ?? this.streakFreezeCount,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      xpReward: xpReward ?? this.xpReward,
      linkedFeature: clearLinkedFeature
          ? null
          : (linkedFeature ?? this.linkedFeature),
    );
  }
}

// ============ HIVE ADAPTERS ============

class ChallengeCategoryAdapter extends TypeAdapter<ChallengeCategory> {
  @override
  final int typeId = 55;

  @override
  ChallengeCategory read(BinaryReader reader) {
    return ChallengeCategory.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ChallengeCategory obj) {
    writer.writeByte(obj.index);
  }
}

class DailyProgressAdapter extends TypeAdapter<DailyProgress> {
  @override
  final int typeId = 56;

  @override
  DailyProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyProgress(
      dateTimestamp: fields[0] as int,
      completed: fields[1] as bool,
      usedFreeze: fields[2] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, DailyProgress obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.dateTimestamp)
      ..writeByte(1)
      ..write(obj.completed)
      ..writeByte(2)
      ..write(obj.usedFreeze);
  }
}

class ChallengeAdapter extends TypeAdapter<Challenge> {
  @override
  final int typeId = 50;

  @override
  Challenge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Challenge(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as ChallengeCategory,
      durationDays: fields[4] as int,
      startDateTimestamp: fields[5] as int,
      dailyProgress: (fields[6] as List).cast<DailyProgress>(),
      isActive: fields[7] as bool,
      streakFreezeCount: fields[8] as int,
      iconCodePoint: fields[9] as int,
      xpReward: fields[10] as int,
      linkedFeature: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Challenge obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.durationDays)
      ..writeByte(5)
      ..write(obj.startDateTimestamp)
      ..writeByte(6)
      ..write(obj.dailyProgress)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.streakFreezeCount)
      ..writeByte(9)
      ..write(obj.iconCodePoint)
      ..writeByte(10)
      ..write(obj.xpReward)
      ..writeByte(11)
      ..write(obj.linkedFeature);
  }
}
