import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../mood_tracker/domain/entities/mood_entry.dart';
import '../../../water/domain/entities/water_intake.dart';


class AnalysisService {
  // Singleton pattern
  static final AnalysisService _instance = AnalysisService._internal();
  factory AnalysisService() => _instance;
  AnalysisService._internal();

  /// Calculates the Pearson Correlation Coefficient (-1 to 1)
  /// Returns null if not enough data points (need at least 3)
  double? _calculatePearsonCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 3) return null;

    final n = x.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((e) => e * e).reduce((a, b) => a + b);
    final sumY2 = y.map((e) => e * e).reduce((a, b) => a + b);

    final numerator = (n * sumXY) - (sumX * sumY);
    final denominator = sqrt(((n * sumX2) - (sumX * sumX)) * ((n * sumY2) - (sumY * sumY)));

    if (denominator == 0) return 0; // Avoid division by zero
    return numerator / denominator;
  }

  /// Analyzes the relationship between Water Intake and Mood
  Future<String?> analyzeWaterMoodCorrelation() async {
    try {
      final moodBox = await Hive.openBox<MoodEntry>('mood_entries');
      final waterBox = await Hive.openBox<WaterIntake>('water_intake');

      final moods = moodBox.values.toList();
      final waterIntakes = waterBox.values.toList();

      if (moods.length < 3 || waterIntakes.length < 3) {
        return null; // Not enough data
      }

      // Map data by date (YYYY-MM-DD) to align them
      final Map<String, double> moodMap = {};
      final Map<String, double> waterMap = {};

      for (var m in moods) {
        final date = DateTime.fromMillisecondsSinceEpoch(m.dateTimestamp);
        final key = '${date.year}-${date.month}-${date.day}';
        // If multiple moods per day, take the average or the last one. Let's take average.
        if (moodMap.containsKey(key)) {
          moodMap[key] = (moodMap[key]! + m.score) / 2;
        } else {
          moodMap[key] = m.score.toDouble();
        }
      }

      for (var w in waterIntakes) {
        final date = w.date;
        final key = '${date.year}-${date.month}-${date.day}';
        waterMap[key] = w.amountMl.toDouble();
      }

      // Create aligned lists
      final List<double> alignedMoods = [];
      final List<double> alignedWater = [];

      // Iterate through days where we have BOTH data
      for (var key in moodMap.keys) {
        if (waterMap.containsKey(key)) {
          alignedMoods.add(moodMap[key]!);
          alignedWater.add(waterMap[key]!);
        }
      }

      final correlation = _calculatePearsonCorrelation(alignedWater, alignedMoods);

      if (correlation == null) return null;

      // Interpret correlation
      if (correlation > 0.5) {
        return "💡 Strong Insight: On days you drink more water, your mood tends to be significantly better (+${(correlation * 100).toStringAsFixed(0)}% correlation).";
      } else if (correlation > 0.3) {
        return "💡 Insight: There is a positive link between your hydration and mood. Keep drinking water!";
      } else if (correlation < -0.3) {
        return "🤔 Interesting: Your data shows a slight negative link between water and mood. Maybe you drink more when stressed?";
      } else {
        return "📊 Analysis: No strong link found between water and mood yet. Keep tracking!";
      }
    } catch (e) {
      return null;
    }
  }

  /// Analyzes Mood Trends by Day of Week
  Future<String?> analyzeMoodTrendByDay() async {
    try {
      final moodBox = await Hive.openBox<MoodEntry>('mood_entries');
      final moods = moodBox.values.toList();
      
      if (moods.length < 5) return null; // Need some data

      // 0=Mon, ..., 6=Sun
      final Map<int, List<double>> dayMoods = {};
      
      for (var m in moods) {
        final date = DateTime.fromMillisecondsSinceEpoch(m.dateTimestamp);
        final weekday = date.weekday - 1;
        dayMoods.putIfAbsent(weekday, () => []).add(m.score.toDouble());
      }
      
      // Calculate averages
      int bestDay = -1;
      double bestAvg = -1;
      int worstDay = -1;
      double worstAvg = 11;
      
      dayMoods.forEach((day, scores) {
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        if (avg > bestAvg) {
          bestAvg = avg;
          bestDay = day;
        }
        if (avg < worstAvg) {
          worstAvg = avg;
          worstDay = day;
        }
      });
      
      if (bestDay != -1 && bestAvg >= 7.0) {
        const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        return "📈 Trend: You tend to be happiest on ${days[bestDay]}s (Avg: ${bestAvg.toStringAsFixed(1)}/10).";
      } else if (worstDay != -1 && worstAvg <= 5.0) {
        const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        return "📉 Trend: ${days[worstDay]}s seem tough for you (Avg: ${worstAvg.toStringAsFixed(1)}/10). Be kind to yourself!";
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Analyzes Mood Trends by Time of Day
  Future<String?> analyzeMoodTrendByTime() async {
    try {
      final moodBox = await Hive.openBox<MoodEntry>('mood_entries');
      final moods = moodBox.values.toList();
      
      if (moods.length < 5) return null;

      final Map<String, List<double>> timeMoods = {
        'Morning': [],
        'Afternoon': [],
        'Evening': [],
      };

      for (var m in moods) {
        final date = DateTime.fromMillisecondsSinceEpoch(m.dateTimestamp);
        final hour = date.hour;
        
        if (hour >= 5 && hour < 12) {
          timeMoods['Morning']!.add(m.score.toDouble());
        } else if (hour >= 12 && hour < 17) {
          timeMoods['Afternoon']!.add(m.score.toDouble());
        } else if (hour >= 17 || hour < 5) {
          timeMoods['Evening']!.add(m.score.toDouble());
        }
      }

      String bestTime = '';
      double bestAvg = -1;

      timeMoods.forEach((time, scores) {
        if (scores.isNotEmpty) {
          final avg = scores.reduce((a, b) => a + b) / scores.length;
          if (avg > bestAvg) {
            bestAvg = avg;
            bestTime = time;
          }
        }
      });

      if (bestTime.isNotEmpty && bestAvg >= 0) {
        return "🌅 Insight: You feel best in the $bestTime (Avg: ${bestAvg.toStringAsFixed(1)}/10).";
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
