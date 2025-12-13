import 'package:hive/hive.dart';

part 'affirmation_session.g.dart';

/// Represents a saved affirmation recording session
@HiveType(typeId: 10)
class AffirmationSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String recordingPath;

  @HiveField(3)
  final String? selectedBackgroundId;

  @HiveField(4)
  final double backgroundVolume;

  @HiveField(5)
  final double voiceVolume;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final int loopDurationMinutes;

  @HiveField(8)
  final int completedSessions;

  AffirmationSession({
    required this.id,
    required this.name,
    required this.recordingPath,
    this.selectedBackgroundId,
    this.backgroundVolume = 0.5,
    this.voiceVolume = 1.0,
    required this.createdAt,
    this.loopDurationMinutes = 30,
    this.completedSessions = 0,
  });

  AffirmationSession copyWith({
    String? id,
    String? name,
    String? recordingPath,
    String? selectedBackgroundId,
    double? backgroundVolume,
    double? voiceVolume,
    DateTime? createdAt,
    int? loopDurationMinutes,
    int? completedSessions,
  }) {
    return AffirmationSession(
      id: id ?? this.id,
      name: name ?? this.name,
      recordingPath: recordingPath ?? this.recordingPath,
      selectedBackgroundId: selectedBackgroundId ?? this.selectedBackgroundId,
      backgroundVolume: backgroundVolume ?? this.backgroundVolume,
      voiceVolume: voiceVolume ?? this.voiceVolume,
      createdAt: createdAt ?? this.createdAt,
      loopDurationMinutes: loopDurationMinutes ?? this.loopDurationMinutes,
      completedSessions: completedSessions ?? this.completedSessions,
    );
  }
}
