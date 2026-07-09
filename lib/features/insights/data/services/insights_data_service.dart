import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../gratitude/domain/entities/gratitude_entry.dart';
import '../../../mood_tracker/domain/entities/mood_entry.dart';
import '../../../todo/data/models/daily_todo_model.dart';
import '../../../water/domain/entities/water_intake.dart';
import '../../domain/entities/consistency_summary.dart';
import '../../domain/entities/weekly_wrapped_data.dart';
import '../../domain/usecases/consistency_calculator.dart';

/// Reads the existing local stores (Hive boxes and SharedPreferences session
/// histories) and produces the aggregates behind the Consistency heatmap and
/// the Weekly Wrapped story. Read-only: it never mutates feature data.
class InsightsDataService {
  final ConsistencyCalculator _calculator;

  InsightsDataService({ConsistencyCalculator? calculator})
    : _calculator = calculator ?? ConsistencyCalculator();

  Future<ConsistencySummary> loadConsistency({
    DateTime? today,
    int weeks = ConsistencyCalculator.defaultWeeks,
  }) async {
    final activity = await _loadCategoryActivity();
    return _calculator.calculate(
      categoryActivity: activity,
      today: today ?? DateTime.now(),
      weeks: weeks,
    );
  }

  /// Wrapped week: the current Monday..Sunday week when today is Sunday
  /// (matching the Sunday Home banner), otherwise the previous full week.
  Future<WeeklyWrappedData> loadWeeklyWrapped({DateTime? now}) async {
    final today = _dateOnly(now ?? DateTime.now());
    final monday = today.weekday == DateTime.sunday
        ? today.subtract(const Duration(days: 6))
        : today.subtract(Duration(days: today.weekday - 1 + 7));
    final sunday = monday.add(const Duration(days: 6));

    final prefs = await SharedPreferences.getInstance();
    final consistency = await loadConsistency(today: today);

    final water = await _waterInRange(monday, sunday);
    final todos = await _todosInRange(monday, sunday);
    final moods = await _moodsInRange(monday, sunday);
    final sessions = _sessionDatesInRange(prefs, monday, sunday);

    // Hydration
    final byDay = List<int>.filled(7, 0);
    for (final intake in water) {
      byDay[intake.date.weekday - 1] += intake.amountMl;
    }
    final totalMl = byDay.fold<int>(0, (sum, ml) => sum + ml);
    int? bestDay;
    if (totalMl > 0) {
      var bestMl = -1;
      for (var i = 0; i < 7; i++) {
        if (byDay[i] > bestMl) {
          bestMl = byDay[i];
          bestDay = i;
        }
      }
    }

    // Productivity
    final morningDone = todos
        .where((t) => (t.completedAt ?? t.date).hour < 12)
        .length;

    return WeeklyWrappedData(
      weekStart: monday,
      weekEnd: sunday,
      userName: await _loadUserName(),
      totalWaterLiters: totalMl / 1000,
      waterByDayMl: byDay,
      bestWaterDay: bestDay,
      tasksCompleted: todos.length,
      mindfulSessions: sessions.length,
      morningTaskShare: todos.isEmpty ? null : morningDone / todos.length,
      moodTrend: _moodTrend(moods, monday),
      moodWaterBoostPercent: _moodWaterBoost(moods, water),
      currentStreak: consistency.currentStreak,
      bestStreak: consistency.bestStreak,
    );
  }

  // ---------------------------------------------------------------- storage

  Future<List<Set<DateTime>>> _loadCategoryActivity() async {
    final prefs = await SharedPreferences.getInstance();

    final taskDates = <DateTime>{};
    for (final todo in (await _openBox<DailyTodoModel>('todos')).values) {
      if (todo.isCompleted) {
        taskDates.add(_dateOnly(todo.completedAt ?? todo.date));
      }
    }

    final waterDates = <DateTime>{};
    for (final intake in (await _openBox<WaterIntake>('water_intake')).values) {
      if (intake.amountMl > 0) waterDates.add(_dateOnly(intake.date));
    }

    final moodDates = <DateTime>{};
    for (final mood in (await _openBox<MoodEntry>('mood_entries')).values) {
      moodDates.add(_dateOnly(mood.date));
    }

    final gratitudeDates = <DateTime>{};
    for (final entry
        in (await _openBox<GratitudeEntry>('gratitude_entries')).values) {
      gratitudeDates.add(
        _dateOnly(DateTime.fromMillisecondsSinceEpoch(entry.dateTimestamp)),
      );
    }

    final mindfulDates = <DateTime>{
      ..._sessionDates(prefs.getString('breathing_session_history')),
      ..._sessionDates(prefs.getString('affirmation_session_history')),
    };

    return [taskDates, waterDates, moodDates, gratitudeDates, mindfulDates];
  }

