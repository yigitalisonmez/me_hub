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

  Future<void> saveMood({
    required int score,
    String? note,
    DateTime? date,
  }) async {
    try {
      if (score < 1 || score > 10) {
        throw ArgumentError('Score must be between 1 and 10');
      }

      final targetDate = date ?? DateTime.now();
      final moodEntry = MoodEntry(
        id: targetDate.microsecondsSinceEpoch.toString(),
        dateTimestamp: targetDate.millisecondsSinceEpoch,
        score: score,
        note: note,
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

  /// Delete mood entry for a specific date
  Future<void> deleteMood(DateTime date) async {
    try {
      await _dataSource.deleteMoodEntry(date);
      
      // If deleting today's mood, update _todayMood
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        _todayMood = null;
      }
      
      await loadAllMoods();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting mood: $e');
      rethrow;
    }
  }

  /// Delete today's mood
  Future<void> deleteTodayMood() async {
    await deleteMood(DateTime.now());
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
