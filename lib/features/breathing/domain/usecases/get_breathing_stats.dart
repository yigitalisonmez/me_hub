import '../repositories/breathing_repository.dart';
import '../../../../core/utils/result.dart';

/// Breathing statistics data class
class BreathingStats {
  final int totalMinutes;
  final int currentStreak;
  final int sessionCount;

  const BreathingStats({
    required this.totalMinutes,
    required this.currentStreak,
    required this.sessionCount,
  });
}

/// Use case for getting breathing statistics
class GetBreathingStats {
  final BreathingRepository repository;

  GetBreathingStats(this.repository);

  Future<Result<BreathingStats>> call() async {
    final sessionsResult = await repository.getSessions();
    final totalMinutesResult = await repository.getTotalMinutes();
    final streakResult = await repository.getCurrentStreak();

    if (sessionsResult is! Success ||
        totalMinutesResult is! Success ||
        streakResult is! Success) {
      return Error(message: 'Failed to load breathing stats');
    }

    return Success(
      BreathingStats(
        totalMinutes: totalMinutesResult.data ?? 0,
        currentStreak: streakResult.data ?? 0,
        sessionCount: (sessionsResult.data ?? []).length,
      ),
    );
  }
}
