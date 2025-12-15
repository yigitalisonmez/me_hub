// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gratitude_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GratitudeItemAdapter extends TypeAdapter<GratitudeItem> {
  @override
  final int typeId = 41;

  @override
  GratitudeItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GratitudeItem(
      id: fields[0] as String,
      content: fields[1] as String,
      whyContent: fields[2] as String?,
      feelingContent: fields[3] as String?,
      emotionTags: (fields[4] as List?)?.cast<String>(),
      voiceRecordingPath: fields[5] as String?,
      createdAtTimestamp: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, GratitudeItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.whyContent)
      ..writeByte(3)
      ..write(obj.feelingContent)
      ..writeByte(4)
      ..write(obj.emotionTags)
      ..writeByte(5)
      ..write(obj.voiceRecordingPath)
      ..writeByte(6)
      ..write(obj.createdAtTimestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GratitudeItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
