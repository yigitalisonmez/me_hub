import 'package:hive_flutter/hive_flutter.dart';

part 'water_intake.g.dart';

@HiveType(typeId: 20)
class WaterIntake {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final int amountMl; // Total amount in milliliters

  @HiveField(3)
  final List<WaterLog> logs; // Individual water additions

  const WaterIntake({
    required this.id,
    required this.date,
    required this.amountMl,
    required this.logs,
  });

  WaterIntake copyWith({
    String? id,
    DateTime? date,
    int? amountMl,
    List<WaterLog>? logs,
  }) {
    return WaterIntake(
      id: id ?? this.id,
      date: date ?? this.date,
      amountMl: amountMl ?? this.amountMl,
      logs: logs ?? this.logs,
    );
  }

  /// Get percentage of daily goal (2000ml default)
  double getProgress({int dailyGoalMl = 2000}) {
    return (amountMl / dailyGoalMl).clamp(0.0, 1.0);
  }

  /// Check if daily goal is reached
  bool isGoalReached({int dailyGoalMl = 2000}) {
    return amountMl >= dailyGoalMl;
  }
}

@HiveType(typeId: 21)
class WaterLog {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final int amountMl;

  const WaterLog({
    required this.id,
    required this.timestamp,
    required this.amountMl,
  });
}

