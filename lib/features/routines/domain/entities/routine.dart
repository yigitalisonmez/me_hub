import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 10)
class RoutineItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime? lastCheckedDate; // The last date this item was marked complete

  const RoutineItem({
    required this.id,
    required this.title,
    this.lastCheckedDate,
  });

  RoutineItem copyWith({String? id, String? title, DateTime? lastCheckedDate}) {
    return RoutineItem(
      id: id ?? this.id,
      title: title ?? this.title,
      lastCheckedDate: lastCheckedDate,
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

  const Routine({
    required this.id,
    required this.name,
    required this.items,
    this.streakCount = 0,
    this.lastStreakDate,
  });

  Routine copyWith({
    String? id,
    String? name,
    List<RoutineItem>? items,
    int? streakCount,
    DateTime? lastStreakDate,
    bool clearLastStreakDate = false,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      streakCount: streakCount ?? this.streakCount,
      lastStreakDate: clearLastStreakDate
          ? null
          : (lastStreakDate ?? this.lastStreakDate),
    );
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
    if (last == DateTime(today.year, today.month, today.day))
      return streakCount; // already counted today
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
    );
  }

  @override
  void write(BinaryWriter writer, RoutineItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.lastCheckedDate);
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
    );
  }

  @override
  void write(BinaryWriter writer, Routine obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.streakCount)
      ..writeByte(4)
      ..write(obj.lastStreakDate);
  }
}
