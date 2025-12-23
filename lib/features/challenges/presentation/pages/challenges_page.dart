import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:math' as math;

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../domain/entities/badge.dart';
import '../../data/constants/badge_definitions.dart';
import '../providers/challenges_provider.dart';
import '../widgets/challenges_widgets.dart';

/// Goals & Challenges page - Gamification hub with XP, challenges, and badges
class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _xpAnimController;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _xpAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengesProvider>().initialize();
      _xpAnimController.forward();
    });
  }

  @override
  void dispose() {
    _xpAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final provider = context.watch<ChallengesProvider>();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Skeletonizer(
        enabled: provider.isLoading,
        effect: ShimmerEffect(
          baseColor: theme.isDarkMode
              ? Colors.grey.shade800
              : Colors.grey.shade300,
          highlightColor: theme.isDarkMode
              ? Colors.grey.shade700
              : Colors.grey.shade100,
        ),
        child: CustomScrollView(
          slivers: [
            // Hero Header with gradient
            _buildHeroHeader(theme, provider),

            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      const SizedBox(height: 24),

                      // Stats Row
                      _buildStatsRow(theme, provider),
                      const SizedBox(height: 24),

                      // Active Challenges Section
                      _buildSectionHeader(theme, 'Active Challenges'),
                      const SizedBox(height: 12),
                      _buildActiveChallenges(theme, provider),
                      const SizedBox(height: 24),

                      // Recent Badge Highlight
                      if (provider.unlockedBadges.isNotEmpty) ...[
                        _buildRecentBadge(theme, provider),
                        const SizedBox(height: 24),
                      ],

                      // Badges Preview
                      _buildSectionHeader(
                        theme,
                        'Badges',
                        trailing: GestureDetector(
                          onTap: () => _showAllBadges(context, provider),
                          child: Text(
                            'See All',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBadgesPreview(theme, provider),
                      const SizedBox(height: 24),

                      // Category Tabs for Available Challenges
                      if (provider.availableChallenges.isNotEmpty) ...[
                        _buildSectionHeader(theme, 'Start New Challenge'),
                        const SizedBox(height: 12),
                        _buildCategoryTabs(theme),
                        const SizedBox(height: 16),
                        _buildAvailableChallenges(theme, provider),
                      ],

                      SizedBox(
                        height: LayoutConstants.getNavbarClearance(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hero header with gradient and XP ring
  Widget _buildHeroHeader(ThemeProvider theme, ChallengesProvider provider) {
    final progress = provider.userProgress;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: theme.backgroundColor,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.settings, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Goals & Challenges',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.8),
                theme.backgroundColor,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: Icon(
                  LucideIcons.trophy,
                  size: 24,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              Positioned(
                top: 80,
                right: 80,
                child: Icon(
                  LucideIcons.sparkles,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),

              // XP Ring - Center
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _xpAnimController,
                    builder: (context, child) {
                      return _AnimatedXpRing(
                        level: progress.currentLevel,
                        progress:
                            progress.levelProgress * _xpAnimController.value,
                        totalXp: progress.totalXp,
                        primaryColor: Colors.white,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Stats row with mini cards
  Widget _buildStatsRow(ThemeProvider theme, ChallengesProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: LucideIcons.flame,
            value: '${provider.userProgress.longestStreak}',
            label: 'Best Streak',
            color: const Color(0xFFFF7043),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: LucideIcons.target,
            value: '${provider.userProgress.challengesCompleted}',
            label: 'Completed',
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: LucideIcons.award,
            value: '${provider.unlockedBadges.length}',
            label: 'Badges',
            color: const Color(0xFFFFD700),
          ),
        ),
      ],
    );
  }

  /// Section header with optional trailing widget
  Widget _buildSectionHeader(
    ThemeProvider theme,
    String title, {
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  /// Active challenges - vertical cards
  Widget _buildActiveChallenges(
    ThemeProvider theme,
    ChallengesProvider provider,
  ) {
    if (provider.activeChallenges.isEmpty) {
      return _buildEmptyState(
        theme,
        icon: LucideIcons.target,
        title: 'No Active Challenges',
        subtitle: 'Start a new challenge below!',
      );
    }

    return Column(
      children: provider.activeChallenges.map((challenge) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ActiveChallengeCard(
            challenge: challenge,
            onComplete: () => provider.markChallengeComplete(challenge.id),
            onDelete: () =>
                _confirmDeleteChallenge(context, provider, challenge.id),
          ),
        );
      }).toList(),
    );
  }

  /// Recent badge highlight
  Widget _buildRecentBadge(ThemeProvider theme, ChallengesProvider provider) {
    final recentBadge = provider.unlockedBadges.last;
    final tierColor = BadgeDefinitions.getTierColor(recentBadge.tier);

    return ElevatedCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tierColor.withValues(alpha: 0.2),
                  tierColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tierColor.withValues(alpha: 0.5)),
            ),
            child: Icon(
              IconData(recentBadge.iconCodePoint, fontFamily: 'MaterialIcons'),
              color: tierColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      size: 14,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Recent Achievement',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  recentBadge.name,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '+${recentBadge.xpReward} XP',
                  style: TextStyle(
                    color: tierColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Badges preview - horizontal scroll
  Widget _buildBadgesPreview(ThemeProvider theme, ChallengesProvider provider) {
    final displayBadges = provider.allBadges.take(6).toList();

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayBadges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final badge = displayBadges[index];
          return _BadgePreviewItem(badge: badge);
        },
      ),
    );
  }

  /// Category tabs for filtering
  Widget _buildCategoryTabs(ThemeProvider theme) {
    final categories = [
      ('all', 'All', LucideIcons.grid3x3),
      ('health', 'Health', LucideIcons.heart),
      ('mindfulness', 'Mindfulness', LucideIcons.brain),
      ('productivity', 'Productivity', LucideIcons.target),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (id, label, icon) = categories[index];
          final isSelected = _selectedCategory == id;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? theme.primaryColor : theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.white : theme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : theme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Available challenges list
  Widget _buildAvailableChallenges(
    ThemeProvider theme,
    ChallengesProvider provider,
  ) {
    final filtered = _selectedCategory == 'all'
        ? provider.availableChallenges
        : provider.availableChallenges
              .where((c) => c.category.name == _selectedCategory)
              .toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(
        theme,
        icon: LucideIcons.search,
        title: 'No challenges in this category',
        subtitle: 'Try selecting a different category',
      );
    }

    return Column(
      children: filtered.map((challenge) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AvailableChallengeCard(
            challenge: challenge,
            onJoin: () => provider.joinChallenge(challenge),
          ),
        );
      }).toList(),
    );
  }

  /// Empty state widget
  Widget _buildEmptyState(
    ThemeProvider theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: theme.primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteChallenge(
    BuildContext context,
    ChallengesProvider provider,
    String challengeId,
  ) {
    final theme = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Challenge',
          style: TextStyle(color: theme.textPrimary),
        ),
        content: Text(
          'Are you sure? Your progress will be lost.',
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteChallenge(challengeId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAllBadges(BuildContext context, ChallengesProvider provider) {
    final theme = context.read<ThemeProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.backgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Badges',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${provider.unlockedBadges.length}/${provider.allBadges.length}',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BadgeGrid(badges: provider.allBadges, showAll: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated XP Ring widget
class _AnimatedXpRing extends StatelessWidget {
  final int level;
  final double progress;
  final int totalXp;
  final Color primaryColor;

  const _AnimatedXpRing({
    required this.level,
    required this.progress,
    required this.totalXp,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(
                primaryColor.withValues(alpha: 0.3),
              ),
            ),
          ),
          // Progress ring
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _XpRingPainter(
                progress: progress,
                color: primaryColor,
                strokeWidth: 8,
              ),
            ),
          ),
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'LVL',
                style: TextStyle(
                  color: primaryColor.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$level',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for XP ring with rounded caps
class _XpRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _XpRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _XpRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Stat card widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return ElevatedCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      borderRadius: 16,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: theme.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

/// Active challenge card - vertical design
class _ActiveChallengeCard extends StatelessWidget {
  final dynamic challenge;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const _ActiveChallengeCard({
    required this.challenge,
    this.onComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isCompleteToday = challenge.isTodayCompleted(DateTime.now());
    final progress = challenge.completionPercentage;

    return ElevatedCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Progress ring
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: theme.surfaceColor,
                  valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        challenge.title,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onDelete != null)
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(
                          LucideIcons.x,
                          color: theme.textSecondary,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 12,
                      color: theme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.daysCompleted}/${challenge.durationDays} days',
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      LucideIcons.flame,
                      size: 12,
                      color: const Color(0xFFFF7043),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.currentStreak}',
                      style: const TextStyle(
                        color: Color(0xFFFF7043),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Complete button
          GestureDetector(
            onTap: isCompleteToday ? null : onComplete,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCompleteToday
                    ? const Color(0xFF4CAF50)
                    : theme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleteToday ? LucideIcons.check : LucideIcons.plus,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge preview item
class _BadgePreviewItem extends StatelessWidget {
  final Badge badge;

  const _BadgePreviewItem({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final tierColor = BadgeDefinitions.getTierColor(badge.tier);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: badge.isUnlocked
                ? tierColor.withValues(alpha: 0.15)
                : theme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: badge.isUnlocked
                  ? tierColor.withValues(alpha: 0.5)
                  : theme.textSecondary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: Icon(
            IconData(badge.iconCodePoint, fontFamily: 'MaterialIcons'),
            color: badge.isUnlocked
                ? tierColor
                : theme.textSecondary.withValues(alpha: 0.4),
            size: 28,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 60,
          child: Text(
            badge.name,
            style: TextStyle(
              color: badge.isUnlocked ? theme.textPrimary : theme.textSecondary,
              fontSize: 9,
              fontWeight: badge.isUnlocked
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
