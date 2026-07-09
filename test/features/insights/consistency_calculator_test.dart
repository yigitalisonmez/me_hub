import 'package:flutter_test/flutter_test.dart';
import 'package:me_hub/features/insights/domain/usecases/consistency_calculator.dart';

void main() {
  final calculator = ConsistencyCalculator();

  // Wednesday 2026-07-08 as a stable "today".
  final today = DateTime(2026, 7, 8);

  DateTime day(int daysAgo) => today.subtract(Duration(days: daysAgo));

  List<Set<DateTime>> activity({
    Set<DateTime>? tasks,
    Set<DateTime>? water,
    Set<DateTime>? mood,
    Set<DateTime>? gratitude,
    Set<DateTime>? mindful,
  }) => [tasks ?? {}, water ?? {}, mood ?? {}, gratitude ?? {}, mindful ?? {}];

  test('window is weeks * 7 days, Monday-first, ending in the current week', () {
    final summary = calculator.calculate(
      categoryActivity: activity(),
      today: today,
      weeks: 16,
    );
    expect(summary.days.length, 16 * 7);
    expect(summary.days.first.date.weekday, DateTime.monday);
    expect(summary.days.last.date, DateTime(2026, 7, 12)); // this Sunday
  });

  test('habit counts map to levels with 4+ capped at 4', () {
    final target = day(1);
    final summary = calculator.calculate(
      categoryActivity: activity(
        tasks: {target},
        water: {target},
        mood: {target},
        gratitude: {target},
        mindful: {target},
      ),
      today: today,
    );
    final match = summary.days.singleWhere((d) => d.date == target);
    expect(match.habitsCompleted, 5);
    expect(match.level, 4);
  });

  test('current streak counts consecutive days ending today', () {
    final summary = calculator.calculate(
      categoryActivity: activity(water: {day(0), day(1), day(2)}),
      today: today,
    );
    expect(summary.currentStreak, 3);
  });

  test('an empty today does not break the streak yet', () {
    final summary = calculator.calculate(
      categoryActivity: activity(water: {day(1), day(2)}),
      today: today,
    );
    expect(summary.currentStreak, 2);
  });

  test('a gap resets the current streak but keeps the best streak', () {
    final summary = calculator.calculate(
      categoryActivity: activity(
        water: {day(0), day(3), day(4), day(5), day(6)},
      ),
      today: today,
    );
    expect(summary.currentStreak, 1);
    expect(summary.bestStreak, 4);
  });

  test('month completion is active days over elapsed days', () {
    // July 8: 8 elapsed days, 4 active.
    final summary = calculator.calculate(
      categoryActivity: activity(
        mood: {
          DateTime(2026, 7, 1),
          DateTime(2026, 7, 2),
          DateTime(2026, 7, 5),
          DateTime(2026, 7, 8),
        },
      ),
      today: today,
    );
    expect(summary.monthCompletion, closeTo(0.5, 0.0001));
  });

  test('future days in the window stay inactive and uncounted', () {
    final summary = calculator.calculate(
      categoryActivity: activity(
        // Friday this week is in the window but after "today".
        tasks: {DateTime(2026, 7, 10), day(0)},
      ),
      today: today,
    );
    expect(summary.activeDays, 1);
  });
}
