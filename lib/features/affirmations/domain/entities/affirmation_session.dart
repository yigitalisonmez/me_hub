/// Represents a saved affirmation session/recording configuration
/// Pure domain entity without Hive dependencies
class AffirmationSession {
  final String id;
  final String name;
  final String recordingPath;
  final String? selectedBackgroundId;
  final double backgroundVolume;
  final double voiceVolume;
  final DateTime createdAt;
  final int loopDurationMinutes;
  final int completedSessions;

  const AffirmationSession({
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
