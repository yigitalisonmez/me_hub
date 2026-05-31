import 'package:hive_flutter/hive_flutter.dart';

/// Aggregated user progress and XP
class UserProgress {
  final int totalXp;
  final int currentLevel;
  final int longestStreak;
  final int challengesCompleted;
  final int badgesUnlocked;
  final List<String> unlockedBadgeIds;
  final int streakFreezeTokens;

  const UserProgress({
    this.totalXp = 0,
    this.currentLevel = 1,
    this.longestStreak = 0,
    this.challengesCompleted = 0,
    this.badgesUnlocked = 0,
    this.unlockedBadgeIds = const [],
    this.streakFreezeTokens = 0,
  });

  /// XP required to reach next level
  /// Uses a simple progression: level * 100 XP
  int get xpForNextLevel => currentLevel * 100;

  /// XP progress within current level (0.0 to 1.0)
  double get levelProgress {
    final xpInCurrentLevel = totalXp - _totalXpForLevel(currentLevel - 1);
    return (xpInCurrentLevel / xpForNextLevel).clamp(0.0, 1.0);
  }

  /// Calculate total XP needed to reach a level
  int _totalXpForLevel(int level) {
    // Sum of 1*100 + 2*100 + ... + level*100 = 100 * (level * (level + 1) / 2)
    return 100 * (level * (level + 1) ~/ 2);
  }

  /// Calculate level from total XP
  static int calculateLevel(int totalXp) {
    // Solve: 100 * (level * (level + 1) / 2) <= totalXp
    int level = 1;
    while (_totalXpForLevelStatic(level) <= totalXp) {
      level++;
    }
    return level - 1 > 0 ? level - 1 : 1;
  }

  static int _totalXpForLevelStatic(int level) {
    return 100 * (level * (level + 1) ~/ 2);
  }

  UserProgress copyWith({
    int? totalXp,
    int? currentLevel,
    int? longestStreak,
    int? challengesCompleted,
    int? badgesUnlocked,
    List<String>? unlockedBadgeIds,
    int? streakFreezeTokens,
  }) {
    return UserProgress(
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      longestStreak: longestStreak ?? this.longestStreak,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      badgesUnlocked: badgesUnlocked ?? this.badgesUnlocked,
      unlockedBadgeIds: unlockedBadgeIds ?? List.from(this.unlockedBadgeIds),
      streakFreezeTokens: streakFreezeTokens ?? this.streakFreezeTokens,
    );
  }

  /// Add XP and recalculate level
  UserProgress addXp(int amount) {
    final newTotalXp = totalXp + amount;
    final newLevel = calculateLevel(newTotalXp);
    return copyWith(totalXp: newTotalXp, currentLevel: newLevel);
  }

  /// Unlock a badge
  UserProgress unlockBadge(String badgeId) {
    if (unlockedBadgeIds.contains(badgeId)) return this;
    return copyWith(
      badgesUnlocked: badgesUnlocked + 1,
      unlockedBadgeIds: [...unlockedBadgeIds, badgeId],
    );
  }

  /// Use a streak freeze token
  UserProgress useStreakFreeze() {
    if (streakFreezeTokens <= 0) return this;
    return copyWith(streakFreezeTokens: streakFreezeTokens - 1);
  }

  /// Earn a streak freeze token
  UserProgress earnStreakFreeze() {
    return copyWith(streakFreezeTokens: streakFreezeTokens + 1);
  }
}

// ============ HIVE ADAPTER ============

class UserProgressAdapter extends TypeAdapter<UserProgress> {
  @override
  final int typeId = 53;

  @override
  UserProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProgress(
      totalXp: fields[0] as int? ?? 0,
      currentLevel: fields[1] as int? ?? 1,
      longestStreak: fields[2] as int? ?? 0,
      challengesCompleted: fields[3] as int? ?? 0,
      badgesUnlocked: fields[4] as int? ?? 0,
      unlockedBadgeIds: (fields[5] as List?)?.cast<String>() ?? [],
      streakFreezeTokens: fields[6] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, UserProgress obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.totalXp)
      ..writeByte(1)
      ..write(obj.currentLevel)
      ..writeByte(2)
      ..write(obj.longestStreak)
      ..writeByte(3)
      ..write(obj.challengesCompleted)
      ..writeByte(4)
      ..write(obj.badgesUnlocked)
      ..writeByte(5)
      ..write(obj.unlockedBadgeIds)
      ..writeByte(6)
      ..write(obj.streakFreezeTokens);
  }
}
