import 'package:flutter/foundation.dart';
import '../../domain/entities/mood_entry.dart';
import '../../data/datasources/mood_local_datasource.dart';

class MoodProvider with ChangeNotifier {
  final MoodLocalDataSource _dataSource;

  MoodProvider(this._dataSource);

  MoodEntry? _todayMood;
  List<MoodEntry> _allMoods = [];
  bool _isLoading = false;

  MoodEntry? get todayMood => _todayMood;
  List<MoodEntry> get allMoods => _allMoods;
  bool get isLoading => _isLoading;
  bool get hasTodayMood => _todayMood != null;

  /// Load today's mood
  Future<void> loadTodayMood() async {
    _isLoading = true;
    notifyListeners();

    try {
      _todayMood = await _dataSource.getTodayMood();
    } catch (e) {
      debugPrint('Error loading today mood: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all moods (for heatmap)
  Future<void> loadAllMoods() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allMoods = await _dataSource.getAllMoodEntries();
    } catch (e) {
      debugPrint('Error loading all moods: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save mood entry
  Future<void> saveMood({
    required int score,
  }) async {
    try {
      if (score < 1 || score > 10) {
        throw ArgumentError('Score must be between 1 and 10');
      }

      final now = DateTime.now();
      final moodEntry = MoodEntry(
        id: now.microsecondsSinceEpoch.toString(),
        dateTimestamp: now.millisecondsSinceEpoch,
        score: score,
      );

      await _dataSource.saveMoodEntry(moodEntry);
      _todayMood = moodEntry;

      // Reload all moods to update heatmap
      await loadAllMoods();
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving mood: $e');
      rethrow;
    }
  }

  /// Delete today's mood
  Future<void> deleteTodayMood() async {
    try {
      final today = DateTime.now();
      await _dataSource.deleteMoodEntry(today);
      _todayMood = null;
      await loadAllMoods();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting today mood: $e');
      rethrow;
    }
  }

  /// Get mood entry for a specific date
  MoodEntry? getMoodForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    try {
      return _allMoods.firstWhere(
        (entry) => entry.normalizedDate == normalizedDate,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if mood exists for a specific date
  bool hasMoodForDate(DateTime date) {
    return getMoodForDate(date) != null;
  }
}
