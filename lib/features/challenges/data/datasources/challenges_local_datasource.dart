import 'package:flutter/material.dart' hide Badge;
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/challenge.dart';
import '../../domain/entities/weekly_goal.dart';
import '../../domain/entities/badge.dart';
import '../../domain/entities/user_progress.dart';

/// Local data source for challenges feature using Hive
class ChallengesLocalDataSource {
  static const String _challengesBoxName = 'challenges';
  static const String _weeklyGoalsBoxName = 'weekly_goals';
  static const String _badgesBoxName = 'badges';
  static const String _userProgressBoxName = 'user_progress';

  Box<Challenge>? _challengesBox;
  Box<WeeklyGoal>? _weeklyGoalsBox;
  Box<Badge>? _badgesBox;
  Box<UserProgress>? _userProgressBox;

  bool _isInitialized = false;

  /// Initialize all Hive boxes
  Future<void> init() async {
    if (_isInitialized) return;

    _challengesBox = await Hive.openBox<Challenge>(_challengesBoxName);
    _weeklyGoalsBox = await Hive.openBox<WeeklyGoal>(_weeklyGoalsBoxName);
    _badgesBox = await Hive.openBox<Badge>(_badgesBoxName);
    _userProgressBox = await Hive.openBox<UserProgress>(_userProgressBoxName);

    _isInitialized = true;
    debugPrint('ChallengesLocalDataSource initialized');
  }

  // ============ CHALLENGES ============

  /// Get all challenges
  List<Challenge> getAllChallenges() {
    return _challengesBox?.values.toList() ?? [];
  }

  /// Get active challenges
  List<Challenge> getActiveChallenges() {
    return getAllChallenges()
        .where((c) => c.isActive && !c.isCompleted)
        .toList();
  }

  /// Get challenge by ID
  Challenge? getChallenge(String id) {
    return _challengesBox?.get(id);
  }

  /// Save a challenge
  Future<void> saveChallenge(Challenge challenge) async {
    await _challengesBox?.put(challenge.id, challenge);
  }

  /// Delete a challenge
  Future<void> deleteChallenge(String id) async {
    await _challengesBox?.delete(id);
  }

  // ============ WEEKLY GOALS ============

  /// Get all weekly goals
  List<WeeklyGoal> getAllWeeklyGoals() {
    return _weeklyGoalsBox?.values.toList() ?? [];
  }

  /// Get current week goals
  List<WeeklyGoal> getCurrentWeekGoals() {
    final now = DateTime.now();
    // Find Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 7));

    return getAllWeeklyGoals().where((g) {
      final goalWeekStart = g.weekStartDate;
      return goalWeekStart.isAfter(
            weekStart.subtract(const Duration(days: 1)),
          ) &&
          goalWeekStart.isBefore(weekEnd);
    }).toList();
  }

  /// Get weekly goal by ID
  WeeklyGoal? getWeeklyGoal(String id) {
    return _weeklyGoalsBox?.get(id);
  }

  /// Save a weekly goal
  Future<void> saveWeeklyGoal(WeeklyGoal goal) async {
    await _weeklyGoalsBox?.put(goal.id, goal);
  }

  /// Delete a weekly goal
  Future<void> deleteWeeklyGoal(String id) async {
    await _weeklyGoalsBox?.delete(id);
  }

  // ============ BADGES ============

  /// Get all badges
  List<Badge> getAllBadges() {
    return _badgesBox?.values.toList() ?? [];
  }

  /// Get unlocked badges
  List<Badge> getUnlockedBadges() {
    return getAllBadges().where((b) => b.isUnlocked).toList();
  }

  /// Get badge by ID
  Badge? getBadge(String id) {
    return _badgesBox?.get(id);
  }

  /// Save a badge
  Future<void> saveBadge(Badge badge) async {
    await _badgesBox?.put(badge.id, badge);
  }

  /// Initialize badges from definitions
  Future<void> initializeBadges(List<Badge> badges) async {
    for (final badge in badges) {
      if (_badgesBox?.get(badge.id) == null) {
        await _badgesBox?.put(badge.id, badge);
      }
    }
  }

  // ============ USER PROGRESS ============

  /// Get user progress
  UserProgress getUserProgress() {
    return _userProgressBox?.get('user') ?? const UserProgress();
  }

  /// Save user progress
  Future<void> saveUserProgress(UserProgress progress) async {
    await _userProgressBox?.put('user', progress);
  }

  // ============ CLEANUP ============

  /// Close all boxes
  Future<void> close() async {
    await _challengesBox?.close();
    await _weeklyGoalsBox?.close();
    await _badgesBox?.close();
    await _userProgressBox?.close();
    _isInitialized = false;
  }
}
