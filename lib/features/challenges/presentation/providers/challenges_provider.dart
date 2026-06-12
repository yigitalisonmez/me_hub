import 'package:flutter/material.dart' hide Badge;

import '../../data/constants/badge_definitions.dart';
import '../../data/constants/challenge_templates.dart';
import '../../data/repositories/challenges_repository_impl.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/weekly_goal.dart';
import '../../domain/entities/badge.dart';
import '../../domain/entities/user_progress.dart';
import '../../../../core/reminders/domain/reminder_feature.dart';
import '../../../../core/reminders/services/reminder_coordinator.dart';

/// Provider for managing challenges, goals, badges, and user progress
class ChallengesProvider with ChangeNotifier {
  final ChallengesRepositoryImpl _repository;
  final ReminderCoordinator? _reminders;

  ChallengesProvider(this._repository, {ReminderCoordinator? reminders})
    : _reminders = reminders;

  // State
  List<Challenge> _activeChallenges = [];
  List<Challenge> _availableChallenges = [];
  List<WeeklyGoal> _weeklyGoals = [];
  List<Badge> _allBadges = [];
  UserProgress _userProgress = const UserProgress();
  bool _isLoading = false;
  String? _error;
  Badge? _lastUnlockedBadge; // For showing unlock animation

  // Getters
  List<Challenge> get activeChallenges => _activeChallenges;
  List<Challenge> get availableChallenges => _availableChallenges;
  List<WeeklyGoal> get weeklyGoals => _weeklyGoals;
  List<Badge> get allBadges => _allBadges;
  List<Badge> get unlockedBadges =>
      _allBadges.where((b) => b.isUnlocked).toList();
  UserProgress get userProgress => _userProgress;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Badge? get lastUnlockedBadge => _lastUnlockedBadge;
  int get totalXp => _userProgress.totalXp;
  int get currentLevel => _userProgress.currentLevel;
  double get levelProgress => _userProgress.levelProgress;
  int get streakFreezeTokens => _userProgress.streakFreezeTokens;

  /// Initialize data
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Initialize badges from definitions
      await _repository.initializeBadges(BadgeDefinitions.getAllBadges());

      // Load all data
      await Future.wait([
        _loadChallenges(),
        _loadWeeklyGoals(),
        _loadBadges(),
        _loadUserProgress(),
      ]);

