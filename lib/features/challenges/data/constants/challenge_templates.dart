import 'package:flutter/material.dart';
import '../../domain/entities/challenge.dart';

/// Pre-defined challenge templates
class ChallengeTemplates {
  static List<Challenge> getAvailableChallenges() {
    final now = DateTime.now();
    return [
      // ============ WATER CHALLENGES ============
      Challenge(
        id: 'water_30',
        title: '30 Day Water Challenge',
        description: 'Drink at least 2 liters of water every day',
        category: ChallengeCategory.health,
        durationDays: 30,
        startDateTimestamp: now.millisecondsSinceEpoch,
        dailyProgress: [],
        iconCodePoint: Icons.water_drop.codePoint,
        xpReward: 300,
        linkedFeature: 'water',
      ),
      Challenge(
        id: 'water_7',
        title: '7 Day Hydration',
        description: 'Reach your daily water goal for one week',
        category: ChallengeCategory.health,
        durationDays: 7,
        startDateTimestamp: now.millisecondsSinceEpoch,
        dailyProgress: [],
        iconCodePoint: Icons.local_drink.codePoint,
        xpReward: 70,
        linkedFeature: 'water',
      ),

      // ============ MINDFULNESS CHALLENGES ============
      Challenge(
        id: 'gratitude_30',
        title: '30 Day Gratitude',
        description: 'Write in your gratitude journal every day',
        category: ChallengeCategory.mindfulness,
        durationDays: 30,
        startDateTimestamp: now.millisecondsSinceEpoch,
        dailyProgress: [],
        iconCodePoint: Icons.favorite.codePoint,
        xpReward: 300,
        linkedFeature: 'gratitude',
      ),
      Challenge(
        id: 'mood_21',
        title: '21 Day Mood Tracking',
        description: 'Log your mood every day',
        category: ChallengeCategory.mindfulness,
        durationDays: 21,
        startDateTimestamp: now.millisecondsSinceEpoch,
        dailyProgress: [],
        iconCodePoint: Icons.mood.codePoint,
        xpReward: 210,
        linkedFeature: 'mood',
      ),
      Challenge(
        id: 'breathing_14',
        title: '14 Day Breathing',
        description: 'Practice breathing exercises daily',
        category: ChallengeCategory.mindfulness,
        durationDays: 14,
        startDateTimestamp: now.millisecondsSinceEpoch,
        dailyProgress: [],
        iconCodePoint: Icons.air.codePoint,
        xpReward: 140,
        linkedFeature: 'breathing',
      ),

      // ============ PRODUCTIVITY CHALLENGES ============
      Challenge(
        id: 'tasks_30',
        title: '30 Day Productivity',
        description: 'Complete at least one task every day',
        category: ChallengeCategory.productivity,
        durationDays: 30,
        startDateTimestamp: now.millisecondsSinceEpoch,
        dailyProgress: [],
        iconCodePoint: Icons.task_alt.codePoint,
        xpReward: 300,
        linkedFeature: 'todos',
      ),
      Challenge(
        id: 'routine_21',
        title: '21 Day Routine',
        description: 'Complete your routines every day',
        category: ChallengeCategory.productivity,
        durationDays: 21,
        startDateTimestamp: now.millisecondsSinceEpoch,
        dailyProgress: [],
        iconCodePoint: Icons.repeat.codePoint,
        xpReward: 210,
        linkedFeature: 'routines',
      ),

      // ============ WELLNESS CHALLENGES ============
      Challenge(
        id: 'affirmation_30',
        title: '30 Day Affirmations',
        description: 'Listen to your affirmations every day',
        category: ChallengeCategory.mindfulness,
        durationDays: 30,
        startDateTimestamp: now.millisecondsSinceEpoch,
        dailyProgress: [],
        iconCodePoint: Icons.record_voice_over.codePoint,
        xpReward: 300,
        linkedFeature: 'affirmations',
      ),
    ];
  }

  /// Get category color
  static Color getCategoryColor(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.health:
        return const Color(0xFF4CAF50);
      case ChallengeCategory.mindfulness:
        return const Color(0xFF9C27B0);
      case ChallengeCategory.productivity:
        return const Color(0xFF2196F3);
      case ChallengeCategory.social:
        return const Color(0xFFFF9800);
    }
  }

  /// Get category name
  static String getCategoryName(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.health:
        return 'Health';
      case ChallengeCategory.mindfulness:
        return 'Mindfulness';
      case ChallengeCategory.productivity:
        return 'Productivity';
      case ChallengeCategory.social:
        return 'Social';
    }
  }

  /// Get category icon
  static IconData getCategoryIcon(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.health:
        return Icons.favorite;
      case ChallengeCategory.mindfulness:
        return Icons.self_improvement;
      case ChallengeCategory.productivity:
        return Icons.trending_up;
      case ChallengeCategory.social:
        return Icons.people;
    }
  }
}
