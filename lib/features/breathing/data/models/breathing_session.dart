/// Represents a completed breathing session for tracking and statistics
class BreathingSession {
  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String techniqueId;
  final String techniqueName;
  final int targetDurationMinutes;
  final int actualDurationSeconds;
  final int? moodBefore; // 1-5 scale
  final int? moodAfter; // 1-5 scale
  final int cyclesCompleted;

  const BreathingSession({
    required this.id,
    required this.startedAt,
    this.completedAt,
    required this.techniqueId,
    required this.techniqueName,
    required this.targetDurationMinutes,
    required this.actualDurationSeconds,
    this.moodBefore,
    this.moodAfter,
    required this.cyclesCompleted,
  });

  /// Calculate mood improvement percentage
  int? get moodImprovementPercent {
    if (moodBefore == null || moodAfter == null) return null;
    if (moodBefore == moodAfter) return 0;

    // Calculate improvement on a 1-5 scale
    final improvement = moodAfter! - moodBefore!;
    // Convert to percentage (each point is 25% on a 4-point improvement scale)
    return (improvement * 25).clamp(-100, 100).round();
  }

  /// Check if session was completed
  bool get isCompleted => completedAt != null;

  /// Get formatted duration string
  String get formattedDuration {
    final minutes = actualDurationSeconds ~/ 60;
    final seconds = actualDurationSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'techniqueId': techniqueId,
      'techniqueName': techniqueName,
      'targetDurationMinutes': targetDurationMinutes,
      'actualDurationSeconds': actualDurationSeconds,
      'moodBefore': moodBefore,
      'moodAfter': moodAfter,
      'cyclesCompleted': cyclesCompleted,
    };
  }

  /// Create from JSON
  factory BreathingSession.fromJson(Map<String, dynamic> json) {
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

  /// Create a copy with updated fields
  BreathingSession copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? completedAt,
    String? techniqueId,
    String? techniqueName,
    int? targetDurationMinutes,
    int? actualDurationSeconds,
    int? moodBefore,
    int? moodAfter,
    int? cyclesCompleted,
  }) {
    return BreathingSession(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      techniqueId: techniqueId ?? this.techniqueId,
      techniqueName: techniqueName ?? this.techniqueName,
      targetDurationMinutes:
          targetDurationMinutes ?? this.targetDurationMinutes,
      actualDurationSeconds:
          actualDurationSeconds ?? this.actualDurationSeconds,
      moodBefore: moodBefore ?? this.moodBefore,
      moodAfter: moodAfter ?? this.moodAfter,
      cyclesCompleted: cyclesCompleted ?? this.cyclesCompleted,
    );
  }
}