      // Update available challenges
      _updateAvailableChallenges();
      await _reconcileReminders();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing ChallengesProvider: $e');
    }
    _setLoading(false);
  }

  Future<void> _loadChallenges() async {
    _activeChallenges = await _repository.getActiveChallenges();
  }

  Future<void> _loadWeeklyGoals() async {
    _weeklyGoals = await _repository.getCurrentWeekGoals();
  }

  Future<void> _loadBadges() async {
    _allBadges = await _repository.getAllBadges();
  }

  Future<void> _loadUserProgress() async {
    _userProgress = await _repository.getUserProgress();
  }

  void _updateAvailableChallenges() {
    final activeIds = _activeChallenges.map((c) => c.id).toSet();
    _availableChallenges = ChallengeTemplates.getAvailableChallenges()
        .where((c) => !activeIds.contains(c.id))
        .toList();
  }

  /// Join a challenge
  Future<void> joinChallenge(Challenge challenge) async {
    try {
      final now = DateTime.now();
      final newChallenge = challenge.copyWith(
        startDateTimestamp: now.millisecondsSinceEpoch,
        dailyProgress: [],
        isActive: true,
      );

      await _repository.joinChallenge(newChallenge);
      _activeChallenges.add(newChallenge);
      _updateAvailableChallenges();
      notifyListeners();
      await _reconcileReminders();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error joining challenge: $e');
    }
  }

  /// Mark today as complete for a challenge
  Future<void> markChallengeComplete(String challengeId) async {
    try {
      final now = DateTime.now();
      await _repository.markChallengeComplete(challengeId, now);

      // Reload challenges
      await _loadChallenges();

      // Award XP
      await _repository.addXp(10);
      await _loadUserProgress();

      // Check for badge unlocks
      await checkAndAwardBadges();

      notifyListeners();
      await _reconcileReminders();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error marking challenge complete: $e');
    }
  }

  /// Use streak freeze for a challenge
  Future<void> useStreakFreeze(String challengeId) async {
    if (_userProgress.streakFreezeTokens <= 0) return;

    try {
      final now = DateTime.now();
      await _repository.useStreakFreeze(challengeId, now);
      await _repository.useStreakFreezeToken();
      await _loadChallenges();
      await _loadUserProgress();
      notifyListeners();
      await _reconcileReminders();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error using streak freeze: $e');
    }
  }

  /// Create a weekly goal
  Future<void> createWeeklyGoal(WeeklyGoal goal) async {
    try {
      await _repository.createWeeklyGoal(goal);
      _weeklyGoals.add(goal);
      notifyListeners();
      await _reconcileReminders();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating weekly goal: $e');
    }
  }

  /// Mark weekly goal day as complete
  Future<void> markWeeklyGoalDay(
    String goalId,
    int dayIndex,
    bool completed,
  ) async {
    try {
      await _repository.markWeeklyGoalDayComplete(goalId, dayIndex, completed);
      await _loadWeeklyGoals();

      if (completed) {
        await _repository.addXp(5);
        await _loadUserProgress();
      }

      notifyListeners();
      await _reconcileReminders();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error marking weekly goal day: $e');
    }
  }

  /// Check and award badges based on current progress
  Future<void> checkAndAwardBadges() async {
    try {
      for (final badge in _allBadges) {
        if (badge.isUnlocked) continue;

        bool shouldUnlock = false;

        switch (badge.requirementType) {
          case BadgeRequirementType.streak:
            // Check longest streak across all challenges
            final maxStreak = _activeChallenges.fold<int>(
              0,
              (max, c) => c.currentStreak > max ? c.currentStreak : max,
            );
            shouldUnlock = maxStreak >= badge.requirementValue;
            break;

          case BadgeRequirementType.challengesCompleted:
            shouldUnlock =
                _userProgress.challengesCompleted >= badge.requirementValue;
            break;

          case BadgeRequirementType.totalWater:
          case BadgeRequirementType.totalTasks:
          case BadgeRequirementType.specialAction:
            // These are checked externally via updateExternalProgress
            break;
        }

        if (shouldUnlock) {
          await _unlockBadge(badge.id);
        }
      }
    } catch (e) {
      debugPrint('Error checking badges: $e');
    }
  }

  Future<void> _reconcileReminders() async {
    final now = DateTime.now();
    final activeChallenges = _activeChallenges.where(
      (challenge) => !challenge.isCompleted,
    );
    final activeGoals = _weeklyGoals.where((goal) => !goal.isCompleted);
    final actionable = activeChallenges.isNotEmpty || activeGoals.isNotEmpty;
    final completedToday =
        actionable &&
        activeChallenges.every(
          (challenge) => challenge.isTodayCompleted(now),
        ) &&
        activeGoals.every((goal) => goal.isTodayCompleted(now));
    await _reminders?.reconcileDailyFeature(
      feature: ReminderFeature.challenges,
      completedToday: completedToday,
      actionable: actionable,
      title: 'Today’s challenge check-in',
      body: 'Mark today’s progress while it is still fresh.',
      payload: 'kora://challenges',
    );
  }

  /// Unlock a badge and award XP
  Future<void> _unlockBadge(String badgeId) async {
    final badge = _allBadges.firstWhere((b) => b.id == badgeId);
    if (badge.isUnlocked) return;

    await _repository.unlockBadge(badgeId);
    await _repository.addXp(badge.xpReward);

    final unlockedBadge = badge.unlock();
    _lastUnlockedBadge = unlockedBadge;

    await _loadBadges();
    await _loadUserProgress();
    notifyListeners();
  }

  /// Clear last unlocked badge (after showing animation)
  void clearLastUnlockedBadge() {
    _lastUnlockedBadge = null;
    notifyListeners();
  }

  /// Update external progress (called from other providers)
  Future<void> updateExternalProgress({
    int? totalWaterMl,
    int? totalTasksCompleted,
    int? currentStreak,
  }) async {
    try {
      // Check water badges
      if (totalWaterMl != null) {
        for (final badge in _allBadges) {
          if (!badge.isUnlocked &&
              badge.requirementType == BadgeRequirementType.totalWater &&
              totalWaterMl >= badge.requirementValue) {
            await _unlockBadge(badge.id);
          }
        }
      }

      // Check task badges
      if (totalTasksCompleted != null) {
        for (final badge in _allBadges) {
          if (!badge.isUnlocked &&
              badge.requirementType == BadgeRequirementType.totalTasks &&
              totalTasksCompleted >= badge.requirementValue) {
            await _unlockBadge(badge.id);
          }
        }
      }

      // Update longest streak if higher
      if (currentStreak != null &&
          currentStreak > _userProgress.longestStreak) {
        final updated = _userProgress.copyWith(longestStreak: currentStreak);
        await _repository.updateUserProgress(updated);
        await _loadUserProgress();

        // Award streak freeze every 7 days
        if (currentStreak % 7 == 0) {
          await _repository.earnStreakFreezeToken();
          await _loadUserProgress();
        }
      }

      await checkAndAwardBadges();
    } catch (e) {
      debugPrint('Error updating external progress: $e');
    }
  }

  /// Delete a challenge
  Future<void> deleteChallenge(String challengeId) async {
    try {
      await _repository.deleteChallenge(challengeId);
      _activeChallenges.removeWhere((c) => c.id == challengeId);
      _updateAvailableChallenges();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting challenge: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
