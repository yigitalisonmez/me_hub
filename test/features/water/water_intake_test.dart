import 'package:flutter_test/flutter_test.dart';
import 'package:me_hub/features/water/domain/entities/water_intake.dart';

void main() {
  group('WaterIntake entity — progress & goal', () {
    WaterIntake buildIntake(int amountMl, {List<WaterLog>? logs}) =>
        WaterIntake(
          id: 'test-id',
          date: DateTime(2026, 5, 30),
          amountMl: amountMl,
          logs: logs ?? [],
        );

    test('getProgress returns 0.0 when amount is 0', () {
      expect(buildIntake(0).getProgress(dailyGoalMl: 2000), 0.0);
    });

    test('getProgress returns 0.5 at half goal', () {
      expect(buildIntake(1000).getProgress(dailyGoalMl: 2000), 0.5);
    });

    test('getProgress clamps to 1.0 when over goal', () {
      expect(buildIntake(3000).getProgress(dailyGoalMl: 2000), 1.0);
    });

    test('getProgress uses default goal of 2000ml', () {
      expect(buildIntake(2000).getProgress(), 1.0);
    });

    test('isGoalReached is false below goal', () {
      expect(buildIntake(1999).isGoalReached(dailyGoalMl: 2000), isFalse);
    });

    test('isGoalReached is true at exact goal', () {
      expect(buildIntake(2000).isGoalReached(dailyGoalMl: 2000), isTrue);
    });

    test('isGoalReached is true above goal', () {
      expect(buildIntake(2500).isGoalReached(dailyGoalMl: 2000), isTrue);
    });
  });

  group('WaterIntake copyWith', () {
    test('copyWith preserves unchanged fields', () {
      final original = WaterIntake(
        id: 'abc',
        date: DateTime(2026, 1, 1),
        amountMl: 500,
        logs: [],
      );
      final updated = original.copyWith(amountMl: 800);
      expect(updated.id, equals('abc'));
      expect(updated.date, equals(DateTime(2026, 1, 1)));
      expect(updated.amountMl, equals(800));
      expect(updated.logs, isEmpty);
    });

    test('copyWith replaces logs when provided', () {
      final original = WaterIntake(
        id: 'abc',
        date: DateTime(2026, 1, 1),
        amountMl: 0,
        logs: [],
      );
      final log = WaterLog(
        id: 'log-1',
        timestamp: DateTime(2026, 1, 1, 9),
        amountMl: 300,
      );
      final updated = original.copyWith(amountMl: 300, logs: [log]);
      expect(updated.logs.length, equals(1));
      expect(updated.logs.first.amountMl, equals(300));
    });
  });

  group('Delete-log total recalculation', () {
    // Mirrors the logic in WaterProvider.deleteLog:
    // newTotal = remaining logs .fold sum

    test('removing one log recalculates total correctly', () {
      final log1 = WaterLog(
        id: 'log-1',
        timestamp: DateTime(2026, 5, 30, 8),
        amountMl: 300,
      );
      final log2 = WaterLog(
        id: 'log-2',
        timestamp: DateTime(2026, 5, 30, 12),
        amountMl: 500,
      );
      final intake = WaterIntake(
        id: 'today',
        date: DateTime(2026, 5, 30),
        amountMl: 800,
        logs: [log1, log2],
      );

      // simulate deleteLog('log-1')
      final remaining = intake.logs.where((l) => l.id != 'log-1').toList();
      final newTotal = remaining.fold<int>(0, (s, l) => s + l.amountMl);

      expect(newTotal, equals(500));
      expect(remaining.length, equals(1));
    });

    test('removing last log leaves total at 0', () {
      final log = WaterLog(
        id: 'only',
        timestamp: DateTime(2026, 5, 30, 9),
        amountMl: 250,
      );
      final intake = WaterIntake(
        id: 'today',
        date: DateTime(2026, 5, 30),
        amountMl: 250,
        logs: [log],
      );

      final remaining = intake.logs.where((l) => l.id != 'only').toList();
      final newTotal = remaining.fold<int>(0, (s, l) => s + l.amountMl);

      expect(newTotal, equals(0));
      expect(remaining, isEmpty);
    });
  });
}
