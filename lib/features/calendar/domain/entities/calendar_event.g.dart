// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalendarEventAdapter extends TypeAdapter<CalendarEvent> {
  @override
  final int typeId = 60;

  @override
  CalendarEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalendarEvent(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      dateTime: fields[3] as DateTime,
      reminderOffset: fields[4] as HiveReminderOffset,
      isCompleted: fields[5] as bool,
      createdAt: fields[6] as DateTime,
      hasReminder: fields[7] as bool,
      categoryId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CalendarEvent obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dateTime)
      ..writeByte(4)
      ..write(obj.reminderOffset)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.hasReminder)
      ..writeByte(8)
      ..write(obj.categoryId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveReminderOffsetAdapter extends TypeAdapter<HiveReminderOffset> {
  @override
  final int typeId = 61;

  @override
  HiveReminderOffset read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HiveReminderOffset.fiveMinutes;
      case 1:
        return HiveReminderOffset.fifteenMinutes;
      case 2:
        return HiveReminderOffset.thirtyMinutes;
      case 3:
        return HiveReminderOffset.oneHour;
      case 4:
        return HiveReminderOffset.threeHours;
      case 5:
        return HiveReminderOffset.twelveHours;
      case 6:
        return HiveReminderOffset.oneDay;
      default:
        return HiveReminderOffset.fiveMinutes;
    }
  }

  @override
  void write(BinaryWriter writer, HiveReminderOffset obj) {
    switch (obj) {
      case HiveReminderOffset.fiveMinutes:
        writer.writeByte(0);
        break;
      case HiveReminderOffset.fifteenMinutes:
        writer.writeByte(1);
        break;
      case HiveReminderOffset.thirtyMinutes:
        writer.writeByte(2);
        break;
      case HiveReminderOffset.oneHour:
        writer.writeByte(3);
        break;
      case HiveReminderOffset.threeHours:
        writer.writeByte(4);
        break;
      case HiveReminderOffset.twelveHours:
        writer.writeByte(5);
        break;
      case HiveReminderOffset.oneDay:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveReminderOffsetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
