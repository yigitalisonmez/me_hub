import 'package:flutter/material.dart' hide Badge;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../data/constants/badge_definitions.dart';
import '../../domain/entities/badge.dart';
import '../../domain/entities/challenge.dart';
import '../providers/challenges_provider.dart';
import '../utils/challenge_icon_lookup.dart';

/// XP Level Progress Bar widget
class XpLevelBar extends StatelessWidget {
  const XpLevelBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final provider = context.watch<ChallengesProvider>();
    final progress = provider.userProgress;

    return ElevatedCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${progress.currentLevel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${progress.currentLevel}',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${progress.totalXp} XP total',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Streak freeze tokens
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.snowflake,
                      color: theme.primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${progress.streakFreezeTokens}',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.levelProgress,
              backgroundColor: theme.surfaceColor,
              valueColor: AlwaysStoppedAnimation(theme.primaryColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress.levelProgress * 100).toInt()}% complete',
                style: TextStyle(color: theme.textSecondary, fontSize: 11),
              ),
              Text(
                'Next: Level ${progress.currentLevel + 1}',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Active Challenge Card widget
class ActiveChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const ActiveChallengeCard({
    super.key,
    required this.challenge,
    this.onComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isCompleteToday = challenge.isTodayCompleted(DateTime.now());

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: ElevatedCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    materialIconFromCodePoint(challenge.iconCodePoint),
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${challenge.durationDays} day challenge',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(
                      LucideIcons.x,
                      color: theme.textSecondary,
                      size: 18,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: challenge.completionPercentage,
                          backgroundColor: theme.surfaceColor,
                          valueColor: AlwaysStoppedAnimation(
                            theme.primaryColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${challenge.daysCompleted}/${challenge.durationDays} days',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Streak flame
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.flame,
                        color: theme.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${challenge.currentStreak}',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Complete button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCompleteToday ? null : onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  disabledBackgroundColor: theme.primaryColor.withValues(
                    alpha: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCompleteToday ? LucideIcons.check : LucideIcons.plus,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCompleteToday ? 'Completed!' : 'Complete Today',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Available Challenge Card (for joining)
class AvailableChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onJoin;

  const AvailableChallengeCard({
    super.key,
    required this.challenge,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                materialIconFromCodePoint(challenge.iconCodePoint),
                color: theme.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    challenge.description,
                    style: TextStyle(color: theme.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildTag('${challenge.durationDays} days', theme),
                      const SizedBox(width: 6),
                      _buildTag('+${challenge.xpReward} XP', theme),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onJoin,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.plus,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.primaryColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Badge Grid widget
class BadgeGrid extends StatelessWidget {
  final List<Badge> badges;
  final bool showAll;

  const BadgeGrid({super.key, required this.badges, this.showAll = false});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final displayBadges = showAll ? badges : badges.take(8).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: displayBadges.length,
      itemBuilder: (context, index) {
        final badge = displayBadges[index];

        return GestureDetector(
          onTap: () => _showBadgeDetails(context, badge),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: badge.isUnlocked
                      ? theme.primaryColor.withValues(alpha: 0.15)
                      : theme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: badge.isUnlocked
                        ? theme.primaryColor.withValues(alpha: 0.5)
                        : theme.textSecondary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  materialIconFromCodePoint(badge.iconCodePoint),
                  color: badge.isUnlocked
                      ? theme.primaryColor
                      : theme.textSecondary.withValues(alpha: 0.4),
                  size: 28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                badge.name,
                style: TextStyle(
                  color: badge.isUnlocked
                      ? theme.textPrimary
                      : theme.textSecondary,
                  fontSize: 9,
                  fontWeight: badge.isUnlocked
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBadgeDetails(BuildContext context, Badge badge) {
    final theme = context.read<ThemeProvider>();
    final tierColor = BadgeDefinitions.getTierColor(badge.tier);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: badge.isUnlocked
                    ? theme.primaryColor.withValues(alpha: 0.15)
                    : theme.backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: badge.isUnlocked
                      ? theme.primaryColor
                      : theme.textSecondary,
                  width: 3,
                ),
              ),
              child: Icon(
                materialIconFromCodePoint(badge.iconCodePoint),
                color: badge.isUnlocked
                    ? theme.primaryColor
                    : theme.textSecondary,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.name,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                BadgeDefinitions.getTierName(badge.tier),
                style: TextStyle(
                  color: tierColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              badge.description,
              style: TextStyle(color: theme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '+${badge.xpReward} XP',
              style: TextStyle(
                color: theme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (badge.isUnlocked && badge.unlockedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Earned: ${_formatDate(badge.unlockedAt!)}',
                style: TextStyle(color: theme.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
