import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../providers/challenges_provider.dart';
import '../widgets/challenges_widgets.dart';

/// Goals & Challenges page with XP, challenges, and badges
class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengesProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final provider = context.watch<ChallengesProvider>();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Header - using PageHeader for consistency
                    PageHeader(
                      title: 'Goals & Challenges',
                      subtitle: 'Reach your goals, earn badges!',
                      showBackButton: true,
                      actionIcon: LucideIcons.trophy,
                    ),
                    const SizedBox(height: 32),

                    // Stats Row
                    _buildStatsRow(theme, provider),
                    const SizedBox(height: 24),

                    // XP Level Bar
                    const XpLevelBar(),
                    const SizedBox(height: 24),

                    // Active Challenges
                    _buildSectionTitle(theme, 'Active Challenges'),
                    const SizedBox(height: 12),
                    if (provider.activeChallenges.isEmpty)
                      _buildEmptyChallengesState(theme)
                    else
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: provider.activeChallenges.length,
                          itemBuilder: (context, index) {
                            final challenge = provider.activeChallenges[index];
                            return ActiveChallengeCard(
                              challenge: challenge,
                              onComplete: () =>
                                  provider.markChallengeComplete(challenge.id),
                              onDelete: () => _confirmDeleteChallenge(
                                context,
                                provider,
                                challenge.id,
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Badges Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle(theme, 'Badges'),
                        GestureDetector(
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    BadgeGrid(badges: provider.allBadges),
                    const SizedBox(height: 24),

                    // Available Challenges
                    if (provider.availableChallenges.isNotEmpty) ...[
                      _buildSectionTitle(theme, 'Start New Challenge'),
                      const SizedBox(height: 12),
                      ...provider.availableChallenges.map(
                        (challenge) => AvailableChallengeCard(
                          challenge: challenge,
                          onJoin: () => provider.joinChallenge(challenge),
                        ),
                      ),
                    ],

                    SizedBox(
                      height: LayoutConstants.getNavbarClearance(context),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeProvider theme, ChallengesProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: LucideIcons.flame,
            value: '${provider.userProgress.longestStreak}',
            label: 'best streak',
            color: const Color(0xFFFF7043),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            icon: LucideIcons.target,
            value: '${provider.userProgress.challengesCompleted}',
            label: 'completed',
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            icon: LucideIcons.award,
            value: '${provider.unlockedBadges.length}',
            label: 'badges',
            color: const Color(0xFFFFD700),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChallengesState(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.target,
            size: 48,
            color: theme.primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No active challenges',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start a new challenge below to track your goals!',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeProvider theme, String title) {
    return Text(
      title,
      style: TextStyle(
        color: theme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
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
          'Are you sure you want to delete this challenge? Your progress will be lost.',
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

/// Mini stat card matching app style
class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return ElevatedCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      borderRadius: 16,
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(color: theme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
