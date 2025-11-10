import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/water_intake.dart';

class WaterLocalDataSource {
  final Box<WaterIntake> _box;

  WaterLocalDataSource(this._box);

  /// Get water intake for a specific date (normalized to day)
  Future<WaterIntake?> getWaterIntake(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final key = _getKey(normalizedDate);
    return _box.get(key);
  }

  /// Save or update water intake
  Future<void> saveWaterIntake(WaterIntake waterIntake) async {
    final normalizedDate = DateTime(
      waterIntake.date.year,
      waterIntake.date.month,
      waterIntake.date.day,
    );
    final key = _getKey(normalizedDate);
    await _box.put(key, waterIntake);
  }

  /// Delete water intake for a specific date
  Future<void> deleteWaterIntake(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final key = _getKey(normalizedDate);
    await _box.delete(key);
  }

  /// Get all water intakes (for history)
  Future<List<WaterIntake>> getAllWaterIntakes() async {
    return _box.values.toList();
  }

  /// Generate key from date (YYYY-MM-DD format)
  String _getKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

