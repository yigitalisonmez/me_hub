import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/wave_progress_bar.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../domain/entities/routine.dart';
import '../providers/routines_provider.dart';
import '../widgets/streak_badge.dart';
import '../widgets/routine_item_widget.dart';
import '../widgets/add_item_button.dart';
import '../widgets/add_routine_button.dart';

import '../utils/routine_dialogs.dart';
import '../../../../core/constants/routine_icons.dart';

class RoutinesPage extends StatefulWidget {
  const RoutinesPage({super.key});

  @override
  State<RoutinesPage> createState() => _RoutinesPageState();
}

class _RoutinesPageState extends State<RoutinesPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutinesProvider>().loadRoutines();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child:
            Selector<
              RoutinesProvider,
              ({List<Routine> active, List<Routine> inactive})
            >(
              selector: (_, provider) {
                final weekday = DateTime.now().weekday - 1;
                return (
                  active: provider.getActiveRoutinesForDay(weekday),
                  inactive: provider.getInactiveRoutinesForDay(weekday),
                );
              },
              builder: (context, routinesData, child) {
                final provider = context.read<RoutinesProvider>();
                final activeRoutines = routinesData.active;
                final inactiveRoutines = routinesData.inactive;

                // Check for completed routine
                // Check for completed routine
                final completedRoutineName = provider.justCompletedRoutineName;
                if (completedRoutineName != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          opaque: false,
                          barrierDismissible: false,
                          barrierColor: Colors.black54,
                          transitionDuration: const Duration(milliseconds: 800),
                          pageBuilder: (context, animation, secondaryAnimation) {
                            return FadeTransition(
                              opacity: animation,
                              child: Scaffold(
                                backgroundColor: Colors.transparent,
                                body: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Hero(
                                        tag: 'streak_fire',
                                        child: SizedBox(
                                          height: 300,
                                          width: 300,
                                          child: Lottie.asset(
                                            'assets/animations/streak.json',
                                            repeat: false,
                                            fit: BoxFit.contain,
                                            onLoaded: (composition) {
                                              Future.delayed(
                                                composition.duration,
                                                () {
                                                  if (context.mounted) {
                                                    Navigator.of(context).pop();
                                                  }
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Streak Increased!',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.5),
                                                  blurRadius: 10,
                                                ),
                                              ],
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'You completed \'$completedRoutineName\'',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.5),
                                                  blurRadius: 10,
                                                ),
                                              ],
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                  });
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimationLimiter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 375),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 100.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          const SizedBox(height: 16),
                          // Header
                          _buildHeader(context),
                          const SizedBox(height: 24),
                          // Hero Header
                          _buildHeroHeader(context, provider, activeRoutines),
                          const SizedBox(height: 24),
                          // Routine Cards - Filter by active days
                          if (activeRoutines.isEmpty)
                            const EmptyStateWidget(
                              message: 'No routines for today',
                              icon: LucideIcons.coffee,
                              subMessage:
                                  'Enjoy your free time or add a new routine to stay productive!',
                            )
                          else
                            ...activeRoutines.map(
                              (r) => _buildRoutineCard(context, r, provider),
                            ),
                          const SizedBox(height: 24),
                          const SizedBox(height: 24),
                          // Add Routine Button
                          AddRoutineButton(
                            onPressed: () =>
                                RoutineDialogs.showAddRoutine(context),
                          ),

                          if (inactiveRoutines.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.calendarClock,
                                  size: 20,
                                  color: themeProvider.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Upcoming',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: themeProvider.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...inactiveRoutines.map(
                              (r) => _buildRoutineCard(
                                context,
                                r,
                                provider,
                                isInactive: true,
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
              },
            ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const PageHeader(
      title: 'Routines',
      subtitle: 'Build habits & stay consistent',
      actionIcon: LucideIcons.settings,
    );
  }

  Widget _buildHeroHeader(
    BuildContext context,
    RoutinesProvider provider,
    List<Routine> activeRoutines,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final date = DateTime.now();
    final today = DateTime(date.year, date.month, date.day);

    int totalItems = 0;
    int completedToday = 0;
    for (final r in activeRoutines) {
      totalItems += r.items.length;
      completedToday += r.items.where((i) => i.isCheckedToday(today)).length;
    }
    final totalRoutines = activeRoutines.length;
    final completionRate = totalItems == 0 ? 0.0 : completedToday / totalItems;

    // Monochromatic Base Color (using primary color as accent on surface)

    return ElevatedCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.repeat,
                color: themeProvider.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'DAILY OVERVIEW',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: themeProvider.primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Circular Progress with stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Progress
              _buildCircularProgress(
                context,
                completionRate,
                completedToday,
                totalItems,
              ),
              SizedBox(width: 12),
              // Stats Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatItem(
                    context,
                    LucideIcons.list,
                    '$totalRoutines',
                    'Routines',
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem(
                    context,
                    LucideIcons.circleCheck,
                    '$completedToday',
                    'Completed',
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem(
                    context,
                    LucideIcons.clock,
                    '${totalItems - completedToday}',
                    'Remaining',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: themeProvider.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeProvider.borderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              '${today.day}.${today.month}.${today.year}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: themeProvider.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgress(
    BuildContext context,
    double progress,
    int completed,
    int total,
  ) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) {
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 10,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeProvider.primaryColor.withValues(alpha: 0.15),
                  ),
                ),
              ),
              // Progress circle with gradient effect
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: animatedProgress,
                  strokeWidth: 10,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeProvider.primaryColor,
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(animatedProgress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: themeProvider.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: themeProvider.borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: themeProvider.primaryColor, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: themeProvider.textPrimary,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: themeProvider.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoutineCard(
    BuildContext context,
    Routine routine,
    RoutinesProvider provider, {
    bool isInactive = false,
  }) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final date = DateTime.now();
    final today = DateTime(date.year, date.month, date.day);
    final done = routine.items.where((i) => i.isCheckedToday(today)).length;
    final total = routine.items.length;
    final pct = total == 0 ? 0.0 : done / total;

    return Selector<RoutinesProvider, bool>(
      selector: (_, p) => p.isRoutineExpanded(routine.id),
      builder: (context, isExpanded, _) {
        return ElevatedCard(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The rest of the original Column content from the old Container's child
              // Header with icon, name, time and actions
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    if (routine.iconCodePoint != null)
                      Container(
                        width: 52,
                        height: 52,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: isInactive
                              ? themeProvider.surfaceColor
                              : themeProvider.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isInactive
                                ? Colors.transparent
                                : themeProvider.primaryColor.withValues(
                                    alpha: 0.2,
                                  ),
                          ),
                        ),
                        child: Icon(
                          RoutineIcons.getIconFromCodePoint(
                                routine.iconCodePoint!,
                              ) ??
                              LucideIcons.circle,
                          color: isInactive
                              ? themeProvider.textSecondary
                              : themeProvider.primaryColor,
                          size: 24,
                        ),
                      ),
                    // Name and time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            routine.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: isInactive
                                  ? themeProvider.textPrimary.withValues(
                                      alpha: 0.6,
                                    )
                                  : themeProvider.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (routine.time != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.clock,
                                  size: 14,
                                  color: themeProvider.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(routine.time!),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: themeProvider.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Actions
                    Row(
                      children: [
                        StreakBadge(count: routine.streakCount),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: Icon(
                            LucideIcons.ellipsisVertical,
                            color: themeProvider.textSecondary,
                            size: 20,
                          ),
                          onSelected: (v) async {
                            if (v == 'edit') {
                              RoutineDialogs.showEditRoutine(context, routine);
                            } else if (v == 'delete') {
                              RoutineDialogs.showDeleteRoutine(
                                context,
                                routine,
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.pencil,
                                    size: 18,
                                    color: themeProvider.textPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: themeProvider.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.trash2,
                                    size: 18,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: themeProvider.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!isInactive)
                          InkWell(
                            onTap: () =>
                                provider.toggleRoutineExpansion(routine.id),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  LucideIcons.chevronDown,
                                  color: themeProvider.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Days selector
              if (routine.selectedDays != null &&
                  routine.selectedDays!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDaysIndicator(routine.selectedDays!, themeProvider),
              ],
              if (!isInactive) ...[
                const SizedBox(height: 16),
                // Progress bar always visible
                WaveProgressBar(
                  progress: pct,
                  centerText: '${(pct * 100).toStringAsFixed(0)}%',
                  bottomText: '$done / $total today',
                ),
              ],
              // Expandable content with smooth animation
              if (!isInactive)
                _AnimatedExpandableContent(
                  isExpanded: isExpanded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      ...routine.items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isFirst = index == 0;
                        final isLast = index == routine.items.length - 1;

                        // Check if this item is enabled:
                        // First item is always enabled
                        // Subsequent items are enabled only if previous item is checked
                        bool isEnabled = true;
                        if (index > 0) {
                          final previousItem = routine.items[index - 1];
                          isEnabled = previousItem.isCheckedToday(today);
                        }

                        return RoutineItemWidget(
                          routine: routine,
                          item: item,
                          provider: provider,
                          isFirst: isFirst,
                          isLast: isLast,
                          isEnabled: isEnabled,
                        );
                      }),
                      const SizedBox(height: 16),
                      AddItemButton(
                        onPressed: () =>
                            RoutineDialogs.showAddItem(context, routine),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDaysIndicator(
    List<int> selectedDays,
    ThemeProvider themeProvider,
  ) {
    const List<String> dayAbbreviations = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    // Get today's index (0=Monday, 6=Sunday)
    final todayIndex = (DateTime.now().weekday - 1) % 7;
    final isDark = themeProvider.isDarkMode;
    return Row(
      children: List.generate(7, (index) {
        final isSelected = selectedDays.contains(index);
        final isToday = index == todayIndex;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 6 ? 6 : 0),
            height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? themeProvider.primaryColor.withValues(alpha: 0.1)
                  : themeProvider.surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday && isSelected
                    ? themeProvider.primaryColor
                    : (isSelected
                          ? themeProvider.primaryColor.withValues(alpha: 0.2)
                          : Colors.transparent),
                width: isToday ? 2 : 1,
              ),
              // Inset effect for unselected days
              boxShadow: isSelected
                  ? null
                  : [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.1),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                        spreadRadius: 0,
                        blurStyle: BlurStyle.inner,
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                dayAbbreviations[index],
                style: TextStyle(
                  color: isSelected
                      ? themeProvider.primaryColor
                      : themeProvider.textSecondary.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Animated expandable content widget with smooth size and fade transitions
class _AnimatedExpandableContent extends StatefulWidget {
  final bool isExpanded;
  final Widget child;

  const _AnimatedExpandableContent({
    required this.isExpanded,
    required this.child,
  });

  @override
  State<_AnimatedExpandableContent> createState() =>
      _AnimatedExpandableContentState();
}

class _AnimatedExpandableContentState extends State<_AnimatedExpandableContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightFactor = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_AnimatedExpandableContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SizeTransition(
          sizeFactor: _heightFactor,
          axisAlignment: -1.0,
          child: widget.child,
        ),
      ),
    );
  }
}
