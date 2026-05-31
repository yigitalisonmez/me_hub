// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventCategoryAdapter extends TypeAdapter<EventCategory> {
  @override
  final int typeId = 62;

  @override
  EventCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      iconName: fields[2] as String?,
      colorValue: fields[3] as int,
      isPredefined: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EventCategory obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.iconName)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.isPredefined);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
