import '../../domain/entities/water_intake.dart';
import '../../domain/repositories/water_repository.dart';
import '../datasources/water_local_datasource.dart';

class WaterRepositoryImpl implements WaterRepository {
  final WaterLocalDataSource localDataSource;

  WaterRepositoryImpl(this.localDataSource);

  @override
  Future<WaterIntake?> getTodayWaterIntake() async {
    return await localDataSource.getWaterIntake(DateTime.now());
  }

  @override
  Future<void> addWater(DateTime date, int amountMl) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final existing = await localDataSource.getWaterIntake(normalizedDate);

    if (existing == null) {
      // Create new water intake
      final waterIntake = WaterIntake(
        id: normalizedDate.millisecondsSinceEpoch.toString(),
        date: normalizedDate,
        amountMl: amountMl,
        logs: [
          WaterLog(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            timestamp: DateTime.now(),
            amountMl: amountMl,
          ),
        ],
      );
      await localDataSource.saveWaterIntake(waterIntake);
    } else {
      // Add to existing
      final updatedLogs = [
        ...existing.logs,
        WaterLog(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          timestamp: DateTime.now(),
          amountMl: amountMl,
        ),
      ];
      final updatedWaterIntake = existing.copyWith(
        amountMl: existing.amountMl + amountMl,
        logs: updatedLogs,
      );
      await localDataSource.saveWaterIntake(updatedWaterIntake);
    }
  }

  @override
  Future<void> removeLastLog(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final existing = await localDataSource.getWaterIntake(normalizedDate);

    if (existing == null || existing.logs.isEmpty) return;

    if (existing.logs.length == 1) {
      // Delete entire entry if it's the last log
      await localDataSource.deleteWaterIntake(normalizedDate);
    } else {
      // Remove last log
      final lastLog = existing.logs.last;
      final updatedLogs = existing.logs.sublist(0, existing.logs.length - 1);
      final updatedWaterIntake = existing.copyWith(
        amountMl: existing.amountMl - lastLog.amountMl,
        logs: updatedLogs,
      );
      await localDataSource.saveWaterIntake(updatedWaterIntake);
    }
  }

  @override
  Future<void> updateWaterIntake(WaterIntake waterIntake) async {
    await localDataSource.saveWaterIntake(waterIntake);
  }
}

