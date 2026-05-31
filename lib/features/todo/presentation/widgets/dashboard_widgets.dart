import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../../water/presentation/providers/water_provider.dart';
import '../../../mood_tracker/presentation/providers/mood_provider.dart';
import '../../../routines/presentation/providers/routines_provider.dart';
import '../providers/todo_provider.dart';

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
                "Today's Progress",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: themeProvider.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Divider(
                height: 20,
                thickness: 0.5,
                color: themeProvider.isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 136,
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(color: themeProvider.textSecondary, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
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
              Divider(
                height: 20,
                thickness: 0.5,
                color: themeProvider.isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
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

    return Semantics(
      enabled: !isComingSoon,
      button: !isComingSoon,
      label: isComingSoon ? '$label, coming soon' : label,
      child: ElevatedCard(
        width: 110,
        height: 110,
        padding: const EdgeInsets.all(8),
        borderRadius: 16,
        onTap: isComingSoon ? null : onTap,
        child: Stack(
          children: [
            Opacity(
              opacity: isComingSoon ? 0.48 : 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: imagePath != null
                        ? Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                imagePath!,
                                fit: BoxFit.contain,
                              ),
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
                      color: isComingSoon
                          ? themeProvider.textSecondary
                          : themeProvider.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isComingSoon)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? Colors.black.withValues(alpha: 0.16)
                          : Colors.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (isComingSoon)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: themeProvider.textSecondary,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.lock, color: Colors.white, size: 8),
                      SizedBox(width: 3),
                      Text(
                        'Soon',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
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

/// Productivity section: Tasks, Routines, Pomodoro, Goals, Habits
class ProductivitySection extends StatelessWidget {
  final VoidCallback? onTasksTap;
  final VoidCallback? onRoutinesTap;
  final VoidCallback? onPomodoroTap;
  final VoidCallback? onGoalsTap;
  final VoidCallback? onCalendarTap;

  const ProductivitySection({
    super.key,
    this.onTasksTap,
    this.onRoutinesTap,
    this.onPomodoroTap,
    this.onGoalsTap,
    this.onCalendarTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return _CategorySection(
      title: 'Productivity',
      titleColor: themeProvider.primaryColor,
      cards: [
        _CategoryCard(
          imagePath: 'assets/images/checklist_2.png',
          label: 'Tasks',
          color: themeProvider.primaryColor,
          onTap: onTasksTap,
        ),
        _CategoryCard(
          imagePath: 'assets/images/calendar.png',
          label: 'Routines',
          color: const Color(0xFF81C784),
          onTap: onRoutinesTap,
        ),
        _CategoryCard(
          icon: LucideIcons.calendarDays,
          label: 'Calendar',
          color: const Color(0xFF7E57C2),
          onTap: onCalendarTap,
        ),
        _CategoryCard(
          imagePath: 'assets/images/pomodoro_timer.png',
          icon: LucideIcons.timer,
          label: 'Timer',
          color: const Color(0xFFE57373),
          onTap: onPomodoroTap,
        ),
        _CategoryCard(
          icon: LucideIcons.trophy,
          label: 'Goals',
          color: const Color(0xFFFF6B6B),
          onTap: onGoalsTap,
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

/// Mindfulness section: Affirmations, Breathing, Gratitude, Meditate
class MindfulnessSection extends StatelessWidget {
  final VoidCallback? onAffirmationsTap;
  final VoidCallback? onBreathingTap;
  final VoidCallback? onGratitudeTap;

  const MindfulnessSection({
    super.key,
    this.onAffirmationsTap,
    this.onBreathingTap,
    this.onGratitudeTap,
  });

  @override
  Widget build(BuildContext context) {
    return _CategorySection(
      title: 'Mindfulness',
      titleColor: const Color(0xFF26A69A),
      cards: [
        _CategoryCard(
          imagePath: 'assets/images/affirmation.png',
          label: 'Affirmations',
          color: const Color(0xFFE08E6D),
          onTap: onAffirmationsTap,
        ),
        _CategoryCard(
          icon: LucideIcons.wind,
          imagePath: 'assets/images/breathing.png',
          label: 'Breathing',
          color: const Color(0xFF4DB6AC),
          onTap: onBreathingTap,
        ),
        _CategoryCard(
          imagePath: 'assets/images/gratitude_2.png',
          label: 'Gratitude',
          color: const Color(0xFFFFB74D),
          onTap: onGratitudeTap,
        ),
        _CategoryCard(
          icon: LucideIcons.brain,
          label: 'Meditate',
          color: const Color(0xFF7E57C2),
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

/// Daily Tip card — shows a contextual tip based on real provider data
class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key});

  /// Picks the most relevant tip based on today's tracked data.
  _TipData _pickTip({
    required WaterProvider water,
    required MoodProvider mood,
    required RoutinesProvider routines,
    required TodoProvider todo,
  }) {
    final waterPercent = water.dailyGoalMl > 0
        ? water.todayAmount / water.dailyGoalMl
        : 0.0;

    final weekday = DateTime.now().weekday - 1;
    final activeRoutines = routines.getActiveRoutinesForDay(weekday);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    int totalRoutineItems = 0;
    int completedRoutineItems = 0;
    for (final r in activeRoutines) {
      totalRoutineItems += r.items.length;
      completedRoutineItems += r.items
          .where((i) => i.isCheckedToday(todayDate))
          .length;
    }
    final routinePercent = totalRoutineItems > 0
        ? completedRoutineItems / totalRoutineItems
        : 1.0;

    final pendingTodos = todo.todos.where((t) => !t.isCompleted).length;

    // Priority: water < 50% > mood missing > routine < 50% > tasks > all good
    if (waterPercent < 0.5) {
      final remaining = water.dailyGoalMl - water.todayAmount;
      return _TipData(
        icon: LucideIcons.droplet,
        color: const Color(0xFF4FC3F7),
        title: 'Hydration Reminder',
        message:
            'You\'ve had ${water.todayAmount}ml today. Try to drink ${remaining > 0 ? remaining : 0}ml more to hit your daily goal!',
      );
    }

    if (!mood.hasTodayMood) {
      return _TipData(
        icon: LucideIcons.smile,
        color: const Color(0xFFFFB74D),
        title: 'Check In With Yourself',
        message:
            'You haven\'t logged your mood yet today. A quick check-in keeps you self-aware and consistent.',
      );
    }

    if (routinePercent < 0.5 && totalRoutineItems > 0) {
      final left = totalRoutineItems - completedRoutineItems;
      return _TipData(
        icon: LucideIcons.circleCheck,
        color: const Color(0xFF81C784),
        title: 'Keep Your Streak Going',
        message:
            '$left routine ${left == 1 ? 'task' : 'tasks'} left for today. Small steps compound into big results.',
      );
    }

    if (pendingTodos > 0) {
      return _TipData(
        icon: LucideIcons.clipboardList,
        color: const Color(0xFF7986CB),
        title: 'Tasks Awaiting You',
        message:
            'You have $pendingTodos pending ${pendingTodos == 1 ? 'task' : 'tasks'}. Tackle the hardest one first for maximum momentum.',
      );
    }

    // Everything looks good
    return _TipData(
      icon: LucideIcons.sparkles,
      color: const Color(0xFF66BB6A),
      title: 'You\'re On Track!',
      message:
          'Water ✓  Mood ✓  Routines ✓  Great job staying consistent today. Keep it up!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final water = context.watch<WaterProvider>();
    final mood = context.watch<MoodProvider>();
    final routinesProvider = context.watch<RoutinesProvider>();
    final todoProvider = context.watch<TodoProvider>();

    final tip = _pickTip(
      water: water,
      mood: mood,
      routines: routinesProvider,
      todo: todoProvider,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tip.color.withValues(alpha: 0.12),
              tip.color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tip.color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tip.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(tip.icon, color: tip.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.title,
                    style: TextStyle(
                      color: tip.color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip.message,
                    style: TextStyle(
                      color: themeProvider.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipData {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _TipData({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}

/// Goals & Challenges section: Access to gamification features
class GamificationSection extends StatelessWidget {
  final VoidCallback? onChallengesTap;

  const GamificationSection({super.key, this.onChallengesTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onChallengesTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                const Color(0xFFFFE66D).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.trophy,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goals & Challenges',
                      style: TextStyle(
                        color: themeProvider.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '30-day challenges, badges & XP',
                      style: TextStyle(
                        color: themeProvider.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.flame, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Start',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
