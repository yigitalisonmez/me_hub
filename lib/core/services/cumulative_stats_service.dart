import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../features/water/domain/entities/water_intake.dart';
import '../../features/todo/domain/entities/daily_todo.dart';

/// Service to track cumulative (all-time) stats
/// Stats are stored in SharedPreferences and updated incrementally
class CumulativeStatsService {
  static const String _allTimeWaterKey = 'cumulative_all_time_water_ml';
  static const String _allTimeTasksKey = 'cumulative_all_time_tasks_done';
  static const String _maxStreakKey = 'cumulative_max_streak';
  static const String _statsMigratedKey = 'cumulative_stats_migrated_v1';

  /// Initialize cumulative stats - call this on app start
  /// If first time or values are 0, calculates from all existing data
  static Future<void> initializeIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_statsMigratedKey) ?? false;

    debugPrint(
      'CumulativeStats: initializeIfNeeded called, migrated=$migrated',
    );

    if (!migrated) {
      debugPrint('CumulativeStats: First time, migrating data...');
      await _migrateExistingData(prefs);
    } else {
      // Check if stats are still 0 but data exists - re-migrate
      final currentWater = prefs.getInt(_allTimeWaterKey) ?? 0;
      final currentTasks = prefs.getInt(_allTimeTasksKey) ?? 0;

      debugPrint(
        'CumulativeStats: Current values - water=$currentWater, tasks=$currentTasks',
      );

      if (currentWater == 0 || currentTasks == 0) {
        debugPrint('CumulativeStats: Values are 0, trying to recalculate...');
        await _tryRecalculateFromHive(prefs, currentWater, currentTasks);
      }
    }
  }

  /// Try to recalculate stats from Hive if values are still 0
  static Future<void> _tryRecalculateFromHive(
    SharedPreferences prefs,
    int currentWater,
    int currentTasks,
  ) async {
    try {
      debugPrint(
        'CumulativeStats: water_intake box open=${Hive.isBoxOpen('water_intake')}',
      );
      debugPrint(
        'CumulativeStats: daily_todos box open=${Hive.isBoxOpen('daily_todos')}',
      );

      // Recalculate water if it's 0
      if (currentWater == 0 && Hive.isBoxOpen('water_intake')) {
        final waterBox = Hive.box<WaterIntake>('water_intake');
        int totalWaterMl = 0;
        debugPrint(
          'CumulativeStats: water_intake has ${waterBox.length} entries',
        );
        for (final intake in waterBox.values) {
          totalWaterMl += intake.amountMl;
        }
        debugPrint(
          'CumulativeStats: Calculated total water = $totalWaterMl ml',
        );
        if (totalWaterMl > 0) {
          await prefs.setInt(_allTimeWaterKey, totalWaterMl);
        }
      }

      // Recalculate tasks if it's 0
      if (currentTasks == 0 && Hive.isBoxOpen('daily_todos')) {
        final todoBox = Hive.box<DailyTodo>('daily_todos');
        int totalTasks = 0;
        int completedCount = 0;
        debugPrint(
          'CumulativeStats: daily_todos has ${todoBox.length} entries',
        );
        for (final todo in todoBox.values) {
          totalTasks++;
          if (todo.isCompleted) {
            completedCount++;
          }
        }
        debugPrint(
          'CumulativeStats: Total todos=$totalTasks, completed=$completedCount',
        );
        if (completedCount > 0) {
          await prefs.setInt(_allTimeTasksKey, completedCount);
        }
      }
    } catch (e) {
      debugPrint('CumulativeStats: Error in recalculate: $e');
    }
  }

  /// Migrate existing data to cumulative stats (one-time operation)
  static Future<void> _migrateExistingData(SharedPreferences prefs) async {
    try {
      // Calculate total water from all existing records
      int totalWaterMl = 0;
      if (Hive.isBoxOpen('water_intake')) {
        final waterBox = Hive.box<WaterIntake>('water_intake');
        for (final intake in waterBox.values) {
          totalWaterMl += intake.amountMl;
        }
      }

      // Calculate total completed tasks
      int totalTasks = 0;
      if (Hive.isBoxOpen('daily_todos')) {
        final todoBox = Hive.box<DailyTodo>('daily_todos');
        for (final todo in todoBox.values) {
          if (todo.isCompleted) {
            totalTasks++;
          }
        }
      }

      // Save to SharedPreferences
      await prefs.setInt(_allTimeWaterKey, totalWaterMl);
      await prefs.setInt(_allTimeTasksKey, totalTasks);
      await prefs.setInt(_maxStreakKey, 0); // Start fresh, will be updated
      await prefs.setBool(_statsMigratedKey, true);
    } catch (e) {
      // Silently fail, will try again next time
    }
  }

  /// Get all-time water consumed in ml
  static Future<int> getAllTimeWaterMl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_allTimeWaterKey) ?? 0;
  }

  /// Add water to the cumulative total
  static Future<void> addWater(int amountMl) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_allTimeWaterKey) ?? 0;
    await prefs.setInt(_allTimeWaterKey, current + amountMl);
  }

  /// Get all-time tasks completed
  static Future<int> getAllTimeTasksCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_allTimeTasksKey) ?? 0;
  }

  /// Increment tasks completed count
  static Future<void> incrementTasksCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_allTimeTasksKey) ?? 0;
    await prefs.setInt(_allTimeTasksKey, current + 1);
  }

  /// Decrement tasks completed count (when unchecking)
  static Future<void> decrementTasksCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_allTimeTasksKey) ?? 0;
    if (current > 0) {
      await prefs.setInt(_allTimeTasksKey, current - 1);
    }
  }

  /// Get max streak
  static Future<int> getMaxStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_maxStreakKey) ?? 0;
  }

  /// Update max streak if current is higher
  static Future<void> updateMaxStreak(int currentStreak) async {
    final prefs = await SharedPreferences.getInstance();
    final maxStreak = prefs.getInt(_maxStreakKey) ?? 0;
    if (currentStreak > maxStreak) {
      await prefs.setInt(_maxStreakKey, currentStreak);
    }
  }

  /// Force recalculate all stats from existing data
  static Future<void> forceRecalculate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_statsMigratedKey, false);
    await _migrateExistingData(prefs);
  }
}
