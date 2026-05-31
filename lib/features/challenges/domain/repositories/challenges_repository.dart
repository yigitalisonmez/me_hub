import '../entities/challenge.dart';
import '../entities/weekly_goal.dart';
import '../entities/badge.dart';
import '../entities/user_progress.dart';

/// Repository interface for challenges feature
abstract class ChallengesRepository {
  // ============ CHALLENGES ============

  /// Get all active challenges the user has joined
  Future<List<Challenge>> getActiveChallenges();

  /// Get all available challenges to join
  Future<List<Challenge>> getAvailableChallenges();

  /// Get a specific challenge by ID
  Future<Challenge?> getChallenge(String id);

  /// Join a challenge
  Future<void> joinChallenge(Challenge challenge);

  /// Update challenge progress
  Future<void> updateChallenge(Challenge challenge);

  /// Mark today as complete for a challenge
  Future<void> markChallengeComplete(String challengeId, DateTime date);

  /// Use a streak freeze for a challenge
  Future<void> useStreakFreeze(String challengeId, DateTime date);

  /// Delete a challenge
  Future<void> deleteChallenge(String challengeId);

  // ============ WEEKLY GOALS ============

  /// Get all weekly goals for the current week
  Future<List<WeeklyGoal>> getCurrentWeekGoals();

  /// Get weekly goal by ID
  Future<WeeklyGoal?> getWeeklyGoal(String id);

  /// Create a new weekly goal
  Future<void> createWeeklyGoal(WeeklyGoal goal);

  /// Update weekly goal progress
  Future<void> updateWeeklyGoal(WeeklyGoal goal);

  /// Mark a day as complete for a weekly goal
  Future<void> markWeeklyGoalDayComplete(
    String goalId,
    int dayIndex,
    bool completed,
  );

  /// Delete a weekly goal
  Future<void> deleteWeeklyGoal(String goalId);

  // ============ BADGES ============

  /// Get all badges (both locked and unlocked)
  Future<List<Badge>> getAllBadges();

  /// Get only unlocked badges
  Future<List<Badge>> getUnlockedBadges();

  /// Get a specific badge by ID
  Future<Badge?> getBadge(String id);

  /// Unlock a badge
  Future<void> unlockBadge(String badgeId);

  /// Initialize default badges
  Future<void> initializeBadges(List<Badge> badges);

  // ============ USER PROGRESS ============

  /// Get user progress
  Future<UserProgress> getUserProgress();

  /// Update user progress
  Future<void> updateUserProgress(UserProgress progress);

  /// Add XP to user
  Future<UserProgress> addXp(int amount);

  /// Use a streak freeze token
  Future<UserProgress> useStreakFreezeToken();

  /// Earn a streak freeze token
  Future<UserProgress> earnStreakFreezeToken();
}
