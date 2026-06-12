import 'package:flutter_test/flutter_test.dart';
import 'package:me_hub/features/routines/domain/entities/routine.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  RoutineItem buildItem({
    String id = 'item-1',
    String title = 'Wake up',
    DateTime? lastCheckedDate,
    int? durationMinutes,
  }) => RoutineItem(
    id: id,
    title: title,
    lastCheckedDate: lastCheckedDate,
    durationMinutes: durationMinutes,
  );

  Routine buildRoutine({
    String id = 'routine-1',
    String name = 'Morning',
    List<RoutineItem>? items,
    int streakCount = 0,
    DateTime? lastStreakDate,
    List<int>? selectedDays,
  }) => Routine(
    id: id,
    name: name,
    items: items ?? [],
    streakCount: streakCount,
    lastStreakDate: lastStreakDate,
    selectedDays: selectedDays,
  );

  // ---------------------------------------------------------------------------
  // RoutineItem.isCheckedToday
  // ---------------------------------------------------------------------------

  group('RoutineItem.isCheckedToday', () {
    final today = DateTime(2026, 5, 30);

    test('returns true when lastCheckedDate matches today', () {
      final item = buildItem(lastCheckedDate: today);
      expect(item.isCheckedToday(today), isTrue);
    });

    test('returns false when lastCheckedDate is yesterday', () {
      final yesterday = today.subtract(const Duration(days: 1));
      final item = buildItem(lastCheckedDate: yesterday);
      expect(item.isCheckedToday(today), isFalse);
    });

    test('returns false when lastCheckedDate is null', () {
      final item = buildItem();
      expect(item.isCheckedToday(today), isFalse);
    });

    test('returns false when lastCheckedDate is in the future', () {
      final tomorrow = today.add(const Duration(days: 1));
      final item = buildItem(lastCheckedDate: tomorrow);
      expect(item.isCheckedToday(today), isFalse);
    });
  });

  group('RoutineItem.copyWith', () {
    test('preserves and updates the guided step duration', () {
      final item = buildItem(durationMinutes: 5);

      expect(item.copyWith(title: 'Drink water').durationMinutes, 5);
      expect(item.copyWith(durationMinutes: 8).durationMinutes, 8);
    });
  });

  // ---------------------------------------------------------------------------
  // Routine.allItemsCheckedToday
  // ---------------------------------------------------------------------------

  group('Routine.allItemsCheckedToday', () {
    final today = DateTime(2026, 5, 30);

    test('returns false when items list is empty', () {
      final routine = buildRoutine(items: []);
      expect(routine.allItemsCheckedToday(today), isFalse);
    });

    test('returns true when all items are checked today', () {
      final items = [
        buildItem(id: '1', lastCheckedDate: today),
        buildItem(id: '2', lastCheckedDate: today),
      ];
      final routine = buildRoutine(items: items);
      expect(routine.allItemsCheckedToday(today), isTrue);
    });

    test('returns false when at least one item is unchecked', () {
      final items = [
        buildItem(id: '1', lastCheckedDate: today),
        buildItem(id: '2'), // not checked
      ];
      final routine = buildRoutine(items: items);
      expect(routine.allItemsCheckedToday(today), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Routine.computeNextStreak
  // ---------------------------------------------------------------------------

  group('Routine.computeNextStreak', () {
    final today = DateTime(2026, 5, 30);

    test('returns 1 when lastStreakDate is null (first completion)', () {
      final routine = buildRoutine(streakCount: 0, lastStreakDate: null);
      expect(routine.computeNextStreak(today), equals(1));
    });

    test('increments streak when lastStreakDate is yesterday', () {
      final yesterday = today.subtract(const Duration(days: 1));
      final routine = buildRoutine(streakCount: 5, lastStreakDate: yesterday);
      expect(routine.computeNextStreak(today), equals(6));
    });

    test(
      'keeps streak unchanged when lastStreakDate is today (double-call guard)',
      () {
        final routine = buildRoutine(streakCount: 3, lastStreakDate: today);
        expect(routine.computeNextStreak(today), equals(3));
      },
    );

    test('resets streak to 1 when lastStreakDate is two or more days ago', () {
      final twoDaysAgo = today.subtract(const Duration(days: 2));
      final routine = buildRoutine(streakCount: 10, lastStreakDate: twoDaysAgo);
      expect(routine.computeNextStreak(today), equals(1));
    });

    test('resets streak to 1 when lastStreakDate is far in the past', () {
      final longAgo = DateTime(2025, 1, 1);
      final routine = buildRoutine(streakCount: 99, lastStreakDate: longAgo);
      expect(routine.computeNextStreak(today), equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // Routine.isActiveOnDay
  // ---------------------------------------------------------------------------

  group('Routine.isActiveOnDay', () {
    test('returns true for all days when selectedDays is null', () {
      final routine = buildRoutine(selectedDays: null);
      for (var day = 0; day < 7; day++) {
        expect(
          routine.isActiveOnDay(day),
          isTrue,
          reason: 'Should be active on day $day',
        );
      }
    });

    test('returns true for all days when selectedDays is empty', () {
      final routine = buildRoutine(selectedDays: []);
      for (var day = 0; day < 7; day++) {
        expect(routine.isActiveOnDay(day), isTrue);
      }
    });

    test('returns true only for configured days', () {
      // Mon=0, Wed=2, Fri=4
      final routine = buildRoutine(selectedDays: [0, 2, 4]);
      expect(routine.isActiveOnDay(0), isTrue); // Monday
      expect(routine.isActiveOnDay(2), isTrue); // Wednesday
      expect(routine.isActiveOnDay(4), isTrue); // Friday
      expect(routine.isActiveOnDay(1), isFalse); // Tuesday
      expect(routine.isActiveOnDay(3), isFalse); // Thursday
      expect(routine.isActiveOnDay(6), isFalse); // Sunday
    });
  });

  // ---------------------------------------------------------------------------
  // Routine.copyWith
  // ---------------------------------------------------------------------------

  group('Routine.copyWith', () {
    test('copyWith preserves unchanged fields', () {
      final original = buildRoutine(id: 'r1', streakCount: 5);
      final copy = original.copyWith(name: 'Evening');
      expect(copy.id, equals('r1'));
      expect(copy.streakCount, equals(5));
      expect(copy.name, equals('Evening'));
    });

    test('clearLastStreakDate sets lastStreakDate to null', () {
      final original = buildRoutine(lastStreakDate: DateTime(2026, 5, 29));
      final cleared = original.copyWith(clearLastStreakDate: true);
      expect(cleared.lastStreakDate, isNull);
    });

    test('clearTime sets timeHour and timeMinute to null', () {
      final routine = Routine(
        id: 'r',
        name: 'Test',
        items: [],
        timeHour: 7,
        timeMinute: 30,
      );
      final cleared = routine.copyWith(clearTime: true);
      expect(cleared.timeHour, isNull);
      expect(cleared.timeMinute, isNull);
    });
  });
}
