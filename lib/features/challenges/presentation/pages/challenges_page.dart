import 'dart:math' as math;

import 'package:flutter/material.dart' hide Badge;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animated_metric_text.dart';
import '../../../../core/widgets/celebration_dialog.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/weekly_goal.dart';
import '../providers/challenges_provider.dart';
import '../utils/challenge_icon_lookup.dart';
import '../widgets/challenges_widgets.dart' show BadgeGrid;

/// Goals & Challenges hub.
///
/// The Claude Design handoff treats Goals and Challenges as sibling screens.
/// The production app already routes both concepts here, so this page exposes
/// them as two first-class tabs while keeping the existing provider flow.
class ChallengesPage extends StatefulWidget {
  final int initialTab;

  const ChallengesPage({super.key, this.initialTab = 0});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  late int _selectedTab;
  int _goalsFilter = 0;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab < 0
        ? 0
        : widget.initialTab > 1
        ? 1
        : widget.initialTab;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengesProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final provider = context.watch<ChallengesProvider>();
    final isGoals = _selectedTab == 0;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: isGoals ? AppColors.routineDeep : AppColors.moodDeep,
          onRefresh: provider.initialize,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FeatureTopBar(
                  title: isGoals ? 'Goals' : 'Challenges',
                  actionIcon: isGoals ? LucideIcons.plus : LucideIcons.trophy,
                  actionColor: isGoals
                      ? AppColors.routineDeep
                      : AppColors.moodDeep,
                  onBack: () => Navigator.of(context).pop(),
                  onAction: isGoals
                      ? () => _showGoalTemplates(context, provider)
                      : () => _showAllBadges(context, provider),
                ),
                _SegmentedTabs(
                  labels: const ['Goals', 'Challenges'],
                  selectedIndex: _selectedTab,
                  onChanged: (index) => setState(() => _selectedTab = index),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: isGoals
                      ? _GoalsTab(
                          key: const ValueKey('goals_tab'),
                          provider: provider,
                          goalsFilter: _goalsFilter,
                          onFilterChanged: (index) {
                            setState(() => _goalsFilter = index);
                          },
                          onCreateGoal: () =>
                              _showGoalTemplates(context, provider),
                        )
                      : _ChallengesTab(
                          key: const ValueKey('challenges_tab'),
                          provider: provider,
                          onCheckIn: (challenge) =>
                              _checkInChallenge(provider, challenge),
                          onJoin: provider.joinChallenge,
                        ),
                ),
                SizedBox(height: LayoutConstants.getNavbarClearance(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkInChallenge(
    ChallengesProvider provider,
    Challenge challenge,
  ) async {
    final previousDays = challenge.daysCompleted;
    await provider.markChallengeComplete(challenge.id);
    if (!mounted) return;

    Challenge? updatedChallenge;
    for (final active in provider.activeChallenges) {
      if (active.id == challenge.id) {
        updatedChallenge = active;
        break;
      }
    }
    if (updatedChallenge == null ||
        updatedChallenge.daysCompleted <= previousDays) {
      return;
    }

    await showCelebrationDialog(
      context: context,
      icon: LucideIcons.flame,
      color: AppColors.moodDeep,
      eyebrow: 'CHALLENGE CHECK-IN',
      title: 'Today is complete',
      message:
          'You kept your promise for “${updatedChallenge.title}”. Small steps are becoming a streak.',
      actionLabel: 'Keep going',
      metric: CelebrationMetric(
        before: '$previousDays',
        after: '${updatedChallenge.daysCompleted}',
        label: 'days',
      ),
    );
  }

  void _showGoalTemplates(BuildContext context, ChallengesProvider provider) {
    final theme = context.read<ThemeProvider>();
    final templates = _GoalTemplate.defaults();
    final existingIds = provider.weeklyGoals.map((goal) => goal.id).toSet();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.backgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.borderColor.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Create weekly goal',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pick a gentle target for this week.',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                ...templates.map((template) {
                  final goal = template.toWeeklyGoal();
                  final exists = existingIds.contains(goal.id);
                  final tone = _toneForGoalType(template.type);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TemplateGoalTile(
                      title: template.title,
                      subtitle: template.subtitle,
                      icon: template.icon,
                      tone: tone,
                      disabled: exists,
                      onTap: exists
                          ? null
                          : () async {
                              await provider.createWeeklyGoal(goal);
                              if (context.mounted) Navigator.pop(context);
                            },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAllBadges(BuildContext context, ChallengesProvider provider) {
    final theme = context.read<ThemeProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.backgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.borderColor.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Row(
                  children: [
                    Text(
                      'Badges',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${provider.unlockedBadges.length}/${provider.allBadges.length}',
                      style: const TextStyle(
                        color: AppColors.moodDeep,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: BadgeGrid(badges: provider.allBadges, showAll: true),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GoalsTab extends StatelessWidget {
  final ChallengesProvider provider;
  final int goalsFilter;
  final ValueChanged<int> onFilterChanged;
  final VoidCallback onCreateGoal;

  const _GoalsTab({
    super.key,
    required this.provider,
    required this.goalsFilter,
    required this.onFilterChanged,
    required this.onCreateGoal,
  });

  @override
  Widget build(BuildContext context) {
    final goals = _goalCardsFor(provider);
    final visibleGoals = goalsFilter == 0
        ? goals.where((goal) => !goal.isDone).toList()
        : goals.where((goal) => goal.isDone).toList();
    final activeGoals = goals.where((goal) => !goal.isDone).toList();
    final healthyCount = activeGoals
        .where((goal) => goal.progress >= 0.5 || goal.isSuggested)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GoalsHero(totalGoals: activeGoals.length, healthyGoals: healthyCount),
        _SegmentedTabs(
          labels: const ['Active', 'Done'],
          selectedIndex: goalsFilter,
          onChanged: onFilterChanged,
          compact: true,
        ),
        if (visibleGoals.isEmpty)
          _EmptyPanel(
            icon: goalsFilter == 0 ? LucideIcons.target : LucideIcons.check,
            title: goalsFilter == 0 ? 'No active goals' : 'No completed goals',
            subtitle: goalsFilter == 0
                ? 'Create a weekly goal to start tracking progress.'
                : 'Finished goals will appear here.',
            actionLabel: goalsFilter == 0 ? 'Create goal' : null,
            onAction: goalsFilter == 0 ? onCreateGoal : null,
            tone: _routineTone,
          )
        else
          Column(
            children: visibleGoals
                .map(
                  (goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: _GoalProgressCard(goal: goal),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  List<_GoalCardData> _goalCardsFor(ChallengesProvider provider) {
    if (provider.weeklyGoals.isNotEmpty) {
      return provider.weeklyGoals.map(_goalFromWeeklyGoal).toList();
    }

    if (provider.activeChallenges.isNotEmpty) {
      return provider.activeChallenges
          .map((challenge) => _goalFromChallenge(challenge, suggested: false))
          .toList();
    }

    return provider.availableChallenges
        .take(4)
        .map((challenge) => _goalFromChallenge(challenge, suggested: true))
        .toList();
  }

  _GoalCardData _goalFromWeeklyGoal(WeeklyGoal goal) {
    return _GoalCardData(
      title: goal.title,
      subtitle: '${_goalTypeLabel(goal.type)} · this week',
      icon: materialIconFromCodePoint(goal.iconCodePoint),
      value: '${goal.completedDays}',
      target: '7',
      unit: 'days',
      progress: goal.completionPercentage,
      tone: _toneForGoalType(goal.type),
      isDone: goal.isCompleted,
      isSuggested: false,
    );
  }

  _GoalCardData _goalFromChallenge(
    Challenge challenge, {
    required bool suggested,
  }) {
    return _GoalCardData(
      title: challenge.title,
      subtitle:
          '${suggested ? 'Suggested' : 'Challenge'} · ${challenge.durationDays} days',
      icon: materialIconFromCodePoint(challenge.iconCodePoint),
      value: '${challenge.daysCompleted}',
      target: '${challenge.durationDays}',
      unit: 'days',
      progress: challenge.completionPercentage,
      tone: _toneForChallenge(challenge),
      isDone: challenge.isCompleted,
      isSuggested: suggested,
    );
  }

  String _goalTypeLabel(GoalType type) {
    switch (type) {
      case GoalType.waterStreak:
        return 'Daily hydration';
      case GoalType.taskStreak:
        return 'Daily tasks';
      case GoalType.routineStreak:
        return 'Routine';
      case GoalType.moodTrack:
        return 'Mood';
      case GoalType.gratitude:
        return 'Mindful';
      case GoalType.custom:
        return 'Custom';
    }
  }
}

class _ChallengesTab extends StatelessWidget {
  final ChallengesProvider provider;
  final Future<void> Function(Challenge challenge) onCheckIn;
  final Future<void> Function(Challenge challenge) onJoin;

  const _ChallengesTab({
    super.key,
    required this.provider,
    required this.onCheckIn,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final activeChallenge = provider.activeChallenges.isNotEmpty
        ? provider.activeChallenges.first
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChallengeSpotlightCard(
          challenge: activeChallenge,
          onCheckIn: activeChallenge == null
              ? null
              : () => onCheckIn(activeChallenge),
        ),
        const SizedBox(height: 14),
        _ChallengeStatsRow(provider: provider),
        _SectionHeading(
          title: 'Join a challenge',
          trailing: provider.availableChallenges.isNotEmpty ? 'All' : null,
        ),
        if (provider.availableChallenges.isEmpty)
          _EmptyPanel(
            icon: LucideIcons.trophy,
            title: 'All challenges joined',
            subtitle: 'Your active challenges are already in motion.',
            tone: _moodTone,
          )
        else
          Column(
            children: provider.availableChallenges.take(6).map((challenge) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _JoinChallengeCard(
                  challenge: challenge,
                  onJoin: () => onJoin(challenge),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _FeatureTopBar extends StatelessWidget {
  final String title;
  final IconData actionIcon;
  final Color actionColor;
  final VoidCallback onBack;
  final VoidCallback onAction;

  const _FeatureTopBar({
    required this.title,
    required this.actionIcon,
    required this.actionColor,
    required this.onBack,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _RoundIconButton(
            icon: LucideIcons.chevronLeft,
            color: theme.textPrimary,
            onTap: onBack,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _RoundIconButton(
            icon: actionIcon,
            color: actionColor,
            onTap: onAction,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Material(
      color: theme.cardColor,
      shape: const CircleBorder(),
      elevation: theme.isDarkMode ? 0 : 5,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.08),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool compact;

  const _SegmentedTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 14 : 18),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(vertical: compact ? 8 : 10),
                decoration: BoxDecoration(
                  color: selected ? theme.cardColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: selected && !theme.isDarkMode
                      ? [
                          BoxShadow(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.07,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? theme.textPrimary : theme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _GoalsHero extends StatelessWidget {
  final int totalGoals;
  final int healthyGoals;

  const _GoalsHero({required this.totalGoals, required this.healthyGoals});

  @override
  Widget build(BuildContext context) {
    final subtitle = totalGoals == 0
        ? 'Choose your first weekly target'
        : '$healthyGoals of $totalGoals goals progressing well';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.routine, AppColors.routineDeep],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.routine.withValues(alpha: 0.34),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/analytics.png',
            width: 76,
            height: 76,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              LucideIcons.chartNoAxesCombined,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THIS MONTH',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'On track',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12.5,
                    height: 1.25,
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
}

class _GoalProgressCard extends StatelessWidget {
  final _GoalCardData goal;

  const _GoalProgressCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final tint = goal.tone.tintFor(theme);
    final pctLeft = ((1 - goal.progress).clamp(0.0, 1.0) * 100).round();

    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(goal.icon, color: goal.tone.deep, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      goal.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _MiniProgressRing(progress: goal.progress, tone: goal.tone),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 7,
              backgroundColor: tint,
              valueColor: AlwaysStoppedAnimation(goal.tone.color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                goal.value,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                ' / ${goal.target} ${goal.unit}',
                style: TextStyle(
                  color: theme.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                goal.isSuggested ? 'suggested' : '$pctLeft% to go',
                style: TextStyle(
                  color: goal.tone.deep,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeSpotlightCard extends StatelessWidget {
  final Challenge? challenge;
  final VoidCallback? onCheckIn;

  const _ChallengeSpotlightCard({required this.challenge, this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    final currentChallenge = challenge;
    final completedDays = currentChallenge?.daysCompleted ?? 0;
    final duration = currentChallenge?.durationDays ?? 30;
    final progress = currentChallenge?.completionPercentage ?? 0.0;
    final isCompleteToday =
        currentChallenge?.isTodayCompleted(DateTime.now()) ?? false;
    final todayDay = math.max(
      1,
      math.min(duration, completedDays + (isCompleteToday ? 0 : 1)),
    );
    final daysLeft = math.max(0, duration - completedDays);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.mood, AppColors.moodDeep],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.mood.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -54,
            top: -62,
            child: Container(
              width: 164,
              height: 164,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.13),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      currentChallenge == null
                          ? LucideIcons.flame
                          : materialIconFromCodePoint(
                              currentChallenge.iconCodePoint,
                            ),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentChallenge == null
                              ? 'START A CHALLENGE'
                              : 'ACTIVE CHALLENGE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          currentChallenge?.title ?? 'Build your next streak',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Day $todayDay',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ChallengeDayGrid(
                durationDays: duration,
                completedDays: completedDays,
                todayDay: todayDay,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${(progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(
                            text: ' complete · $daysLeft days left',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  _CheckInButton(
                    enabled: currentChallenge != null && !isCompleteToday,
                    done: isCompleteToday,
                    onTap: onCheckIn,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeDayGrid extends StatelessWidget {
  final int durationDays;
  final int completedDays;
  final int todayDay;

  const _ChallengeDayGrid({
    required this.durationDays,
    required this.completedDays,
    required this.todayDay,
  });

  @override
  Widget build(BuildContext context) {
    final visibleDays = math.min(durationDays, 30);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
      ),
      itemCount: visibleDays,
      itemBuilder: (context, index) {
        final day = index + 1;
        final done = day <= completedDays;
        final today = day == todayDay;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: done || today
                ? Colors.white.withValues(alpha: done ? 0.92 : 1.0)
                : Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(7),
            boxShadow: today
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.45),
                      spreadRadius: 2.5,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: today
                ? const Icon(
                    LucideIcons.check,
                    color: AppColors.moodDeep,
                    size: 11,
                  )
                : Text(
                    '$day',
                    style: TextStyle(
                      color: done
                          ? AppColors.moodDeep
                          : Colors.white.withValues(alpha: 0.55),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _CheckInButton extends StatelessWidget {
  final bool enabled;
  final bool done;
  final VoidCallback? onTap;

  const _CheckInButton({
    required this.enabled,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.68),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                done ? 'Done' : 'Check in',
                style: TextStyle(
                  color: AppColors.moodDeep.withValues(
                    alpha: enabled || done ? 1 : 0.55,
                  ),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                done ? LucideIcons.check : LucideIcons.check,
                size: 15,
                color: AppColors.moodDeep.withValues(
                  alpha: enabled || done ? 1 : 0.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeStatsRow extends StatelessWidget {
  final ChallengesProvider provider;

  const _ChallengeStatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ChallengeStatCard(
            icon: LucideIcons.flame,
            value: provider.userProgress.longestStreak,
            label: 'Best streak',
            tone: _moodTone,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ChallengeStatCard(
            icon: LucideIcons.trophy,
            value: provider.userProgress.challengesCompleted,
            label: 'Completed',
            tone: _routineTone,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ChallengeStatCard(
            icon: LucideIcons.star,
            value: provider.unlockedBadges.length,
            label: 'Badges',
            tone: _mindTone,
          ),
        ),
      ],
    );
  }
}

class _ChallengeStatCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final _Tone tone;

  const _ChallengeStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return _SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: tone.tintFor(theme),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tone.deep, size: 16),
          ),
          AnimatedMetricText(
            value: value,
            semanticLabel: '$value $label',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onJoin;

  const _JoinChallengeCard({required this.challenge, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final tone = _toneForChallenge(challenge);

    return _SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tone.tintFor(theme),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              materialIconFromCodePoint(challenge.iconCodePoint),
              color: tone.deep,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${challenge.durationDays} days · ${challenge.description}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(LucideIcons.user, size: 11, color: theme.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${_joinedCount(challenge)} joined',
                      style: TextStyle(
                        color: theme.textTertiary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: tone.color,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onJoin,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                child: Text(
                  'Join',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _joinedCount(Challenge challenge) {
    switch (challenge.linkedFeature) {
      case 'water':
        return '1.2k';
      case 'breathing':
      case 'affirmations':
        return '860';
      case 'todos':
      case 'routines':
        return '2.4k';
      default:
        return '740';
    }
  }
}

class _TemplateGoalTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final _Tone tone;
  final bool disabled;
  final VoidCallback? onTap;

  const _TemplateGoalTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: _SoftCard(
        padding: const EdgeInsets.all(14),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tone.tintFor(theme),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: tone.deep, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      disabled ? 'Already added this week' : subtitle,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                disabled ? LucideIcons.check : LucideIcons.plus,
                color: disabled ? theme.textTertiary : tone.deep,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniProgressRing extends StatelessWidget {
  final double progress;
  final _Tone tone;

  const _MiniProgressRing({required this.progress, required this.tone});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final value = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              backgroundColor: theme.borderColor.withValues(alpha: 0.24),
              valueColor: AlwaysStoppedAnimation(tone.deep),
            ),
          ),
          Text(
            '${(value * 100).round()}',
            style: TextStyle(
              color: tone.deep,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionHeading({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                color: theme.textTertiary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final _Tone tone;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return _SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tone.tintFor(theme),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: tone.deep, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            Material(
              color: tone.color,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.22)),
        boxShadow: theme.isDarkMode
            ? null
            : [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.045),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: AppColors.primaryDeep.withValues(alpha: 0.07),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _GoalCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String target;
  final String unit;
  final double progress;
  final _Tone tone;
  final bool isDone;
  final bool isSuggested;

  const _GoalCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.target,
    required this.unit,
    required this.progress,
    required this.tone,
    required this.isDone,
    required this.isSuggested,
  });
}

class _GoalTemplate {
  final GoalType type;
  final String title;
  final String subtitle;
  final String description;
  final int targetValue;
  final String unit;
  final IconData icon;

  const _GoalTemplate({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.targetValue,
    required this.unit,
    required this.icon,
  });

  static List<_GoalTemplate> defaults() {
    return const [
      _GoalTemplate(
        type: GoalType.waterStreak,
        title: 'Drink 2L water',
        subtitle: 'Daily · this week',
        description: 'Reach your hydration target every day.',
        targetValue: 2000,
        unit: 'ml',
        icon: Icons.water_drop,
      ),
      _GoalTemplate(
        type: GoalType.taskStreak,
        title: 'Complete tasks',
        subtitle: 'Productivity · this week',
        description: 'Finish at least one task each day.',
        targetValue: 1,
        unit: 'task',
        icon: Icons.task_alt,
      ),
      _GoalTemplate(
        type: GoalType.routineStreak,
        title: 'Keep routines',
        subtitle: 'Habit · this week',
        description: 'Complete your routine checklist daily.',
        targetValue: 1,
        unit: 'routine',
        icon: Icons.eco,
      ),
      _GoalTemplate(
        type: GoalType.moodTrack,
        title: 'Track mood',
        subtitle: 'Wellness · this week',
        description: 'Log one mood check-in each day.',
        targetValue: 1,
        unit: 'log',
        icon: Icons.mood,
      ),
    ];
  }

  WeeklyGoal toWeeklyGoal() {
    final weekStart = _weekStart(DateTime.now());
    return WeeklyGoal(
      id: 'weekly_${type.name}_${weekStart.millisecondsSinceEpoch}',
      title: title,
      description: description,
      weekStartTimestamp: weekStart.millisecondsSinceEpoch,
      dailyChecklist: List<bool>.filled(7, false),
      type: type,
      targetValue: targetValue,
      unit: unit,
      iconCodePoint: icon.codePoint,
      xpReward: 50,
    );
  }

  static DateTime _weekStart(DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    return day.subtract(Duration(days: now.weekday - 1));
  }
}

class _Tone {
  final Color color;
  final Color deep;
  final Color tint;

  const _Tone({required this.color, required this.deep, required this.tint});

  Color tintFor(ThemeProvider theme) {
    if (!theme.isDarkMode) return tint;
    return Color.alphaBlend(color.withValues(alpha: 0.16), theme.cardColor);
  }
}

const _Tone _waterTone = _Tone(
  color: AppColors.water,
  deep: AppColors.waterDeep,
  tint: AppColors.waterTint,
);

const _Tone _moodTone = _Tone(
  color: AppColors.mood,
  deep: AppColors.moodDeep,
  tint: AppColors.moodTint,
);

const _Tone _routineTone = _Tone(
  color: AppColors.routine,
  deep: AppColors.routineDeep,
  tint: AppColors.routineTint,
);

const _Tone _mindTone = _Tone(
  color: AppColors.mindful,
  deep: AppColors.mindfulDeep,
  tint: AppColors.mindfulTint,
);

const _Tone _terraTone = _Tone(
  color: AppColors.primary,
  deep: AppColors.primaryDeep,
  tint: AppColors.terraTint,
);

_Tone _toneForGoalType(GoalType type) {
  switch (type) {
    case GoalType.waterStreak:
      return _waterTone;
    case GoalType.taskStreak:
      return _terraTone;
    case GoalType.routineStreak:
    case GoalType.gratitude:
      return _routineTone;
    case GoalType.moodTrack:
      return _moodTone;
    case GoalType.custom:
      return _mindTone;
  }
}

_Tone _toneForChallenge(Challenge challenge) {
  switch (challenge.linkedFeature) {
    case 'water':
      return _waterTone;
    case 'mood':
      return _moodTone;
    case 'routines':
      return _routineTone;
    case 'breathing':
    case 'affirmations':
    case 'gratitude':
      return _mindTone;
  }

  switch (challenge.category) {
    case ChallengeCategory.health:
      return _waterTone;
    case ChallengeCategory.mindfulness:
      return _mindTone;
    case ChallengeCategory.productivity:
      return _terraTone;
    case ChallengeCategory.social:
      return _moodTone;
  }
}
