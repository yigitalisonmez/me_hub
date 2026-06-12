import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/mood_entry.dart';

class MoodLocalDataSource {
  static const String _boxName = 'mood_entries';
  static const String _recoveryFlagKey = 'mood_data_recovered';
  Box<MoodEntry>? _box;

  Future<void> init() async {
    try {
      _box = await Hive.openBox<MoodEntry>(_boxName);
    } on HiveError catch (e) {
      // Only handle known Hive schema/format errors, not I/O or permission
      // failures — those should propagate so the caller can surface them.
      debugPrint('mood_entries schema error — recovering: $e');
      await _backupBoxFiles();
      try {
        if (_box != null && _box!.isOpen) await _box!.close();
        await Hive.deleteBoxFromDisk(_boxName);
      } catch (deleteError) {
        debugPrint('Error deleting mood box during recovery: $deleteError');
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_recoveryFlagKey, true);
      } catch (_) {}
      _box = await Hive.openBox<MoodEntry>(_boxName);
    }
  }

  /// Returns true once after a schema-recovery wipe, then clears the flag.
  /// Call from MoodProvider after loading moods to show a one-time warning.
  static Future<bool> checkAndClearRecoveryFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final wasRecovered = prefs.getBool(_recoveryFlagKey) ?? false;
    if (wasRecovered) await prefs.remove(_recoveryFlagKey);
    return wasRecovered;
  }

  Future<void> _backupBoxFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final source = File('${appDir.path}/$_boxName.hive');
      if (!await source.exists()) return;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await source.copy('${appDir.path}/${_boxName}_backup_$timestamp.hive');
      await _pruneOldBackups(appDir);
    } catch (e) {
      debugPrint('mood_entries backup failed (non-fatal): $e');
    }
  }

  Future<void> _pruneOldBackups(Directory appDir) async {
    try {
      final backups = appDir
          .listSync()
          .whereType<File>()
          .where((f) =>
              f.path.contains('${_boxName}_backup_') &&
              f.path.endsWith('.hive'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      for (final file in backups.skip(3)) {
        await file.delete();
      }
    } catch (_) {}
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
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    return allEntries.where((entry) {
      final entryDate = entry.normalizedDate;
      return entryDate.isAfter(
            normalizedStart.subtract(const Duration(days: 1)),
          ) &&
          entryDate.isBefore(normalizedEnd.add(const Duration(days: 1)));
    }).toList();
  }

  /// Generate key from date (YYYY-MM-DD format)
  String _getKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
