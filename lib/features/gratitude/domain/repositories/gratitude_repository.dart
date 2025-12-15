import '../entities/gratitude_entry.dart';

/// Abstract repository for gratitude operations
abstract class GratitudeRepository {
  /// Get all gratitude entries
  Future<List<GratitudeEntry>> getAllEntries();

  /// Get today's entry (if exists)
  Future<GratitudeEntry?> getTodayEntry({required EntryType entryType});

  /// Get entry by date
  Future<GratitudeEntry?> getEntryByDate(
    DateTime date, {
    required EntryType entryType,
  });

  /// Get entries for date range
  Future<List<GratitudeEntry>> getEntriesInRange(DateTime start, DateTime end);

  /// Add a new gratitude entry
  Future<GratitudeEntry> addEntry(GratitudeEntry entry);

  /// Update an existing entry
  Future<GratitudeEntry> updateEntry(GratitudeEntry entry);

  /// Delete an entry
  Future<void> deleteEntry(String id);

  /// Get a random past entry for "Positive Recall"
  Future<GratitudeEntry?> getRandomPastEntry();

  /// Get total entries count
  Future<int> getTotalEntriesCount();

  /// Get current streak (consecutive days)
  Future<int> getCurrentStreak();

  /// Get most used emotion tags
  Future<Map<String, int>> getEmotionTagStats();

  /// Get entries containing specific emotion tag
  Future<List<GratitudeEntry>> getEntriesByEmotionTag(String tag);
}
