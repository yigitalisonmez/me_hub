// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gratitude_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GratitudeEntryAdapter extends TypeAdapter<GratitudeEntry> {
  @override
  final int typeId = 40;

  @override
  GratitudeEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GratitudeEntry(
      id: fields[0] as String,
      dateTimestamp: fields[1] as int,
      items: (fields[2] as List).cast<GratitudeItem>(),
      entryType: fields[3] as EntryType,
      promptUsed: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GratitudeEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dateTimestamp)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.entryType)
      ..writeByte(4)
      ..write(obj.promptUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GratitudeEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EntryTypeAdapter extends TypeAdapter<EntryType> {
  @override
  final int typeId = 42;

  @override
  EntryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EntryType.morning;
      case 1:
        return EntryType.evening;
      default:
        return EntryType.morning;
    }
  }

  @override
  void write(BinaryWriter writer, EntryType obj) {
    switch (obj) {
      case EntryType.morning:
        writer.writeByte(0);
        break;
      case EntryType.evening:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
