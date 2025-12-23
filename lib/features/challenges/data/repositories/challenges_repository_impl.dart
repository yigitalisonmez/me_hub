import '../../domain/entities/challenge.dart';
import '../../domain/entities/weekly_goal.dart';
import '../../domain/entities/badge.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/repositories/challenges_repository.dart';
import '../datasources/challenges_local_datasource.dart';

/// Implementation of ChallengesRepository using local storage
class ChallengesRepositoryImpl implements ChallengesRepository {
  final ChallengesLocalDataSource _dataSource;

  ChallengesRepositoryImpl(this._dataSource);

  // ============ CHALLENGES ============

  @override
  Future<List<Challenge>> getActiveChallenges() async {
    return _dataSource.getActiveChallenges();
  }

  @override
  Future<List<Challenge>> getAvailableChallenges() async {
    // Available challenges are handled in the provider via templates
    return [];
  }

  @override
  Future<Challenge?> getChallenge(String id) async {
    return _dataSource.getChallenge(id);
  }

  @override
  Future<void> joinChallenge(Challenge challenge) async {
    await _dataSource.saveChallenge(challenge);
  }

  @override
  Future<void> updateChallenge(Challenge challenge) async {
    await _dataSource.saveChallenge(challenge);
  }

  @override
  Future<void> markChallengeComplete(String challengeId, DateTime date) async {
    final challenge = _dataSource.getChallenge(challengeId);
    if (challenge == null) return;

    final timestamp = DateTime(
      date.year,
      date.month,
      date.day,
    ).millisecondsSinceEpoch;

    // Check if already marked
    final alreadyMarked = challenge.dailyProgress.any(
      (p) => p.dateTimestamp == timestamp,
    );
    if (alreadyMarked) return;

    final updatedProgress = [
      ...challenge.dailyProgress,
      DailyProgress(dateTimestamp: timestamp, completed: true),
    ];

    await _dataSource.saveChallenge(
      challenge.copyWith(dailyProgress: updatedProgress),
    );
  }

  @override
  Future<void> useStreakFreeze(String challengeId, DateTime date) async {
    final challenge = _dataSource.getChallenge(challengeId);
    if (challenge == null || challenge.streakFreezeCount <= 0) return;

    final timestamp = DateTime(
      date.year,
      date.month,
      date.day,
    ).millisecondsSinceEpoch;

    final updatedProgress = [
      ...challenge.dailyProgress,
      DailyProgress(
        dateTimestamp: timestamp,
        completed: false,
        usedFreeze: true,
      ),
    ];

    await _dataSource.saveChallenge(
      challenge.copyWith(
        dailyProgress: updatedProgress,
        streakFreezeCount: challenge.streakFreezeCount - 1,
      ),
    );
  }

  @override
  Future<void> deleteChallenge(String challengeId) async {
    await _dataSource.deleteChallenge(challengeId);
  }

  // ============ WEEKLY GOALS ============

  @override
  Future<List<WeeklyGoal>> getCurrentWeekGoals() async {
    return _dataSource.getCurrentWeekGoals();
  }

  @override
  Future<WeeklyGoal?> getWeeklyGoal(String id) async {
    return _dataSource.getWeeklyGoal(id);
  }

  @override
  Future<void> createWeeklyGoal(WeeklyGoal goal) async {
    await _dataSource.saveWeeklyGoal(goal);
  }

  @override
  Future<void> updateWeeklyGoal(WeeklyGoal goal) async {
    await _dataSource.saveWeeklyGoal(goal);
  }

  @override
  Future<void> markWeeklyGoalDayComplete(
    String goalId,
    int dayIndex,
    bool completed,
  ) async {
    final goal = _dataSource.getWeeklyGoal(goalId);
    if (goal == null || dayIndex < 0 || dayIndex >= 7) return;

    final updatedChecklist = List<bool>.from(goal.dailyChecklist);
    updatedChecklist[dayIndex] = completed;

    await _dataSource.saveWeeklyGoal(
      goal.copyWith(dailyChecklist: updatedChecklist),
    );
  }

  @override
  Future<void> deleteWeeklyGoal(String goalId) async {
    await _dataSource.deleteWeeklyGoal(goalId);
  }

  // ============ BADGES ============

  @override
  Future<List<Badge>> getAllBadges() async {
    return _dataSource.getAllBadges();
  }

  @override
  Future<List<Badge>> getUnlockedBadges() async {
    return _dataSource.getUnlockedBadges();
  }

  @override
  Future<Badge?> getBadge(String id) async {
    return _dataSource.getBadge(id);
  }

  @override
  Future<void> unlockBadge(String badgeId) async {
    final badge = _dataSource.getBadge(badgeId);
    if (badge == null || badge.isUnlocked) return;

    await _dataSource.saveBadge(badge.unlock());
  }

  @override
  Future<void> initializeBadges(List<Badge> badges) async {
    await _dataSource.initializeBadges(badges);
  }

  // ============ USER PROGRESS ============

  @override
  Future<UserProgress> getUserProgress() async {
    return _dataSource.getUserProgress();
  }

  @override
  Future<void> updateUserProgress(UserProgress progress) async {
    await _dataSource.saveUserProgress(progress);
  }

  @override
  Future<UserProgress> addXp(int amount) async {
    final progress = _dataSource.getUserProgress();
    final updated = progress.addXp(amount);
    await _dataSource.saveUserProgress(updated);
    return updated;
  }

  @override
  Future<UserProgress> useStreakFreezeToken() async {
    final progress = _dataSource.getUserProgress();
    final updated = progress.useStreakFreeze();
    await _dataSource.saveUserProgress(updated);
    return updated;
  }

  @override
  Future<UserProgress> earnStreakFreezeToken() async {
    final progress = _dataSource.getUserProgress();
    final updated = progress.earnStreakFreeze();
    await _dataSource.saveUserProgress(updated);
    return updated;
  }
}
