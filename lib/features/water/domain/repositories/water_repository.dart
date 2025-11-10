import '../entities/water_intake.dart';

abstract class WaterRepository {
  /// Get water intake for a specific date
  Future<WaterIntake?> getWaterIntake(DateTime date);

  /// Get water intake for today
  Future<WaterIntake?> getTodayWaterIntake();

  /// Add water amount
  Future<void> addWater(DateTime date, int amountMl);

  /// Remove last water log
  Future<void> removeLastLog(DateTime date);

  /// Update water intake
  Future<void> updateWaterIntake(WaterIntake waterIntake);

  /// Get water intake history (last N days)
  Future<List<WaterIntake>> getWaterHistory(int days);

  /// Delete water intake for a specific date
  Future<void> deleteWaterIntake(DateTime date);
}

