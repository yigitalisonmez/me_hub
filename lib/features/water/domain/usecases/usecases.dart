import '../entities/water_intake.dart';
import '../repositories/water_repository.dart';

class GetTodayWaterIntake {
  final WaterRepository repository;

  GetTodayWaterIntake(this.repository);

  Future<WaterIntake?> call() => repository.getTodayWaterIntake();
}

class AddWater {
  final WaterRepository repository;

  AddWater(this.repository);

  Future<void> call(DateTime date, int amountMl) =>
      repository.addWater(date, amountMl);
}

class RemoveLastLog {
  final WaterRepository repository;

  RemoveLastLog(this.repository);

  Future<void> call(DateTime date) => repository.removeLastLog(date);
}

class GetWaterHistory {
  final WaterRepository repository;

  GetWaterHistory(this.repository);

  Future<List<WaterIntake>> call(int days) => repository.getWaterHistory(days);
}

