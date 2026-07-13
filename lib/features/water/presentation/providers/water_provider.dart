import 'package:flutter/foundation.dart';
import '../../domain/entities/water_intake.dart';
import '../../domain/usecases/usecases.dart';
import '../../data/services/daily_goal_service.dart';
import '../../../home_widget/data/home_widget_service.dart';
import '../../../../core/services/cumulative_stats_service.dart';
import '../../../../core/reminders/services/reminder_coordinator.dart';

class WaterProvider with ChangeNotifier {
  final GetTodayWaterIntake _getTodayWaterIntake;
  final AddWater _addWater;
  final RemoveLastLog _removeLastLog;
  final UpdateWaterIntake _updateWaterIntake;
  final GetAllWaterIntakes? _getAllWaterIntakes;
  final ReminderCoordinator? _reminders;

  WaterProvider({
    required GetTodayWaterIntake getTodayWaterIntake,
    required AddWater addWater,
    required RemoveLastLog removeLastLog,
    required UpdateWaterIntake updateWaterIntake,
    GetAllWaterIntakes? getAllWaterIntakes,
    ReminderCoordinator? reminders,
  }) : _getTodayWaterIntake = getTodayWaterIntake,
       _addWater = addWater,
       _removeLastLog = removeLastLog,
       _updateWaterIntake = updateWaterIntake,
       _getAllWaterIntakes = getAllWaterIntakes,
       _reminders = reminders;

  WaterIntake? _todayIntake;
  bool _isLoading = false;
  String? _error;
  bool _justReachedGoal = false;
  int _dailyGoalMl = 2000; // Default goal

  int _streakDays = 0;
  List<int> _weekMl = List.filled(7, 0);

  /// Consecutive days with any water logged, ending today (an empty today
  /// does not break the streak until the day is over).
  int get streakDays => _streakDays;

  /// Milliliters per weekday Mon..Sun of the current week.
  List<int> get weekMl => _weekMl;

  WaterIntake? get todayIntake => _todayIntake;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get dailyGoalMl => _dailyGoalMl;

  /// Get today's water intake amount
  int get todayAmount => _todayIntake?.amountMl ?? 0;

  /// Get today's progress (0.0 to 1.0)
  double get todayProgress =>
      _todayIntake?.getProgress(dailyGoalMl: _dailyGoalMl) ?? 0.0;

  /// Check if today's goal is reached
  bool get isGoalReached =>
      _todayIntake?.isGoalReached(dailyGoalMl: _dailyGoalMl) ?? false;

  /// Set daily goal (called from WaterPage)
  void setDailyGoal(int dailyGoalMl) {
    _dailyGoalMl = dailyGoalMl;
    notifyListeners();

    // Update widget
    if (_todayIntake != null) {
      HomeWidgetService().updateWidget(
        waterIntake: _todayIntake!.amountMl,
        waterGoal: _dailyGoalMl,
      );
    }
    _reconcileReminders();
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
      // Load saved daily goal first to prevent incorrect progress display
      _dailyGoalMl = await DailyGoalService.getDailyGoal();

      _todayIntake = await _getTodayWaterIntake();
    } catch (e) {
      _error = 'Failed to load water intake';
    } finally {
      _isLoading = false;
      notifyListeners();
      // Update widget
      if (_todayIntake != null) {
        HomeWidgetService().updateWidget(
          waterIntake: _todayIntake!.amountMl,
          waterGoal: _dailyGoalMl,
        );
      }
      await _refreshHydrationStats();
      await _reconcileReminders();
    }
  }

  /// Recompute the hydration streak and this week's daily totals. Runs after
  /// every reload so add/undo/delete all keep the stats current.
  Future<void> _refreshHydrationStats() async {
    final getAll = _getAllWaterIntakes;
    if (getAll == null) return;
    try {
      final all = await getAll();
      final activeDates = <DateTime>{
        for (final intake in all)
          if (intake.amountMl > 0)
            DateTime(intake.date.year, intake.date.month, intake.date.day),
      };

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      var cursor = activeDates.contains(today)
          ? today
          : today.subtract(const Duration(days: 1));
      var streak = 0;
      while (activeDates.contains(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
      _streakDays = streak;

      final monday = today.subtract(Duration(days: today.weekday - 1));
      final week = List<int>.filled(7, 0);
      for (final intake in all) {
        final date = DateTime(
          intake.date.year,
          intake.date.month,
          intake.date.day,
        );
        final index = date.difference(monday).inDays;
        if (index >= 0 && index < 7) week[index] += intake.amountMl;
      }
      _weekMl = week;
      notifyListeners();
    } catch (_) {
      // Stats are decorative; never surface an error for them.
    }
  }

  /// Add water amount
  Future<void> addWaterAmount(int amountMl) async {
    try {
      final wasGoalReached = isGoalReached;
      await _addWater(DateTime.now(), amountMl);
      await loadTodayWaterIntake();

      // Update cumulative all-time water stats
      await CumulativeStatsService.addWater(amountMl);

      // Check if goal was just reached
      if (!wasGoalReached && isGoalReached) {
        _justReachedGoal = true;

        notifyListeners(); // Notify to trigger celebration in UI
      }

      // Update widget
      if (_todayIntake != null) {
        HomeWidgetService().updateWidget(
          waterIntake: _todayIntake!.amountMl,
          waterGoal: _dailyGoalMl,
        );
      }
      await _reconcileReminders();
    } catch (e) {
      _error = 'Failed to add water';
      notifyListeners();
    }
  }

  /// Remove last water log (undo)
  Future<void> undoLastLog() async {
    if (_todayIntake == null || _todayIntake!.logs.isEmpty) return;

    // Capture the amount being removed before deleting
    final removedAmount = _todayIntake!.logs.last.amountMl;

    try {
      await _removeLastLog(DateTime.now());
      await loadTodayWaterIntake();

      // Decrement cumulative all-time water stats
      await CumulativeStatsService.subtractWater(removedAmount);
    } catch (e) {
      _error = 'Failed to undo';
      notifyListeners();
    }

    // Update widget
    if (_todayIntake != null) {
      HomeWidgetService().updateWidget(
        waterIntake: _todayIntake!.amountMl,
        waterGoal: _dailyGoalMl,
      );
    }
    await _reconcileReminders();
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

    // Update widget
    if (_todayIntake != null) {
      HomeWidgetService().updateWidget(
        waterIntake: _todayIntake!.amountMl,
        waterGoal: _dailyGoalMl,
      );
    }
    await _reconcileReminders();
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

    // Capture the amount before removing
    final removedLog = todayIntake.logs.where((l) => l.id == logId).firstOrNull;
    final removedAmount = removedLog?.amountMl ?? 0;

    // Remove the log and recalculate total
    final updatedLogs = todayIntake.logs.where((l) => l.id != logId).toList();
    final newTotal = updatedLogs.fold<int>(0, (sum, l) => sum + l.amountMl);

    final updatedIntake = todayIntake.copyWith(
      amountMl: newTotal,
      logs: updatedLogs,
    );

    await updateWaterIntake(updatedIntake);

    // Decrement cumulative all-time water stats
    if (removedAmount > 0) {
      await CumulativeStatsService.subtractWater(removedAmount);
    }
    await _reconcileReminders();
  }

  Future<void> _reconcileReminders() async {
    await _reminders?.reconcileWater(goalReached: isGoalReached);
  }
}
