/// Direction of the mood trend across the wrapped week.
enum MoodTrend { up, steady, down, unknown }

/// Everything the Weekly Wrapped story needs, precomputed.
class WeeklyWrappedData {
  /// Monday of the wrapped week.
  final DateTime weekStart;

  /// Sunday of the wrapped week.
  final DateTime weekEnd;

  final String userName;

  // Hydration
  final double totalWaterLiters;

  /// Water per weekday Mon..Sun in milliliters.
  final List<int> waterByDayMl;

  /// Weekday index 0–6 (Mon..Sun) of the highest intake, or null when no
  /// water was logged at all.
  final int? bestWaterDay;

  // Productivity
  final int tasksCompleted;

  /// Breathing + affirmation sessions completed during the week.
  final int mindfulSessions;

  /// Share of completed tasks finished before noon (0–1), or null when no
  /// task was completed.
  final double? morningTaskShare;

  // Mood
  final MoodTrend moodTrend;

  /// Percent (e.g. 18 for "18% brighter") comparing mood on days with
  /// above-median water against the rest, or null without enough data.
  final int? moodWaterBoostPercent;

  // Streak
  final int currentStreak;
  final int bestStreak;

  const WeeklyWrappedData({
    required this.weekStart,
    required this.weekEnd,
    required this.userName,
    required this.totalWaterLiters,
    required this.waterByDayMl,
    required this.bestWaterDay,
    required this.tasksCompleted,
    required this.mindfulSessions,
    required this.morningTaskShare,
    required this.moodTrend,
    required this.moodWaterBoostPercent,
    required this.currentStreak,
    required this.bestStreak,
  });

  bool get hasAnyData =>
      totalWaterLiters > 0 ||
      tasksCompleted > 0 ||
      mindfulSessions > 0 ||
      moodTrend != MoodTrend.unknown;
}
