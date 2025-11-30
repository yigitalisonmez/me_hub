import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/wave_progress_bar.dart';
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

class _RoutinesPageState extends State<RoutinesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutinesProvider>().loadRoutines();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      decoration: BoxDecoration(color: themeProvider.backgroundColor),
      child: SafeArea(
        child: Selector<RoutinesProvider, List<Routine>>(
          selector: (_, provider) => provider.getActiveRoutinesForDay(
            DateTime.now().weekday - 1,
          ),
          builder: (context, activeRoutines, child) {
            final provider = context.read<RoutinesProvider>();
            
            // Check for completed routine
            final completedRoutineName = provider.justCompletedRoutineName;
            if (completedRoutineName != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          LucideIcons.partyPopper,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'You have completed \'$completedRoutineName\'',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
                }
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Header
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  // Hero Header
                  _buildHeroHeader(context, provider, activeRoutines),
                  const SizedBox(height: 24),
                  // Routine Cards - Filter by active days
                  ...activeRoutines.map((r) => _buildRoutineCard(context, r, provider)),
                  const SizedBox(height: 24),
                  // Add Routine Button
                  AddRoutineButton(
                    onPressed: () => RoutineDialogs.showAddRoutine(context),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Routines',
              style: theme.textTheme.displaySmall?.copyWith(
                color: themeProvider.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Build habits & stay consistent',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: themeProvider.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: themeProvider.borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            LucideIcons.settings,
            color: themeProvider.primaryColor,
            size: 20,
          ),
        ),
      ],
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'ROUTINES',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: themeProvider.primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.repeat,
                color: themeProvider.primaryColor,
                size: 24,
              ),
            ],
          ),
          Container(
            height: 2,
            width: 100,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 16),
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
                  const SizedBox(height: 12),
                  _buildStatItem(
                    context,
                    LucideIcons.circleCheck,
                    '$completedToday',
                    'Completed',
                  ),
                  const SizedBox(height: 12),
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
          Text(
            '${today.day}.${today.month}.${today.year}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: themeProvider.textSecondary),
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
    RoutinesProvider provider,
  ) {
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeProvider.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon, name, time and actions
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                if (routine.iconCodePoint != null)
                  Container(
                    width: 56,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      RoutineIcons.getIconFromCodePoint(
                            routine.iconCodePoint!,
                          ) ??
                          LucideIcons.circle,
                      color: Colors.white,
                      size: 28,
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
                          color: themeProvider.textPrimary,
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
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: Icon(
                        LucideIcons.ellipsisVertical,
                        color: themeProvider.primaryColor.withValues(
                          alpha: 0.7,
                        ),
                        size: 24,
                      ),
                      onSelected: (v) async {
                        if (v == 'edit') {
                          RoutineDialogs.showEditRoutine(context, routine);
                        } else if (v == 'delete') {
                          RoutineDialogs.showDeleteRoutine(context, routine);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.pencil,
                                size: 20,
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
                                size: 20,
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
                    InkWell(
                      onTap: () => provider.toggleRoutineExpansion(routine.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            LucideIcons.chevronDown,
                            color: themeProvider.primaryColor.withValues(
                              alpha: 0.7,
                            ),
                            size: 24,
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
            const SizedBox(height: 12),
            _buildDaysIndicator(routine.selectedDays!, themeProvider),
          ],
          const SizedBox(height: 12),
          // Progress bar always visible
          WaveProgressBar(
            progress: pct,
            centerText: '${(pct * 100).toStringAsFixed(0)}%',
            bottomText: '$done / $total today',
          ),
          // Expandable content with smooth animation
          _AnimatedExpandableContent(
            isExpanded: isExpanded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
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

    return Row(
      children: List.generate(7, (index) {
        final isSelected = selectedDays.contains(index);
        final isToday = index == todayIndex;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 6 ? 4 : 0),
            height: 32,
            decoration: BoxDecoration(
              color: isSelected
                  ? themeProvider.surfaceColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday && isSelected
                  ? Border.all(color: themeProvider.primaryColor, width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                dayAbbreviations[index],
                style: TextStyle(
                  color: isSelected
                      ? themeProvider.primaryColor
                      : themeProvider.textSecondary,
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

class _AnimatedExpandableContentState
    extends State<_AnimatedExpandableContent>
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
