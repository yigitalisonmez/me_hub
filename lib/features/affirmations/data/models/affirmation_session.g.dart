// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'affirmation_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AffirmationSessionAdapter extends TypeAdapter<AffirmationSession> {
  @override
  final int typeId = 10;

  @override
  AffirmationSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AffirmationSession(
      id: fields[0] as String,
      name: fields[1] as String,
      recordingPath: fields[2] as String,
      selectedBackgroundId: fields[3] as String?,
      backgroundVolume: fields[4] as double,
      voiceVolume: fields[5] as double,
      createdAt: fields[6] as DateTime,
      loopDurationMinutes: fields[7] as int,
      completedSessions: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AffirmationSession obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.recordingPath)
      ..writeByte(3)
      ..write(obj.selectedBackgroundId)
      ..writeByte(4)
      ..write(obj.backgroundVolume)
      ..writeByte(5)
      ..write(obj.voiceVolume)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.loopDurationMinutes)
      ..writeByte(8)
      ..write(obj.completedSessions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AffirmationSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
