import 'package:hive_flutter/hive_flutter.dart';

/// Type of weekly goal
enum GoalType {
  waterStreak, // Drink water every day
  taskStreak, // Complete tasks every day
  routineStreak, // Complete routine every day
  moodTrack, // Track mood every day
  gratitude, // Write gratitude every day
  custom, // User-defined goal
}

/// Weekly goal with 7-day tracking
class WeeklyGoal {
  final String id;
  final String title;
  final String description;
  final int weekStartTimestamp; // Monday of the week
  final List<bool> dailyChecklist; // 7 booleans for Mon-Sun
  final GoalType type;
  final int targetValue; // e.g., drink 2000ml water
  final String unit; // e.g., 'ml', 'tasks', etc.
  final int iconCodePoint;
  final int xpReward;

  const WeeklyGoal({
    required this.id,
    required this.title,
    this.description = '',
    required this.weekStartTimestamp,
    required this.dailyChecklist,
    required this.type,
    this.targetValue = 1,
    this.unit = '',
    required this.iconCodePoint,
    this.xpReward = 50,
  });

  DateTime get weekStartDate =>
      DateTime.fromMillisecondsSinceEpoch(weekStartTimestamp);

  /// Get number of completed days
  int get completedDays => dailyChecklist.where((d) => d).length;

  /// Get completion percentage
  double get completionPercentage => completedDays / 7;

  /// Check if weekly goal is fully completed
  bool get isCompleted => completedDays == 7;

  /// Get current streak (consecutive days from start)
  int get currentStreak {
    int streak = 0;
    for (final completed in dailyChecklist) {
      if (completed) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Check if today's goal is completed
  bool isTodayCompleted(DateTime today) {
    final weekStart = weekStartDate;
    final dayIndex = today.difference(weekStart).inDays;
    if (dayIndex < 0 || dayIndex >= 7) return false;
    return dailyChecklist[dayIndex];
  }

  /// Get day index for a given date (0=Mon, 6=Sun)
  int? getDayIndex(DateTime date) {
    final weekStart = weekStartDate;
    final dayIndex = date.difference(weekStart).inDays;
    if (dayIndex < 0 || dayIndex >= 7) return null;
    return dayIndex;
  }

  WeeklyGoal copyWith({
    String? id,
    String? title,
    String? description,
    int? weekStartTimestamp,
    List<bool>? dailyChecklist,
    GoalType? type,
    int? targetValue,
    String? unit,
    int? iconCodePoint,
    int? xpReward,
  }) {
    return WeeklyGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      weekStartTimestamp: weekStartTimestamp ?? this.weekStartTimestamp,
      dailyChecklist: dailyChecklist ?? List.from(this.dailyChecklist),
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      xpReward: xpReward ?? this.xpReward,
    );
  }
}

// ============ HIVE ADAPTERS ============

class GoalTypeAdapter extends TypeAdapter<GoalType> {
  @override
  final int typeId = 57;

  @override
  GoalType read(BinaryReader reader) {
    return GoalType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, GoalType obj) {
    writer.writeByte(obj.index);
  }
}

class WeeklyGoalAdapter extends TypeAdapter<WeeklyGoal> {
  @override
  final int typeId = 51;

  @override
  WeeklyGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklyGoal(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String? ?? '',
      weekStartTimestamp: fields[3] as int,
      dailyChecklist: (fields[4] as List).cast<bool>(),
      type: fields[5] as GoalType,
      targetValue: fields[6] as int? ?? 1,
      unit: fields[7] as String? ?? '',
      iconCodePoint: fields[8] as int,
      xpReward: fields[9] as int? ?? 50,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyGoal obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.weekStartTimestamp)
      ..writeByte(4)
      ..write(obj.dailyChecklist)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.targetValue)
      ..writeByte(7)
      ..write(obj.unit)
      ..writeByte(8)
      ..write(obj.iconCodePoint)
      ..writeByte(9)
      ..write(obj.xpReward);
  }
}
