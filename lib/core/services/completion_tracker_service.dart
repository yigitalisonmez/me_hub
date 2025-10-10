import 'package:shared_preferences/shared_preferences.dart';

class CompletionTrackerService {
  static const String _completionKey = 'daily_completion_';
  static const String _celebrationShownKey = 'celebration_shown_';

  /// Bugünün completion durumunu kaydet
  static Future<void> saveDailyCompletion(
    DateTime date,
    int totalTodos,
    int completedTodos,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = _completionKey + date.toIso8601String().split('T')[0];
      await prefs.setString(dateKey, '$totalTodos:$completedTodos');
    } catch (e) {
      print('Completion save error: $e');
    }
  }

  /// Bugünün completion durumunu getir
  static Future<Map<String, int>?> getDailyCompletion(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = _completionKey + date.toIso8601String().split('T')[0];
      final completionData = prefs.getString(dateKey);

      if (completionData != null) {
        final parts = completionData.split(':');
        if (parts.length == 2) {
          return {
            'total': int.parse(parts[0]),
            'completed': int.parse(parts[1]),
          };
        }
      }
      return null;
    } catch (e) {
      print('Completion get error: $e');
      return null;
    }
  }

  /// Bugün celebration gösterildi mi kontrol et
  static Future<bool> wasCelebrationShownToday(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final celebrationKey =
          _celebrationShownKey + date.toIso8601String().split('T')[0];
      return prefs.getBool(celebrationKey) ?? false;
    } catch (e) {
      print('Celebration check error: $e');
      return false;
    }
  }

  /// Bugün celebration gösterildi olarak işaretle
  static Future<void> markCelebrationShownToday(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final celebrationKey =
          _celebrationShownKey + date.toIso8601String().split('T')[0];
      await prefs.setBool(celebrationKey, true);
    } catch (e) {
      print('Celebration mark error: $e');
    }
  }

  /// Tüm tasklar tamamlandı mı kontrol et
  static Future<bool> areAllTasksCompleted(
    DateTime date,
    int totalTodos,
    int completedTodos,
  ) async {
    if (totalTodos == 0) return false;
    return totalTodos == completedTodos;
  }

  /// Celebration gösterilmeli mi kontrol et
  static Future<bool> shouldShowCelebration(
    DateTime date,
    int totalTodos,
    int completedTodos,
  ) async {
    // Tüm tasklar tamamlandı mı?
    final allCompleted = await areAllTasksCompleted(
      date,
      totalTodos,
      completedTodos,
    );
    if (!allCompleted) return false;

    // Bugün daha önce celebration gösterildi mi?
    final wasShown = await wasCelebrationShownToday(date);
    if (wasShown) return false;

    return true;
  }
}
