import '../entities/consistency_summary.dart';

/// Pure aggregation of per-category activity dates into the consistency
/// summary shown on the heatmap screen. Kept free of storage concerns so it
/// can be unit tested directly.
class ConsistencyCalculator {
  static const int defaultWeeks = 16;

  /// [categoryActivity] holds one set of active (normalized, local) dates per
  /// habit category: tasks, water, mood, gratitude, mindful.
  ConsistencySummary calculate({
    required List<Set<DateTime>> categoryActivity,
    required DateTime today,
    int weeks = defaultWeeks,
  }) {
    final normalizedToday = _dateOnly(today);
    // Monday of the current week, then back (weeks - 1) full weeks.
    final currentMonday = normalizedToday.subtract(
      Duration(days: normalizedToday.weekday - 1),
    );
    final windowStart = currentMonday.subtract(Duration(days: 7 * (weeks - 1)));

    final days = <DayConsistency>[];
    for (var i = 0; i < weeks * 7; i++) {
      final date = windowStart.add(Duration(days: i));
      days.add(
        DayConsistency(date: date, habitsCompleted: _habitsOn(date, categoryActivity)),
      );
    }

    return ConsistencySummary(
      days: days,
      currentStreak: _currentStreak(normalizedToday, categoryActivity),
      bestStreak: _bestStreak(days, normalizedToday),
      monthCompletion: _monthCompletion(normalizedToday, categoryActivity),
      activeDays: days
          .where((d) => !d.date.isAfter(normalizedToday) && d.isActive)
          .length,
    );
  }

  int _habitsOn(DateTime date, List<Set<DateTime>> categoryActivity) {
    var count = 0;
    for (final category in categoryActivity) {
      if (category.contains(date)) count++;
    }
    return count;
  }

  /// Consecutive active days ending today, or ending yesterday when today has
  /// no activity yet (the streak is not broken until the day is over).
  int _currentStreak(DateTime today, List<Set<DateTime>> categoryActivity) {
    var cursor = _habitsOn(today, categoryActivity) > 0
        ? today
        : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (_habitsOn(cursor, categoryActivity) > 0) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _bestStreak(List<DayConsistency> days, DateTime today) {
    var best = 0;
    var run = 0;
    for (final day in days) {
      if (day.date.isAfter(today)) break;
      if (day.isActive) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
    }
    return best;
  }

  double _monthCompletion(
    DateTime today,
    List<Set<DateTime>> categoryActivity,
  ) {
    final monthStart = DateTime(today.year, today.month, 1);
    final elapsed = today.difference(monthStart).inDays + 1;
    var active = 0;
    for (var i = 0; i < elapsed; i++) {
      if (_habitsOn(monthStart.add(Duration(days: i)), categoryActivity) > 0) {
        active++;
      }
    }
    return elapsed > 0 ? active / elapsed : 0;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