  Future<Box<T>> _openBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box<T>(name);
    return Hive.openBox<T>(name);
  }

  Future<String> _loadUserName() async {
    try {
      const storage = FlutterSecureStorage();
      return (await storage.read(key: 'user_name'))?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<List<WaterIntake>> _waterInRange(DateTime start, DateTime end) async {
    final box = await _openBox<WaterIntake>('water_intake');
    return box.values
        .where((w) => _inRange(_dateOnly(w.date), start, end))
        .toList();
  }

  Future<List<DailyTodoModel>> _todosInRange(
    DateTime start,
    DateTime end,
  ) async {
    final box = await _openBox<DailyTodoModel>('todos');
    return box.values
        .where(
          (t) =>
              t.isCompleted &&
              _inRange(_dateOnly(t.completedAt ?? t.date), start, end),
        )
        .toList();
  }

  Future<List<MoodEntry>> _moodsInRange(DateTime start, DateTime end) async {
    final box = await _openBox<MoodEntry>('mood_entries');
    return box.values
        .where((m) => _inRange(_dateOnly(m.date), start, end))
        .toList();
  }

  List<DateTime> _sessionDatesInRange(
    SharedPreferences prefs,
    DateTime start,
    DateTime end,
  ) {
    return [
      ..._sessionDates(prefs.getString('breathing_session_history')),
      ..._sessionDates(prefs.getString('affirmation_session_history')),
    ].where((d) => _inRange(d, start, end)).toList();
  }

  // ------------------------------------------------------------ derivations

  /// Mood trend: first half of the week vs second half.
  static MoodTrend _moodTrend(List<MoodEntry> moods, DateTime weekStart) {
    if (moods.length < 2) return MoodTrend.unknown;
    final firstHalf = <int>[];
    final secondHalf = <int>[];
    for (final mood in moods) {
      final dayIndex = _dateOnly(mood.date).difference(weekStart).inDays;
      (dayIndex < 4 ? firstHalf : secondHalf).add(mood.score);
    }
    if (firstHalf.isEmpty || secondHalf.isEmpty) return MoodTrend.steady;
    final delta = _avg(secondHalf) - _avg(firstHalf);
    if (delta > 0.5) return MoodTrend.up;
    if (delta < -0.5) return MoodTrend.down;
    return MoodTrend.steady;
  }

  /// Mood on above-median water days vs the rest, needing at least two days
  /// on each side to say anything.
  static int? _moodWaterBoost(List<MoodEntry> moods, List<WaterIntake> water) {
    final waterByDate = <DateTime, int>{};
    for (final intake in water) {
      final key = _dateOnly(intake.date);
      waterByDate[key] = (waterByDate[key] ?? 0) + intake.amountMl;
    }
    if (waterByDate.isEmpty) return null;
    final amounts = waterByDate.values.toList()..sort();
    final median = amounts[amounts.length ~/ 2];
    final highMoods = <int>[];
    final lowMoods = <int>[];
    for (final mood in moods) {
      final ml = waterByDate[_dateOnly(mood.date)] ?? 0;
      (ml >= median && ml > 0 ? highMoods : lowMoods).add(mood.score);
    }
    if (highMoods.length < 2 || lowMoods.length < 2) return null;
    final low = _avg(lowMoods);
    if (low <= 0) return null;
    final boost = ((_avg(highMoods) - low) / low * 100).round();
    return boost > 0 ? boost : null;
  }

  static double _avg(List<int> values) =>
      values.fold<int>(0, (sum, v) => sum + v) / values.length;

  static Set<DateTime> _sessionDates(String? rawJson) {
    if (rawJson == null || rawJson.isEmpty) return {};
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return {};
      final dates = <DateTime>{};
      for (final entry in decoded.whereType<Map>()) {
        final value = entry['completedAt'];
        if (value is! String) continue;
        final completedAt = DateTime.tryParse(value);
        if (completedAt != null) dates.add(_dateOnly(completedAt));
      }
      return dates;
    } catch (_) {
      return {};
    }
  }

  static bool _inRange(DateTime day, DateTime start, DateTime end) =>
      !day.isBefore(start) && !day.isAfter(end);

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
