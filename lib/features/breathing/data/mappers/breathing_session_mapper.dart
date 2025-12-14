import '../../domain/entities/breathing_session.dart';

/// Mapper for converting between domain entity and JSON for persistence
class BreathingSessionMapper {
  /// Convert domain entity to JSON
  static Map<String, dynamic> toJson(BreathingSession session) {
    return {
      'id': session.id,
      'startedAt': session.startedAt.toIso8601String(),
      'completedAt': session.completedAt?.toIso8601String(),
      'techniqueId': session.techniqueId,
      'techniqueName': session.techniqueName,
      'targetDurationMinutes': session.targetDurationMinutes,
      'actualDurationSeconds': session.actualDurationSeconds,
      'moodBefore': session.moodBefore,
      'moodAfter': session.moodAfter,
      'cyclesCompleted': session.cyclesCompleted,
    };
  }

  /// Create domain entity from JSON
  static BreathingSession fromJson(Map<String, dynamic> json) {
    return BreathingSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      techniqueId: json['techniqueId'] as String,
      techniqueName: json['techniqueName'] as String,
      targetDurationMinutes: json['targetDurationMinutes'] as int,
      actualDurationSeconds: json['actualDurationSeconds'] as int,
      moodBefore: json['moodBefore'] as int?,
      moodAfter: json['moodAfter'] as int?,
      cyclesCompleted: json['cyclesCompleted'] as int,
    );
  }
}
