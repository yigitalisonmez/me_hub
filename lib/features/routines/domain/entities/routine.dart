import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 10)
class RoutineItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime? lastCheckedDate; // The last date this item was marked complete

  @HiveField(3)
  final int? iconCodePoint; // Icon code point for Material Icons

  @HiveField(4)
  final int? durationMinutes;

  const RoutineItem({
    required this.id,
    required this.title,
    this.lastCheckedDate,
    this.iconCodePoint,
    this.durationMinutes,
  });

  RoutineItem copyWith({
    String? id,
    String? title,
    DateTime? lastCheckedDate,
    int? iconCodePoint,
    bool clearIconCodePoint = false,
    int? durationMinutes,
    bool clearDurationMinutes = false,
  }) {
    return RoutineItem(
      id: id ?? this.id,
      title: title ?? this.title,
      lastCheckedDate: lastCheckedDate,
      iconCodePoint: clearIconCodePoint
          ? null
          : (iconCodePoint ?? this.iconCodePoint),
      durationMinutes: clearDurationMinutes
          ? null
          : (durationMinutes ?? this.durationMinutes),
    );
  }

  bool isCheckedToday(DateTime today) {
    if (lastCheckedDate == null) return false;
    return lastCheckedDate!.year == today.year &&
        lastCheckedDate!.month == today.month &&
        lastCheckedDate!.day == today.day;
  }
}

@HiveType(typeId: 11)
class Routine {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<RoutineItem> items;

  @HiveField(3)
  final int streakCount;

  @HiveField(4)
  final DateTime? lastStreakDate;

  @HiveField(5)
  final int? iconCodePoint; // Icon code point for the routine

  @HiveField(6)
  final int? timeHour; // Hour of the routine time (0-23)

  @HiveField(7)
  final int? timeMinute; // Minute of the routine time (0-59)

  @HiveField(8)
  final List<int>? selectedDays; // Days of week (0=Monday, 6=Sunday)

  @HiveField(9)
  final bool reminderEnabled;

  @HiveField(10)
  final int reminderMinutesBefore;

  const Routine({
    required this.id,
    required this.name,
    required this.items,
    this.streakCount = 0,
    this.lastStreakDate,
    this.iconCodePoint,
    this.timeHour,
    this.timeMinute,
    this.selectedDays,
    bool? reminderEnabled,
    this.reminderMinutesBefore = 5,
  }) : reminderEnabled =
           reminderEnabled ?? (timeHour != null && timeMinute != null);

  Routine copyWith({
    String? id,
    String? name,
    List<RoutineItem>? items,
    int? streakCount,
    DateTime? lastStreakDate,
    bool clearLastStreakDate = false,
    int? iconCodePoint,
    bool clearIconCodePoint = false,
    int? timeHour,
    int? timeMinute,
    bool clearTime = false,
    List<int>? selectedDays,
    bool clearSelectedDays = false,
    bool? reminderEnabled,
    int? reminderMinutesBefore,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      streakCount: streakCount ?? this.streakCount,
      lastStreakDate: clearLastStreakDate
          ? null
          : (lastStreakDate ?? this.lastStreakDate),
      iconCodePoint: clearIconCodePoint
          ? null
          : (iconCodePoint ?? this.iconCodePoint),
      timeHour: clearTime ? null : (timeHour ?? this.timeHour),
      timeMinute: clearTime ? null : (timeMinute ?? this.timeMinute),
      selectedDays: clearSelectedDays
          ? null
          : (selectedDays ?? this.selectedDays),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }

  /// Get TimeOfDay from stored hour and minute
  TimeOfDay? get time {
    if (timeHour == null || timeMinute == null) return null;
    return TimeOfDay(hour: timeHour!, minute: timeMinute!);
  }

  /// Check if routine is active on a specific weekday
  /// weekday: 0=Monday, 6=Sunday
  bool isActiveOnDay(int weekday) {
    if (selectedDays == null || selectedDays!.isEmpty) {
      // If no days selected, routine is active on all days (backward compatibility)
      return true;
    }
    return selectedDays!.contains(weekday);
  }

  bool allItemsCheckedToday(DateTime today) {
    if (items.isEmpty) return false;
    return items.every((i) => i.isCheckedToday(today));
  }

  int computeNextStreak(DateTime today) {
    if (lastStreakDate == null) return 1;
    final yesterday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 1));
    final last = DateTime(
      lastStreakDate!.year,
      lastStreakDate!.month,
      lastStreakDate!.day,
    );
    if (last == yesterday) return streakCount + 1; // consecutive
    if (last == DateTime(today.year, today.month, today.day)) {
      return streakCount; // already counted today
    }
    return 1; // reset streak
  }
}

class RoutineItemAdapter extends TypeAdapter<RoutineItem> {
  @override
  final int typeId = 10;

  @override
  RoutineItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoutineItem(
      id: fields[0] as String,
      title: fields[1] as String,
      lastCheckedDate: fields[2] as DateTime?,
      iconCodePoint: fields[3] as int?,
      durationMinutes: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, RoutineItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.lastCheckedDate)
      ..writeByte(3)
      ..write(obj.iconCodePoint)
      ..writeByte(4)
      ..write(obj.durationMinutes);
  }
}

class RoutineAdapter extends TypeAdapter<Routine> {
  @override
  final int typeId = 11;

  @override
  Routine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Routine(
      id: fields[0] as String,
      name: fields[1] as String,
      items: (fields[2] as List).cast<RoutineItem>(),
      streakCount: fields[3] as int,
      lastStreakDate: fields[4] as DateTime?,
      iconCodePoint: fields[5] as int?,
      timeHour: fields[6] as int?,
      timeMinute: fields[7] as int?,
      selectedDays: fields[8] as List<int>?,
      reminderEnabled: fields[9] as bool?,
      reminderMinutesBefore: fields[10] as int? ?? 5,
    );
  }

  @override
  void write(BinaryWriter writer, Routine obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.streakCount)
      ..writeByte(4)
      ..write(obj.lastStreakDate)
      ..writeByte(5)
      ..write(obj.iconCodePoint)
      ..writeByte(6)
      ..write(obj.timeHour)
      ..writeByte(7)
      ..write(obj.timeMinute)
      ..writeByte(8)
      ..write(obj.selectedDays)
      ..writeByte(9)
      ..write(obj.reminderEnabled)
      ..writeByte(10)
      ..write(obj.reminderMinutesBefore);
  }
}
