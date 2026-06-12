import 'package:flutter/foundation.dart';
import '../../domain/entities/gratitude_entry.dart';
import '../../domain/entities/gratitude_item.dart';
import '../../domain/entities/gratitude_prompt.dart';
import '../../domain/usecases/usecases.dart';
import '../../../../core/reminders/domain/reminder_feature.dart';
import '../../../../core/reminders/services/reminder_coordinator.dart';

/// State management for gratitude journaling
class GratitudeProvider with ChangeNotifier {
  final AddGratitudeEntry _addEntry;
  final GetTodayGratitudeEntry _getTodayEntry;
  final GetAllGratitudeEntries _getAllEntries;
  final GetRandomPastGratitudeEntry _getRandomPastEntry;
  final UpdateGratitudeEntry _updateEntry;
  final DeleteGratitudeEntry _deleteEntry;
  final GetGratitudeStreak _getStreak;
  final GetEmotionTagStats _getEmotionTagStats;
  final ReminderCoordinator? _reminders;

  GratitudeProvider({
    required AddGratitudeEntry addEntry,
    required GetTodayGratitudeEntry getTodayEntry,
    required GetAllGratitudeEntries getAllEntries,
    required GetRandomPastGratitudeEntry getRandomPastEntry,
    required UpdateGratitudeEntry updateEntry,
    required DeleteGratitudeEntry deleteEntry,
    required GetGratitudeStreak getStreak,
    required GetEmotionTagStats getEmotionTagStats,
    ReminderCoordinator? reminders,
  }) : _addEntry = addEntry,
       _getTodayEntry = getTodayEntry,
       _getAllEntries = getAllEntries,
       _getRandomPastEntry = getRandomPastEntry,
       _updateEntry = updateEntry,
       _deleteEntry = deleteEntry,
       _getStreak = getStreak,
       _getEmotionTagStats = getEmotionTagStats,
       _reminders = reminders;

  // State
  List<GratitudeEntry> _entries = [];
  GratitudeEntry? _todayMorningEntry;
  GratitudeEntry? _todayEveningEntry;
  GratitudeEntry? _randomPastEntry;
  int _currentStreak = 0;
  Map<String, int> _emotionTagStats = {};
  GratitudePrompt _currentPrompt = GratitudePrompt.getRandomPrompt();
  bool _isLoading = false;
  String? _error;
  final List<String> _recentPromptIds = [];

  // Getters
  List<GratitudeEntry> get entries => _entries;
  GratitudeEntry? get todayMorningEntry => _todayMorningEntry;
  GratitudeEntry? get todayEveningEntry => _todayEveningEntry;
  GratitudeEntry? get randomPastEntry => _randomPastEntry;
  int get currentStreak => _currentStreak;
  Map<String, int> get emotionTagStats => _emotionTagStats;
  GratitudePrompt get currentPrompt => _currentPrompt;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Check if today's morning entry is complete
  bool get hasTodayMorningEntry =>
      _todayMorningEntry != null && _todayMorningEntry!.isComplete;

  /// Check if today's evening entry is complete
  bool get hasTodayEveningEntry =>
      _todayEveningEntry != null && _todayEveningEntry!.isComplete;

  /// Get total entries count
  int get totalEntriesCount => _entries.length;

