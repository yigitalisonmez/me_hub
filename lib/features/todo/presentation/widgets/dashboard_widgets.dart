import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../water/presentation/providers/water_provider.dart';
import '../../../mood_tracker/presentation/providers/mood_provider.dart';
import '../../../routines/presentation/providers/routines_provider.dart';

/// Daily progress section showing water, mood, and routines progress
class DailyProgressSection extends StatelessWidget {
  const DailyProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Today\'s Progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _WaterProgressCard(),
              const SizedBox(width: 12),
              _MoodProgressCard(),
              const SizedBox(width: 12),
              _RoutinesProgressCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _WaterProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final waterProvider = context.watch<WaterProvider>();

    final progress = waterProvider.dailyGoalMl > 0
        ? (waterProvider.todayAmount / waterProvider.dailyGoalMl).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    return _ProgressCard(
      icon: LucideIcons.droplet,
      title: 'Water',
      value: '${waterProvider.todayAmount}ml',
      subtitle: 'of ${waterProvider.dailyGoalMl}ml',
      progress: progress,
      color: const Color(0xFF4FC3F7),
      themeProvider: themeProvider,
    );
  }
}

class _MoodProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final moodProvider = context.watch<MoodProvider>();

    final hasMood = moodProvider.hasTodayMood;
    final moodScore = moodProvider.todayMood?.score ?? 0;
    final progress = hasMood ? moodScore / 10.0 : 0.0;

    return _ProgressCard(
      icon: LucideIcons.smile,
      title: 'Mood',
      value: hasMood ? '$moodScore/10' : '—',
      subtitle: hasMood ? 'Logged today' : 'Not logged',
      progress: progress,
      color: const Color(0xFFFFB74D),
      themeProvider: themeProvider,
    );
  }
}

class _RoutinesProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final routinesProvider = context.watch<RoutinesProvider>();

    final weekday = DateTime.now().weekday - 1;
    final activeRoutines = routinesProvider.getActiveRoutinesForDay(weekday);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    int totalItems = 0;
    int completedItems = 0;
    for (final routine in activeRoutines) {
      totalItems += routine.items.length;
      completedItems += routine.items
          .where((i) => i.isCheckedToday(todayDate))
          .length;
    }

    final progress = totalItems > 0 ? completedItems / totalItems : 0.0;

    return _ProgressCard(
      icon: LucideIcons.circleCheck,
      title: 'Routines',
      value: '$completedItems/$totalItems',
      subtitle: 'tasks done',
      progress: progress,
      color: const Color(0xFF81C784),
      themeProvider: themeProvider,
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final double progress;
  final Color color;
  final ThemeProvider themeProvider;

  const _ProgressCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.progress,
    required this.color,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(color: themeProvider.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: themeProvider.surfaceColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick actions horizontal scroll section
class QuickActionsSection extends StatelessWidget {
  final VoidCallback? onAddWater;
  final VoidCallback? onAddTask;
  final VoidCallback? onLogMood;
  final VoidCallback? onStartRoutine;

  const QuickActionsSection({
    super.key,
    this.onAddWater,
    this.onAddTask,
    this.onLogMood,
    this.onStartRoutine,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _QuickActionCard(
                icon: LucideIcons.droplet,
                label: 'Add Water',
                color: const Color(0xFF4FC3F7),
                onTap: onAddWater,
                themeProvider: themeProvider,
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: LucideIcons.plus,
                label: 'New Task',
                color: themeProvider.primaryColor,
                onTap: onAddTask,
                themeProvider: themeProvider,
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: LucideIcons.smile,
                label: 'Log Mood',
                color: const Color(0xFFFFB74D),
                onTap: onLogMood,
                themeProvider: themeProvider,
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: LucideIcons.play,
                label: 'Routines',
                color: const Color(0xFF81C784),
                onTap: onStartRoutine,
                themeProvider: themeProvider,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final ThemeProvider themeProvider;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.themeProvider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Today's tasks preview card
class TodayTasksPreview extends StatelessWidget {
  final int maxItems;

  const TodayTasksPreview({super.key, this.maxItems = 3});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Tasks',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: themeProvider.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Could navigate to full task list
                },
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: themeProvider.primaryColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Tasks will be displayed here by the todo card widget
        ],
      ),
    );
  }
}

/// AI Insights / Recommendations card
class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeProvider.primaryColor.withValues(alpha: 0.1),
              themeProvider.primaryColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: themeProvider.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                LucideIcons.sparkles,
                color: themeProvider.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Insight',
                    style: TextStyle(
                      color: themeProvider.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You\'re doing great! Keep up the momentum with your daily routines.',
                    style: TextStyle(
                      color: themeProvider.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: themeProvider.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
