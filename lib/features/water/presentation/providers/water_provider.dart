import 'package:flutter/foundation.dart';
import '../../domain/entities/water_intake.dart';
import '../../domain/usecases/usecases.dart';

class WaterProvider with ChangeNotifier {
  final GetTodayWaterIntake _getTodayWaterIntake;
  final AddWater _addWater;
  final RemoveLastLog _removeLastLog;
  final GetWaterHistory _getWaterHistory;
  final UpdateWaterIntake _updateWaterIntake;

  WaterProvider({
    required GetTodayWaterIntake getTodayWaterIntake,
    required AddWater addWater,
    required RemoveLastLog removeLastLog,
    required GetWaterHistory getWaterHistory,
    required UpdateWaterIntake updateWaterIntake,
  }) : _getTodayWaterIntake = getTodayWaterIntake,
       _addWater = addWater,
       _removeLastLog = removeLastLog,
       _getWaterHistory = getWaterHistory,
       _updateWaterIntake = updateWaterIntake;

  WaterIntake? _todayIntake;
  List<WaterIntake> _history = [];
  bool _isLoading = false;
  String? _error;
  bool _justReachedGoal = false;
  int _dailyGoalMl = 2000; // Default goal

  WaterIntake? get todayIntake => _todayIntake;
  List<WaterIntake> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get today's water intake amount
  int get todayAmount => _todayIntake?.amountMl ?? 0;

  /// Get today's progress (0.0 to 1.0)
  double get todayProgress => _todayIntake?.getProgress(dailyGoalMl: _dailyGoalMl) ?? 0.0;

  /// Check if today's goal is reached
  bool get isGoalReached => _todayIntake?.isGoalReached(dailyGoalMl: _dailyGoalMl) ?? false;

  /// Set daily goal (called from WaterPage)
  void setDailyGoal(int dailyGoalMl) {
    _dailyGoalMl = dailyGoalMl;
    notifyListeners();
  }

  /// Check if goal was just reached (for celebration)
  bool get justReachedGoal {
    final result = _justReachedGoal;
    _justReachedGoal = false; // Reset after reading
    return result;
  }

  /// Load today's water intake
  Future<void> loadTodayWaterIntake() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todayIntake = await _getTodayWaterIntake();
    } catch (e) {
      _error = 'Failed to load water intake';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add water amount
  Future<void> addWaterAmount(int amountMl) async {
    try {
      final wasGoalReached = isGoalReached;
      await _addWater(DateTime.now(), amountMl);
      await loadTodayWaterIntake();

      // Check if goal was just reached
      if (!wasGoalReached && isGoalReached) {
        _justReachedGoal = true;
        notifyListeners(); // Notify to trigger celebration in UI
      }
    } catch (e) {
      _error = 'Failed to add water';
      notifyListeners();
    }
  }

  /// Remove last water log (undo)
  Future<void> undoLastLog() async {
    if (_todayIntake == null || _todayIntake!.logs.isEmpty) return;

    try {
      await _removeLastLog(DateTime.now());
      await loadTodayWaterIntake();
    } catch (e) {
      _error = 'Failed to undo';
      notifyListeners();
    }
  }

  /// Load water history
  Future<void> loadHistory({int days = 7}) async {
    try {
      _history = await _getWaterHistory(days);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load history';
      notifyListeners();
    }
  }

  /// Update water intake (for deleting specific logs)
  Future<void> updateWaterIntake(WaterIntake waterIntake) async {
    try {
      await _updateWaterIntake(waterIntake);
      await loadTodayWaterIntake();
    } catch (e) {
      _error = 'Failed to update water intake';
      notifyListeners();
    }
  }

  /// Delete a specific water log
  Future<void> deleteLog(String logId) async {
    final todayIntake = _todayIntake;
    if (todayIntake == null) return;

    // If it's the last log, use undoLastLog for consistency
    if (todayIntake.logs.isNotEmpty && todayIntake.logs.last.id == logId) {
      await undoLastLog();
      return;
    }

    // Remove the log and recalculate total
    final updatedLogs = todayIntake.logs.where((l) => l.id != logId).toList();
    final newTotal = updatedLogs.fold<int>(0, (sum, l) => sum + l.amountMl);

    final updatedIntake = todayIntake.copyWith(
      amountMl: newTotal,
      logs: updatedLogs,
    );

    await updateWaterIntake(updatedIntake);
  }
}