  /// Get the most used emotion tag
  String? get topEmotionTag {
    if (_emotionTagStats.isEmpty) return null;
    return _emotionTagStats.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Load all data
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadEntries(),
        _loadTodayEntries(),
        _loadStreak(),
        _loadEmotionStats(),
        _loadRandomPastEntry(),
      ]);
      await _reconcileReminders();
    } catch (e) {
      _error = 'Failed to load gratitude data';
      debugPrint('GratitudeProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadEntries() async {
    _entries = await _getAllEntries();
  }

  Future<void> _loadTodayEntries() async {
    _todayMorningEntry = await _getTodayEntry(entryType: EntryType.morning);
    _todayEveningEntry = await _getTodayEntry(entryType: EntryType.evening);
  }

  Future<void> _loadStreak() async {
    _currentStreak = await _getStreak();
  }

  Future<void> _loadEmotionStats() async {
    _emotionTagStats = await _getEmotionTagStats();
  }

  Future<void> _loadRandomPastEntry() async {
    _randomPastEntry = await _getRandomPastEntry();
  }

  /// Refresh random past entry (for "Positive Recall" feature)
  Future<void> refreshRandomPastEntry() async {
    _randomPastEntry = await _getRandomPastEntry();
    notifyListeners();
  }

  /// Get a new diversified prompt
  void refreshPrompt() {
    // Track recent prompts to avoid repetition
    if (_recentPromptIds.length > 5) {
      _recentPromptIds.removeAt(0);
    }
    _recentPromptIds.add(_currentPrompt.id);

    _currentPrompt = GratitudePrompt.getNovelPrompt(_recentPromptIds);
    notifyListeners();
  }

  /// Get prompt by category
  void setPromptByCategory(PromptCategory category) {
    _currentPrompt = GratitudePrompt.getRandomPromptByCategory(category);
    notifyListeners();
  }

  /// Add a new gratitude entry
  Future<bool> addEntry({
    required List<GratitudeItem> items,
    required EntryType entryType,
  }) async {
    if (items.length < 3 || items.length > 5) {
      _error = 'Please add 3-5 gratitude items';
      notifyListeners();
      return false;
    }

    try {
      final entry = GratitudeEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        dateTimestamp: DateTime.now().millisecondsSinceEpoch,
        items: items,
        entryType: entryType,
        promptUsed: _currentPrompt.id,
      );

      final savedEntry = await _addEntry(entry);
      _entries.insert(0, savedEntry);

      // Update today's entry
      if (entryType == EntryType.morning) {
        _todayMorningEntry = savedEntry;
      } else {
        _todayEveningEntry = savedEntry;
      }

      // Refresh streak and stats
      await _loadStreak();
      await _loadEmotionStats();

      notifyListeners();
      await _reconcileReminders();
      return true;
    } catch (e) {
      _error = 'Failed to save gratitude entry';
      notifyListeners();
      return false;
    }
  }

  /// Update an existing entry
  Future<bool> updateEntry(GratitudeEntry entry) async {
    try {
      final updatedEntry = await _updateEntry(entry);

      final index = _entries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _entries[index] = updatedEntry;
      }

      // Update today's entry if applicable
      if (updatedEntry.entryType == EntryType.morning) {
        _todayMorningEntry = updatedEntry;
      } else {
        _todayEveningEntry = updatedEntry;
      }

      await _loadEmotionStats();
      notifyListeners();
      await _reconcileReminders();
      return true;
    } catch (e) {
      _error = 'Failed to update entry';
      notifyListeners();
      return false;
    }
  }

  /// Delete an entry
  Future<bool> deleteEntry(String id) async {
    try {
      await _deleteEntry(id);
      _entries.removeWhere((e) => e.id == id);

      // Clear today's entry if deleted
      if (_todayMorningEntry?.id == id) {
        _todayMorningEntry = null;
      }
      if (_todayEveningEntry?.id == id) {
        _todayEveningEntry = null;
      }

      await _loadStreak();
      await _loadEmotionStats();
      notifyListeners();
      await _reconcileReminders();
      return true;
    } catch (e) {
      _error = 'Failed to delete entry';
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _reconcileReminders() async {
    await _reminders?.reconcileDailyFeature(
      feature: ReminderFeature.gratitudeMorning,
      completedToday: hasTodayMorningEntry,
      actionable: true,
      title: 'Morning gratitude',
      body: 'Begin today by naming three things you appreciate.',
      payload: 'kora://gratitude',
    );
    await _reminders?.reconcileDailyFeature(
      feature: ReminderFeature.gratitudeEvening,
      completedToday: hasTodayEveningEntry,
      actionable: true,
      title: 'Evening gratitude',
      body: 'Close the day with a short reflection.',
      payload: 'kora://gratitude',
    );
  }
}
