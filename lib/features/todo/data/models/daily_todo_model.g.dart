// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_todo_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyTodoModelAdapter extends TypeAdapter<DailyTodoModel> {
  @override
  final int typeId = 1;

  @override
  DailyTodoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyTodoModel(
      id: fields[0] as String,
      title: fields[1] as String,
      isCompleted: fields[2] as bool,
      createdAt: fields[3] as DateTime,
      completedAt: fields[4] as DateTime?,
      date: fields[5] as DateTime,
      priority: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailyTodoModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.isCompleted)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.completedAt)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.priority);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyTodoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
