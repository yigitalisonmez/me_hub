import 'package:intl/intl.dart';

/// Represents a single recorded affirmation (max 1 minute, max 3 per user)
class SavedRecording {
  final String id;
  final String name;
  final String filePath;
  final int durationSeconds; // max 60

  SavedRecording({
    required this.id,
    required this.name,
    required this.filePath,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'filePath': filePath,
    'durationSeconds': durationSeconds,
  };

  factory SavedRecording.fromJson(Map<String, dynamic> json) => SavedRecording(
    id: json['id'] as String,
    name: json['name'] as String,
    filePath: json['filePath'] as String,
    durationSeconds: json['durationSeconds'] as int,
  );
}

/// Represents a completed session log entry
class SessionLog {
  final String id;
  final DateTime completedAt;
  final int durationMinutes;
  final String? recordingName;

  SessionLog({
    required this.id,
    required this.completedAt,
    required this.durationMinutes,
    this.recordingName,
  });

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(completedAt);

    if (diff.inDays == 0) {
      return 'Today at ${DateFormat.jm().format(completedAt)}';
    } else if (diff.inDays == 1) {
      return 'Yesterday at ${DateFormat.jm().format(completedAt)}';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(completedAt);
    } else {
      return DateFormat('MMM d').format(completedAt);
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'completedAt': completedAt.toIso8601String(),
    'durationMinutes': durationMinutes,
    'recordingName': recordingName,
  };

  factory SessionLog.fromJson(Map<String, dynamic> json) => SessionLog(
    id: json['id'] as String,
    completedAt: DateTime.parse(json['completedAt'] as String),
    durationMinutes: json['durationMinutes'] as int,
    recordingName: json['recordingName'] as String?,
  );
}
