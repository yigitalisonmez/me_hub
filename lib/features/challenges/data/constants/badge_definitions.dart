import 'package:flutter/material.dart' hide Badge;
import '../../domain/entities/badge.dart';

/// Pre-defined badges available in the app
class BadgeDefinitions {
  static List<Badge> getAllBadges() => [
    // ============ STREAK BADGES ============
    Badge(
      id: 'streak_7',
      name: 'Week Warrior',
      description: 'Complete tasks 7 days in a row',
      tier: BadgeTier.bronze,
      iconCodePoint: Icons.local_fire_department.codePoint,
      requirementType: BadgeRequirementType.streak,
      requirementValue: 7,
      xpReward: 50,
    ),
    Badge(
      id: 'streak_21',
      name: 'Habit Builder',
      description: 'Complete tasks 21 days in a row',
      tier: BadgeTier.silver,
      iconCodePoint: Icons.whatshot.codePoint,
      requirementType: BadgeRequirementType.streak,
      requirementValue: 21,
      xpReward: 150,
    ),
    Badge(
      id: 'streak_30',
      name: 'Monthly Master',
      description: 'Complete tasks 30 days in a row',
      tier: BadgeTier.gold,
      iconCodePoint: Icons.emoji_events.codePoint,
      requirementType: BadgeRequirementType.streak,
      requirementValue: 30,
      xpReward: 300,
    ),
    Badge(
      id: 'streak_100',
      name: 'Century Legend',
      description: 'Complete tasks 100 days in a row',
      tier: BadgeTier.platinum,
      iconCodePoint: Icons.star.codePoint,
      requirementType: BadgeRequirementType.streak,
      requirementValue: 100,
      xpReward: 1000,
    ),

    // ============ WATER BADGES ============
    Badge(
      id: 'water_1L',
      name: 'Hydration Starter',
      description: 'Drink 1 liter of water total',
      tier: BadgeTier.bronze,
      iconCodePoint: Icons.water_drop.codePoint,
      requirementType: BadgeRequirementType.totalWater,
      requirementValue: 1000,
      xpReward: 25,
    ),
    Badge(
      id: 'water_10L',
      name: 'Water Warrior',
      description: 'Drink 10 liters of water total',
      tier: BadgeTier.silver,
      iconCodePoint: Icons.water.codePoint,
      requirementType: BadgeRequirementType.totalWater,
      requirementValue: 10000,
      xpReward: 100,
    ),
    Badge(
      id: 'water_100L',
      name: 'Ocean Master',
      description: 'Drink 100 liters of water total',
      tier: BadgeTier.gold,
      iconCodePoint: Icons.waves.codePoint,
      requirementType: BadgeRequirementType.totalWater,
      requirementValue: 100000,
      xpReward: 500,
    ),

    // ============ TASK BADGES ============
    Badge(
      id: 'tasks_10',
      name: 'Task Starter',
      description: 'Complete 10 tasks total',
      tier: BadgeTier.bronze,
      iconCodePoint: Icons.check_circle.codePoint,
      requirementType: BadgeRequirementType.totalTasks,
      requirementValue: 10,
      xpReward: 25,
    ),
    Badge(
      id: 'tasks_50',
      name: 'Productivity Pro',
      description: 'Complete 50 tasks total',
      tier: BadgeTier.silver,
      iconCodePoint: Icons.task_alt.codePoint,
      requirementType: BadgeRequirementType.totalTasks,
      requirementValue: 50,
      xpReward: 100,
    ),
    Badge(
      id: 'tasks_100',
      name: 'Task Master',
      description: 'Complete 100 tasks total',
      tier: BadgeTier.gold,
      iconCodePoint: Icons.military_tech.codePoint,
      requirementType: BadgeRequirementType.totalTasks,
      requirementValue: 100,
      xpReward: 250,
    ),

    // ============ CHALLENGE BADGES ============
    Badge(
      id: 'first_challenge',
      name: 'Challenger',
      description: 'Complete your first challenge',
      tier: BadgeTier.bronze,
      iconCodePoint: Icons.flag.codePoint,
      requirementType: BadgeRequirementType.challengesCompleted,
      requirementValue: 1,
      xpReward: 50,
    ),
    Badge(
      id: 'challenge_5',
      name: 'Goal Getter',
      description: 'Complete 5 challenges',
      tier: BadgeTier.silver,
      iconCodePoint: Icons.sports_score.codePoint,
      requirementType: BadgeRequirementType.challengesCompleted,
      requirementValue: 5,
      xpReward: 200,
    ),
    Badge(
      id: 'challenge_10',
      name: 'Champion',
      description: 'Complete 10 challenges',
      tier: BadgeTier.gold,
      iconCodePoint: Icons.workspace_premium.codePoint,
      requirementType: BadgeRequirementType.challengesCompleted,
      requirementValue: 10,
      xpReward: 500,
    ),

    // ============ SPECIAL BADGES ============
    Badge(
      id: 'early_bird',
      name: 'Early Bird',
      description: 'Complete a task before 7 AM',
      tier: BadgeTier.bronze,
      iconCodePoint: Icons.wb_sunny.codePoint,
      requirementType: BadgeRequirementType.specialAction,
      requirementValue: 1,
      xpReward: 30,
    ),
    Badge(
      id: 'night_owl',
      name: 'Night Owl',
      description: 'Complete a task after 11 PM',
      tier: BadgeTier.bronze,
      iconCodePoint: Icons.nightlight_round.codePoint,
      requirementType: BadgeRequirementType.specialAction,
      requirementValue: 1,
      xpReward: 30,
    ),
    Badge(
      id: 'perfect_week',
      name: 'Perfect Week',
      description: 'Complete all daily goals for 7 days',
      tier: BadgeTier.gold,
      iconCodePoint: Icons.calendar_month.codePoint,
      requirementType: BadgeRequirementType.specialAction,
      requirementValue: 7,
      xpReward: 200,
    ),
  ];

  /// Get color for badge tier
  static Color getTierColor(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case BadgeTier.silver:
        return const Color(0xFFC0C0C0);
      case BadgeTier.gold:
        return const Color(0xFFFFD700);
      case BadgeTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  /// Get tier name
  static String getTierName(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return 'Bronze';
      case BadgeTier.silver:
        return 'Silver';
      case BadgeTier.gold:
        return 'Gold';
      case BadgeTier.platinum:
        return 'Platinum';
    }
  }
}
