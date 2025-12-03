import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/mood_entry.dart';

class MoodLocalDataSource {
  static const String _boxName = 'mood_entries';
  Box<MoodEntry>? _box;

  /// Initialize Hive box
  Future<void> init() async {
    try {
      _box = await Hive.openBox<MoodEntry>(_boxName);
    } catch (e) {
      // If there's a format error (old data format), delete the box and recreate it
      try {
        // Close the box if it's open
        if (_box != null && _box!.isOpen) {
          await _box!.close();
        }
        // Delete the box files
        await Hive.deleteBoxFromDisk(_boxName);
      } catch (deleteError) {
        // Ignore delete errors (file might not exist)
        debugPrint('Error deleting old mood box: $deleteError');
      }
      // Recreate the box
      _box = await Hive.openBox<MoodEntry>(_boxName);
    }
  }

  /// Get mood entry for a specific date
  Future<MoodEntry?> getMoodEntry(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final key = _getKey(normalizedDate);
    return _box?.get(key);
  }

  /// Get today's mood entry
  Future<MoodEntry?> getTodayMood() async {
    final today = DateTime.now();
    return await getMoodEntry(today);
  }

  /// Save or update mood entry
  Future<void> saveMoodEntry(MoodEntry moodEntry) async {
    final normalizedDate = DateTime(
      moodEntry.date.year,
      moodEntry.date.month,
      moodEntry.date.day,
    );
    final key = _getKey(normalizedDate);
    await _box?.put(key, moodEntry);
  }

  /// Delete mood entry for a specific date
  Future<void> deleteMoodEntry(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final key = _getKey(normalizedDate);
    await _box?.delete(key);
  }

  /// Get all mood entries (for heatmap)
  Future<List<MoodEntry>> getAllMoodEntries() async {
    return _box?.values.toList() ?? [];
  }

  /// Get mood entries for date range
  Future<List<MoodEntry>> getMoodEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allEntries = await getAllMoodEntries();
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    return allEntries.where((entry) {
      final entryDate = entry.normalizedDate;
      return entryDate.isAfter(normalizedStart.subtract(const Duration(days: 1))) &&
          entryDate.isBefore(normalizedEnd.add(const Duration(days: 1)));
    }).toList();
  }

  /// Generate key from date (YYYY-MM-DD format)
  String _getKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

