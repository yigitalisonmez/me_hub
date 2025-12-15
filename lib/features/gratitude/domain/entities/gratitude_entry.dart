import 'package:hive_flutter/hive_flutter.dart';
import 'gratitude_item.dart';

part 'gratitude_entry.g.dart';

/// Entry type: morning intention or evening reflection
@HiveType(typeId: 42)
enum EntryType {
  @HiveField(0)
  morning,
  @HiveField(1)
  evening,
}

/// A single gratitude journal entry containing 3-5 items
@HiveType(typeId: 40)
class GratitudeEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int dateTimestamp; // DateTime stored as milliseconds since epoch

  @HiveField(2)
  final List<GratitudeItem> items; // 3-5 gratitude items

  @HiveField(3)
  final EntryType entryType;

  @HiveField(4)
  final String? promptUsed; // Which prompt triggered this entry

  const GratitudeEntry({
    required this.id,
    required this.dateTimestamp,
    required this.items,
    required this.entryType,
    this.promptUsed,
  });

  /// Get DateTime from timestamp
  DateTime get date => DateTime.fromMillisecondsSinceEpoch(dateTimestamp);

  /// Get normalized date (without time)
  DateTime get normalizedDate {
    final d = date;
    return DateTime(d.year, d.month, d.day);
  }

  /// Check if entry is complete (has at least 3 items)
  bool get isComplete => items.length >= 3;

  /// Get all emotion tags from all items
  List<String> get allEmotionTags {
    final tags = <String>[];
    for (final item in items) {
      if (item.emotionTags != null) {
        tags.addAll(item.emotionTags!);
      }
    }
    return tags;
  }

  /// Get the most used emotion tag
  String? get dominantEmotion {
    final tags = allEmotionTags;
    if (tags.isEmpty) return null;

    final counts = <String, int>{};
    for (final tag in tags) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }

    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  GratitudeEntry copyWith({
    String? id,
    DateTime? date,
    int? dateTimestamp,
    List<GratitudeItem>? items,
    EntryType? entryType,
    String? promptUsed,
  }) {
    return GratitudeEntry(
      id: id ?? this.id,
      dateTimestamp:
          dateTimestamp ??
          (date != null ? date.millisecondsSinceEpoch : this.dateTimestamp),
      items: items ?? this.items,
      entryType: entryType ?? this.entryType,
      promptUsed: promptUsed ?? this.promptUsed,
    );
  }
}
