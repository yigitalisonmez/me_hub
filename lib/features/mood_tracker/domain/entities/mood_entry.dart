import 'package:hive_flutter/hive_flutter.dart';

part 'mood_entry.g.dart';

@HiveType(typeId: 30)
class MoodEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int dateTimestamp; // DateTime stored as milliseconds since epoch

  @HiveField(2)
  final int score; // Mood score from 1 to 10

  const MoodEntry({
    required this.id,
    required this.dateTimestamp,
    required this.score,
  }) : assert(score >= 1 && score <= 10, 'Score must be between 1 and 10');

  /// Get DateTime from timestamp
  DateTime get date {
    return DateTime.fromMillisecondsSinceEpoch(dateTimestamp);
  }

  MoodEntry copyWith({
    String? id,
    DateTime? date,
    int? dateTimestamp,
    int? score,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      dateTimestamp: dateTimestamp ??
          (date != null ? date.millisecondsSinceEpoch : this.dateTimestamp),
      score: score ?? this.score,
    );
  }

  /// Get normalized date (without time)
  DateTime get normalizedDate {
    final date = this.date;
    return DateTime(date.year, date.month, date.day);
  }
}
