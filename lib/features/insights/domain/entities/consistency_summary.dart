/// One day inside the consistency window.
class DayConsistency {
  final DateTime date;

  /// Number of habit categories completed that day (0–5):
  /// tasks, water, mood, gratitude, mindful session.
  final int habitsCompleted;

  const DayConsistency({required this.date, required this.habitsCompleted});

  /// Heatmap intensity level 0–4 used by the consistency grid.
  int get level => habitsCompleted >= 4 ? 4 : habitsCompleted;

  bool get isActive => habitsCompleted > 0;
}

/// Aggregated consistency data for the heatmap screen.
class ConsistencySummary {
  /// Days ordered week by week (Monday-first), oldest week first.
  /// Length is always `weeks * 7`; trailing days may be in the future.
  final List<DayConsistency> days;

  final int currentStreak;
  final int bestStreak;

  /// Active days / elapsed days in the current calendar month (0–1).
  final double monthCompletion;

  /// Total days with at least one habit inside the window.
  final int activeDays;

  const ConsistencySummary({
    required this.days,
    required this.currentStreak,
    required this.bestStreak,
    required this.monthCompletion,
    required this.activeDays,
  });
}
