import 'package:shared_preferences/shared_preferences.dart';

class DailyGoalService {
  static const String _key = 'water_daily_goal_ml';
  static const int _defaultGoal = 2000;

  /// Get daily goal in milliliters
  static Future<int> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? _defaultGoal;
  }

  /// Set daily goal in milliliters
  static Future<void> setDailyGoal(int goalMl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, goalMl);
  }
}

