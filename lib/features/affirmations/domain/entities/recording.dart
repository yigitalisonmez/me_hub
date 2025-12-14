import 'package:intl/intl.dart';

/// Represents a single recorded affirmation (max 1 minute, max 3 per user)
/// Domain entity with business logic
class SavedRecording {
  final String id;
  final String name;
  final String filePath;
  final int durationSeconds; // max 60

  const SavedRecording({
    required this.id,
    required this.name,
    required this.filePath,
    required this.durationSeconds,
  });

  /// Formatted duration string
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}

/// Represents a completed session log entry
class SessionLog {
  final String id;
  final DateTime completedAt;
  final int durationMinutes;
  final String? recordingName;

  const SessionLog({
    required this.id,
    required this.completedAt,
    required this.durationMinutes,
    this.recordingName,
  });

  /// Formatted date with relative time
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
}
