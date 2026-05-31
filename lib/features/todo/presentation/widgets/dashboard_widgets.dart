import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../../water/presentation/providers/water_provider.dart';
import '../../../mood_tracker/presentation/providers/mood_provider.dart';
import '../../../routines/presentation/providers/routines_provider.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../providers/todo_provider.dart';

/// Bento daily summary inspired by the Claude Design handoff.
class DailyProgressSection extends StatelessWidget {
  const DailyProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final todoProvider = context.watch<TodoProvider>();
    final waterProvider = context.watch<WaterProvider>();
    final moodProvider = context.watch<MoodProvider>();
    final routinesProvider = context.watch<RoutinesProvider>();

    final waterProgress = waterProvider.dailyGoalMl > 0
        ? (waterProvider.todayAmount / waterProvider.dailyGoalMl)
              .clamp(0.0, 1.0)
              .toDouble()
        : 0.0;
    final hasMood = moodProvider.hasTodayMood;
    final moodScore = moodProvider.todayMood?.score ?? 0;
    final routineStats = _todayRoutineStats(routinesProvider);
    final routineProgress = routineStats.total > 0
        ? routineStats.completed / routineStats.total
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: "Daily summary",
            actionLabel: "See all",
            themeProvider: themeProvider,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = constraints.maxWidth < 360 ? 10.0 : 12.0;
              final smallWidth = (constraints.maxWidth - gap) / 2;

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: smallWidth,
                        height: 216,
                        child: _SummaryAssetCard(
                          imagePath: 'assets/images/tasks_card_1.png',
                          title: 'Tasks',
                          value: '${todoProvider.incompleteCount}',
                          subtitle: 'left today',
                          progress: todoProvider.completionRate,
                          tint: AppColors.terraTint,
                          color: AppColors.primary,
                          isDark: themeProvider.isDarkMode,
                          largeAsset: true,
                        ),
                      ),
                      SizedBox(width: gap),
                      SizedBox(
                        width: smallWidth,
                        child: Column(
                          children: [
                            _SummaryAssetCard(
                              height: 102,
                              imagePath: 'assets/images/water_tracker.png',
                              title: 'Water',
                              value:
                                  '${(waterProvider.todayAmount / 250).floor()}/${(waterProvider.dailyGoalMl / 250).ceil()}',
                              subtitle: 'glasses',
                              progress: waterProgress,
                              tint: AppColors.waterTint,
                              color: AppColors.water,
                              isDark: themeProvider.isDarkMode,
                            ),
                            SizedBox(height: gap),
                            _SummaryAssetCard(
                              height: 102,
                              imagePath: 'assets/images/mood_card_1.png',
                              title: 'Mood',
                              value: hasMood ? '$moodScore/10' : 'Log',
                              subtitle: hasMood ? 'checked in' : 'how are you?',
                              progress: hasMood ? moodScore / 10 : null,
                              tint: AppColors.moodTint,
                              color: AppColors.mood,
                              isDark: themeProvider.isDarkMode,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gap),
                  _SummaryAssetCard(
                    height: 118,
                    imagePath: 'assets/images/routine_tracker.png',
                    title: 'Routines',
                    value:
                        '${routineStats.completed} of ${routineStats.total} done',
                    subtitle: routineStats.total > 0
                        ? 'Keep your rhythm going'
                        : 'No routine scheduled today',
                    progress: routineProgress,
                    tint: AppColors.routineTint,
                    color: AppColors.routine,
                    isDark: themeProvider.isDarkMode,
                    wide: true,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  _RoutineStats _todayRoutineStats(RoutinesProvider routinesProvider) {
    final weekday = DateTime.now().weekday - 1;
    final activeRoutines = routinesProvider.getActiveRoutinesForDay(weekday);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    var totalItems = 0;
    var completedItems = 0;
    for (final routine in activeRoutines) {
      totalItems += routine.items.length;
      completedItems += routine.items
          .where((i) => i.isCheckedToday(todayDate))
          .length;
    }

    return _RoutineStats(completed: completedItems, total: totalItems);
  }
}

class _RoutineStats {
  final int completed;
  final int total;

  const _RoutineStats({required this.completed, required this.total});
}

class _SummaryAssetCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String value;
  final String subtitle;
  final double? progress;
  final Color tint;
  final Color color;
  final bool isDark;
  final bool largeAsset;
  final bool wide;
  final double? height;

  const _SummaryAssetCard({
    required this.imagePath,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.progress,
    required this.tint,
    required this.color,
    required this.isDark,
    this.largeAsset = false,
    this.wide = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTint = isDark
        ? Color.alphaBlend(color.withValues(alpha: 0.14), AppColors.darkCard)
        : tint;

    return ElevatedCard(
      height: height,
      padding: const EdgeInsets.all(14),
      borderRadius: 22,
      backgroundColor: effectiveTint,
      borderColor: color.withValues(alpha: isDark ? 0.16 : 0.14),
      child: Stack(
        children: [
          Positioned(
            right: wide ? -2 : -12,
            top: wide ? -14 : -12,
            bottom: largeAsset ? 0 : null,
            child: Image.asset(
              imagePath,
              width: largeAsset ? 118 : (wide ? 104 : 78),
              fit: BoxFit.contain,
            ),
          ),
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                if (progress != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0.0, 1.0).toDouble(),
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(
                        alpha: isDark ? 0.08 : 0.48,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final ThemeProvider themeProvider;

  const _SectionTitle({
    required this.title,
    this.actionLabel,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: themeProvider.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          Text(
            actionLabel!,
            style: TextStyle(
              color: themeProvider.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

/// Full Explore section matching the Claude Design feature list.
class ExploreSection extends StatelessWidget {
  final VoidCallback? onTasksTap;
  final VoidCallback? onRoutinesTap;
  final VoidCallback? onPomodoroTap;
  final VoidCallback? onGoalsTap;
  final VoidCallback? onCalendarTap;
  final VoidCallback? onWaterTap;
  final VoidCallback? onMoodTap;
  final VoidCallback? onAffirmationsTap;
  final VoidCallback? onBreathingTap;
  final VoidCallback? onGratitudeTap;

  const ExploreSection({
    super.key,
    this.onTasksTap,
    this.onRoutinesTap,
    this.onPomodoroTap,
    this.onGoalsTap,
    this.onCalendarTap,
    this.onWaterTap,
    this.onMoodTap,
    this.onAffirmationsTap,
    this.onBreathingTap,
    this.onGratitudeTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Everything Kora can help you with.',
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          ProductivitySection(
            onTasksTap: onTasksTap,
            onRoutinesTap: onRoutinesTap,
            onPomodoroTap: onPomodoroTap,
            onGoalsTap: onGoalsTap,
            onCalendarTap: onCalendarTap,
          ),
          const SizedBox(height: 20),
          WellnessSection(onWaterTap: onWaterTap, onMoodTap: onMoodTap),
          const SizedBox(height: 20),
          MindfulnessSection(
            onAffirmationsTap: onAffirmationsTap,
            onBreathingTap: onBreathingTap,
            onGratitudeTap: onGratitudeTap,
          ),
        ],
      ),
    );
  }
}

/// Base category section widget with vertical feature cards.
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
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: titleColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: themeProvider.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i != cards.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ],
    );
  }
}

Color _tintForFeature(Color color, bool isDark) {
  if (color == AppColors.water) {
    return isDark
        ? Color.alphaBlend(
            AppColors.water.withValues(alpha: 0.16),
            AppColors.darkCard,
          )
        : AppColors.waterTint;
  }
  if (color == AppColors.mood) {
    return isDark
        ? Color.alphaBlend(
            AppColors.mood.withValues(alpha: 0.16),
            AppColors.darkCard,
          )
        : AppColors.moodTint;
  }
  if (color == AppColors.routine) {
    return isDark
        ? Color.alphaBlend(
            AppColors.routine.withValues(alpha: 0.16),
            AppColors.darkCard,
          )
        : AppColors.routineTint;
  }
  if (color == AppColors.mindful) {
    return isDark
        ? Color.alphaBlend(
            AppColors.mindful.withValues(alpha: 0.16),
            AppColors.darkCard,
          )
        : AppColors.mindfulTint;
  }
  return isDark
      ? Color.alphaBlend(color.withValues(alpha: 0.16), AppColors.darkCard)
      : AppColors.terraTint;
}

String _routineStatus(BuildContext context) {
  final routinesProvider = context.watch<RoutinesProvider>();
  final weekday = DateTime.now().weekday - 1;
  final activeRoutines = routinesProvider.getActiveRoutinesForDay(weekday);
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  var totalItems = 0;
  var completedItems = 0;
  for (final routine in activeRoutines) {
    totalItems += routine.items.length;
    completedItems += routine.items
        .where((i) => i.isCheckedToday(todayDate))
        .length;
  }

  if (totalItems == 0) return 'No routine today';
  return '$completedItems / $totalItems done';
}

String _waterStatus(BuildContext context) {
  final waterProvider = context.watch<WaterProvider>();
  final current = (waterProvider.todayAmount / 250).floor();
  final goal = (waterProvider.dailyGoalMl / 250).ceil();
  return '$current / $goal glasses';
}

String _moodStatus(BuildContext context) {
  final moodProvider = context.watch<MoodProvider>();
  final score = moodProvider.todayMood?.score;
  return score == null ? 'Not logged' : '$score / 10 logged';
}

String _calendarStatus(BuildContext context) {
  final count = context.watch<CalendarProvider>().todayEventCount;
  if (count == 0) return 'No events today';
  return count == 1 ? '1 event' : '$count events';
}

String _taskStatus(BuildContext context) {
  final count = context.watch<TodoProvider>().incompleteCount;
  if (count == 0) return 'All clear';
  return count == 1 ? '1 left today' : '$count left today';
}

String _goalStatus(BuildContext context) {
  final todo = context.watch<TodoProvider>();
  if (todo.completionRate >= 0.75) return 'On track';
  if (todo.totalTodos == 0) return 'Ready to start';
  return 'Keep going';
}

/// Individual explore card.
class _CategoryCard extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isFeatured;
  final String? status;

  const _CategoryCard({
    this.icon,
    this.imagePath,
    required this.label,
    required this.color,
    this.onTap,
    this.isFeatured = false,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final cardTint = _tintForFeature(color, isDark);
    final artTint = Color.alphaBlend(
      color.withValues(alpha: isDark ? 0.12 : 0.13),
      isFeatured ? cardTint : themeProvider.cardColor,
    );

    return Semantics(
      enabled: onTap != null,
      button: onTap != null,
      label: label,
      child: ElevatedCard(
        height: isFeatured ? 94 : 82,
        padding: EdgeInsets.symmetric(
          horizontal: isFeatured ? 16 : 14,
          vertical: isFeatured ? 12 : 11,
        ),
        borderRadius: 22,
        backgroundColor: isFeatured ? cardTint : themeProvider.cardColor,
        borderColor: isFeatured
            ? Colors.transparent
            : (isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : AppColors.textPrimary.withValues(alpha: 0.08)),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: isFeatured ? 68 : 56,
              height: isFeatured ? 68 : 56,
              decoration: BoxDecoration(
                color: artTint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: imagePath != null
                    ? Image.asset(
                        imagePath!,
                        width: isFeatured ? 54 : 46,
                        height: isFeatured ? 54 : 46,
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        icon ?? LucideIcons.sparkles,
                        color: color,
                        size: 28,
                      ),
              ),
            ),
            SizedBox(width: isFeatured ? 16 : 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: themeProvider.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    status ?? 'Open',
                    style: TextStyle(
                      color: color == AppColors.primary
                          ? AppColors.primaryDeep
                          : color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: themeProvider.textTertiary,
              size: 18,
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
          imagePath: 'assets/images/tasks_card_1.png',
          icon: LucideIcons.clipboardList,
          label: 'Tasks',
          color: themeProvider.primaryColor,
          status: _taskStatus(context),
          isFeatured: true,
          onTap: onTasksTap,
        ),
        _CategoryCard(
          imagePath: 'assets/images/routine_tracker.png',
          icon: LucideIcons.repeat,
          label: 'Routines',
          color: AppColors.routine,
          status: _routineStatus(context),
          onTap: onRoutinesTap,
        ),
        _CategoryCard(
          icon: LucideIcons.calendarDays,
          imagePath: 'assets/images/calendar.png',
          label: 'Calendar',
          color: themeProvider.primaryColor,
          status: _calendarStatus(context),
          onTap: onCalendarTap,
        ),
        _CategoryCard(
          imagePath: 'assets/images/pomodoro_timer.png',
          icon: LucideIcons.timer,
          label: 'Timer',
          color: AppColors.mood,
          status: 'Focus 25 min',
          onTap: onPomodoroTap,
        ),
        _CategoryCard(
          imagePath: 'assets/images/analytics.png',
          icon: LucideIcons.trophy,
          label: 'Goals',
          color: AppColors.routine,
          status: _goalStatus(context),
          onTap: onGoalsTap,
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
      titleColor: AppColors.water,
      cards: [
        _CategoryCard(
          imagePath: 'assets/images/water_tracker.png',
          icon: LucideIcons.droplet,
          label: 'Water',
          color: AppColors.water,
          status: _waterStatus(context),
          isFeatured: true,
          onTap: onWaterTap,
        ),
        _CategoryCard(
          imagePath: 'assets/images/mood_tracker.png',
          icon: LucideIcons.smile,
          label: 'Mood',
          color: AppColors.mood,
          status: _moodStatus(context),
          onTap: onMoodTap,
        ),
        _CategoryCard(
          icon: LucideIcons.chartLine,
          imagePath: 'assets/images/analytics.png',
          label: 'Insights',
          color: AppColors.water,
          status: 'Weekly report',
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
      titleColor: AppColors.mindful,
      cards: [
        _CategoryCard(
          imagePath: 'assets/images/affirmation.png',
          icon: LucideIcons.sparkles,
          label: 'Affirmations',
          color: AppColors.mindful,
          status: "Today's card",
          isFeatured: true,
          onTap: onAffirmationsTap,
        ),
        _CategoryCard(
          icon: LucideIcons.wind,
          imagePath: 'assets/images/breathing.png',
          label: 'Breathing',
          color: AppColors.mindful,
          status: '4 sessions',
          onTap: onBreathingTap,
        ),
        _CategoryCard(
          imagePath: 'assets/images/gratitude_2.png',
          icon: LucideIcons.heart,
          label: 'Gratitude',
          color: AppColors.mindful,
          status: 'Write 1 thing',
          onTap: onGratitudeTap,
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
