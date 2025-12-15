import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/gratitude_entry.dart';

/// Local data source for gratitude journal using Hive
class GratitudeLocalDataSource {
  static const String _boxName = 'gratitude_entries';
  Box<GratitudeEntry>? _box;

  /// Initialize the data source
  Future<void> init() async {
    _box = await Hive.openBox<GratitudeEntry>(_boxName);
  }

  /// Get box (ensure initialized)
  Box<GratitudeEntry> get box {
    if (_box == null) {
      throw Exception(
        'GratitudeLocalDataSource not initialized. Call init() first.',
      );
    }
    return _box!;
  }

  /// Get all entries
  Future<List<GratitudeEntry>> getAllEntries() async {
    return box.values.toList()..sort(
      (a, b) => b.dateTimestamp.compareTo(a.dateTimestamp),
    ); // Newest first
  }

  /// Get entry by ID
  Future<GratitudeEntry?> getEntryById(String id) async {
    return box.get(id);
  }

  /// Get entry by date and type
  Future<GratitudeEntry?> getEntryByDateAndType(
    DateTime date,
    EntryType entryType,
  ) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    try {
      return box.values.firstWhere((entry) {
        final entryDate = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        return entryDate == normalizedDate && entry.entryType == entryType;
      });
    } catch (_) {
      return null;
    }
  }

  /// Get entries in date range
  Future<List<GratitudeEntry>> getEntriesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;

    return box.values
        .where(
          (entry) =>
              entry.dateTimestamp >= startMs && entry.dateTimestamp <= endMs,
        )
        .toList()
      ..sort((a, b) => b.dateTimestamp.compareTo(a.dateTimestamp));
  }

  /// Save entry (add or update)
  Future<GratitudeEntry> saveEntry(GratitudeEntry entry) async {
    await box.put(entry.id, entry);
    return entry;
  }

  /// Delete entry
  Future<void> deleteEntry(String id) async {
    await box.delete(id);
  }

  /// Get random past entry (for positive recall feature)
  Future<GratitudeEntry?> getRandomPastEntry() async {
    final entries = box.values.toList();
    if (entries.isEmpty) return null;

    // Exclude entries from today
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    final pastEntries = entries.where((entry) {
      final entryDate = entry.normalizedDate;
      return entryDate.isBefore(normalizedToday);
    }).toList();

    if (pastEntries.isEmpty) return null;

    // Return random entry
    pastEntries.shuffle();
    return pastEntries.first;
  }

  /// Get total entries count
  Future<int> getTotalCount() async {
    return box.length;
  }

  /// Calculate current streak (consecutive days with entries)
  Future<int> calculateStreak() async {
    final entries = box.values.toList();
    if (entries.isEmpty) return 0;

    // Get unique dates with entries
    final datesWithEntries = <DateTime>{};
    for (final entry in entries) {
      datesWithEntries.add(entry.normalizedDate);
    }

    final sortedDates = datesWithEntries.toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first

    if (sortedDates.isEmpty) return 0;

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final yesterday = normalizedToday.subtract(const Duration(days: 1));

    // Check if there's an entry today or yesterday
    if (!sortedDates.contains(normalizedToday) &&
        !sortedDates.contains(yesterday)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = sortedDates.first;

    for (final date in sortedDates) {
      if (date == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Get emotion tag statistics
  Future<Map<String, int>> getEmotionTagStats() async {
    final stats = <String, int>{};

    for (final entry in box.values) {
      for (final tag in entry.allEmotionTags) {
        stats[tag] = (stats[tag] ?? 0) + 1;
      }
    }

    return stats;
  }
}
