import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/elevated_card.dart';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: themeProvider.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 3,
                width: 40,
                decoration: BoxDecoration(
                  color: themeProvider.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _WaterProgressCard(),
              const SizedBox(width: 8),
              _MoodProgressCard(),
              const SizedBox(width: 8),
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
    return ElevatedCard(
      width: 140,
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
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

/// Base category section widget with horizontal scrollable cards
class _CategorySection extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<_CategoryCard> cards;

  const _CategorySection({
    required this.title,
    required this.titleColor,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: themeProvider.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 3,
                width: 40,
                decoration: BoxDecoration(
                  color: themeProvider.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) => cards[index],
          ),
        ),
      ],
    );
  }
}

/// Individual category card
class _CategoryCard extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isComingSoon;

  const _CategoryCard({
    this.icon,
    this.imagePath,
    required this.label,
    required this.color,
    this.onTap,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return ElevatedCard(
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(8),
      borderRadius: 16,
      onTap: isComingSoon ? null : onTap,
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: imagePath != null
                    ? Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(imagePath!, fit: BoxFit.contain),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(icon, color: color, size: 28),
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: themeProvider.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          if (isComingSoon)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Soon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Productivity section: Tasks, Routines, Pomodoro, Habits
class ProductivitySection extends StatelessWidget {
  final VoidCallback? onTasksTap;
  final VoidCallback? onRoutinesTap;
  final VoidCallback? onPomodoroTap;

  const ProductivitySection({
    super.key,
    this.onTasksTap,
    this.onRoutinesTap,
    this.onPomodoroTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return _CategorySection(
      title: 'Productivity',
      titleColor: themeProvider.primaryColor,
      cards: [
        _CategoryCard(
          imagePath: 'assets/images/tasks_card_1.png',
          label: 'Tasks',
          color: themeProvider.primaryColor,
          onTap: onTasksTap,
        ),
        _CategoryCard(
          imagePath: 'assets/images/routine_circle.png',
          label: 'Routines',
          color: const Color(0xFF81C784),
          onTap: onRoutinesTap,
        ),
        _CategoryCard(
          imagePath: 'assets/images/pomodoro_timer.png',
          icon: LucideIcons.timer,
          label: 'Timer',
          color: const Color(0xFFE57373),
          onTap: onPomodoroTap,
        ),
        _CategoryCard(
          icon: LucideIcons.flame,
          label: 'Habits',
          color: const Color(0xFFFF8A65),
          isComingSoon: true,
        ),
      ],
    );
  }
}

/// Wellness section: Water, Mood, Weekly Insights
class WellnessSection extends StatelessWidget {
  final VoidCallback? onWaterTap;
  final VoidCallback? onMoodTap;

  const WellnessSection({super.key, this.onWaterTap, this.onMoodTap});

  @override
  Widget build(BuildContext context) {
    return _CategorySection(
      title: 'Wellness',
      titleColor: const Color(0xFFE91E63),
      cards: [
        _CategoryCard(
          imagePath: 'assets/images/water_glass_check.png',
          label: 'Water',
          color: const Color(0xFF4FC3F7),
          onTap: onWaterTap,
        ),
        _CategoryCard(
          imagePath: 'assets/images/mood_circle.png',
          label: 'Mood',
          color: const Color(0xFFFFB74D),
          onTap: onMoodTap,
        ),
        _CategoryCard(
          icon: LucideIcons.chartLine,
          imagePath: 'assets/images/analytics.png',
          label: 'Insights',
          color: const Color(0xFF9575CD),
          isComingSoon: true,
        ),
      ],
    );
  }
}

/// Mindfulness section: Affirmations, Breathing, Meditate, Journal
class MindfulnessSection extends StatelessWidget {
  final VoidCallback? onAffirmationsTap;

  const MindfulnessSection({super.key, this.onAffirmationsTap});

  @override
  Widget build(BuildContext context) {
    return _CategorySection(
      title: 'Mindfulness',
      titleColor: const Color(0xFF26A69A),
      cards: [
        _CategoryCard(
          icon: LucideIcons.sparkles,
          label: 'Affirmations',
          color: const Color(0xFFE08E6D),
          onTap: onAffirmationsTap,
        ),
        _CategoryCard(
          icon: LucideIcons.wind,
          label: 'Breathing',
          color: const Color(0xFF4DB6AC),
          isComingSoon: true,
        ),
        _CategoryCard(
          icon: LucideIcons.brain,
          label: 'Meditate',
          color: const Color(0xFF7E57C2),
          isComingSoon: true,
        ),
        _CategoryCard(
          icon: LucideIcons.bookOpen,
          label: 'Journal',
          color: const Color(0xFF5C6BC0),
          isComingSoon: true,
        ),
      ],
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
