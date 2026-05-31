import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/swipe_to_dismiss_wrapper.dart';
import '../../domain/entities/daily_todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/add_todo_dialog.dart';

/// Tasks page - today's goals and task management.
class TodoPage extends StatefulWidget {
  final bool showFullPage;

  const TodoPage({super.key, this.showFullPage = true});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  bool _dataLoaded = false;
  int _selectedSegment = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoaded) {
      _dataLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TodoProvider>().loadTodayTodos();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final content = Consumer<TodoProvider>(
      builder: (context, provider, child) {
        if (provider.justCompletedAllTodos) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showCelebrationDialog(context);
            provider.resetJustCompletedAllTodos();
          });
        }

        final visibleTodos = _visibleTodos(provider.todos);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            LayoutConstants.getNavbarClearance(context),
          ),
          child: AnimationLimiter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 36,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  _FeatureTopBar(
                    title: 'Tasks',
                    color: AppColors.primary,
                    onMoreTap: () => _showAddTodoDialog(context),
                  ),
                  const SizedBox(height: 16),
                  _TasksHero(provider: provider),
                  const SizedBox(height: 18),
                  _TaskSegmentedControl(
                    selectedIndex: _selectedSegment,
                    onChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSegment = index);
                    },
                  ),
                  const SizedBox(height: 14),
                  if (provider.isLoading)
                    _LoadingBlock(themeProvider: themeProvider)
                  else if (provider.error != null)
                    _ErrorBlock(
                      message: provider.error!,
                      onRetry: provider.loadTodayTodos,
                    )
                  else if (visibleTodos.isEmpty)
                    _EmptyTasksBlock(
                      onAddTap: () => _showAddTodoDialog(context),
                    )
                  else
                    _TaskSections(
                      todos: visibleTodos,
                      provider: provider,
                      onDelete: _deleteTodo,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!widget.showFullPage) {
      return SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context),
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: SafeArea(child: content),
    );
  }

  List<DailyTodo> _visibleTodos(List<DailyTodo> todos) {
    final filtered = switch (_selectedSegment) {
      1 => todos.where((todo) => !todo.isCompleted).toList(),
      2 => todos.where((todo) => todo.isCompleted).toList(),
      _ => List<DailyTodo>.from(todos),
    };

    filtered.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.createdAt.compareTo(b.createdAt);
    });
    return filtered;
  }

  void _showAddTodoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTodoDialog(
        onAdd: ({required String title, DateTime? date, int priority = 2}) {
          context.read<TodoProvider>().addTodo(
            title: title,
            date: date,
            priority: priority,
          );
        },
      ),
    );
  }

  void _deleteTodo(
    BuildContext context,
    TodoProvider provider,
    DailyTodo deletedTodo,
  ) {
    provider.deleteTodo(deletedTodo.id);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              LucideIcons.trash2,
              color: context.read<ThemeProvider>().textPrimary,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '"${deletedTodo.title}" deleted',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: context.read<ThemeProvider>().surfaceColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primary,
          onPressed: () {
            provider.addTodo(
              title: deletedTodo.title,
              date: deletedTodo.date,
              priority: deletedTodo.priority,
            );
          },
        ),
      ),
    );
  }

  void _showCelebrationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (context.mounted) Navigator.of(context).pop();
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Lottie.asset(
            'assets/animations/done.json',
            width: 300,
            height: 300,
            fit: BoxFit.contain,
            repeat: false,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                LucideIcons.circleCheck,
                color: AppColors.success,
                size: 100,
              );
            },
          ),
        );
      },
    );
  }
}

class _FeatureTopBar extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback? onMoreTap;

  const _FeatureTopBar({
    required this.title,
    required this.color,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      children: [
        _CircleIconButton(
          icon: LucideIcons.chevronLeft,
          onTap: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          },
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _CircleIconButton(
          icon: LucideIcons.plus,
          color: color,
          onTap: onMoreTap,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const _CircleIconButton({required this.icon, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Material(
      color: themeProvider.cardColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: themeProvider.isDarkMode
                  ? Colors.white.withValues(alpha: 0.07)
                  : AppColors.textPrimary.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: themeProvider.isDarkMode ? 0.18 : 0.04,
                ),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: color ?? themeProvider.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TasksHero extends StatelessWidget {
  final TodoProvider provider;

  const _TasksHero({required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.totalTodos;
    final completed = provider.completedCount;
    final progress = provider.completionRate;

    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 16),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -42,
            top: -54,
            child: Container(
              width: 172,
              height: 172,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Image.asset(
                'assets/images/tasks_card_1.png',
                width: 78,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TODAY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == 0
                          ? 'Ready to plan'
                          : '$completed of $total done',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 6,
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ProgressRing(
                progress: total == 0 ? 0 : progress,
                color: Colors.white,
                trackColor: Colors.white.withValues(alpha: 0.34),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskSegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _TaskSegmentedControl({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    const labels = ['Today', 'Open', 'Done'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? AppColors.darkSurface
            : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected
                      ? themeProvider.cardColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: themeProvider.isDarkMode ? 0.22 : 0.06,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? themeProvider.textPrimary
                        : themeProvider.textSecondary,
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

class _TaskSections extends StatelessWidget {
  final List<DailyTodo> todos;
  final TodoProvider provider;
  final void Function(BuildContext, TodoProvider, DailyTodo) onDelete;

  const _TaskSections({
    required this.todos,
    required this.provider,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <_TaskPriority, List<DailyTodo>>{
      _TaskPriority.high: todos.where((todo) => todo.priority == 3).toList(),
      _TaskPriority.medium: todos.where((todo) => todo.priority == 2).toList(),
      _TaskPriority.low: todos.where((todo) => todo.priority == 1).toList(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries)
          if (entry.value.isNotEmpty) ...[
            _TaskGroupLabel(priority: entry.key, count: entry.value.length),
            const SizedBox(height: 8),
            ...entry.value.map(
              (todo) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TaskRow(
                  todo: todo,
                  priority: entry.key,
                  onToggle: () {
                    HapticFeedback.selectionClick();
                    provider.toggleTodoCompletion(todo.id);
                  },
                  onDelete: () => onDelete(context, provider, todo),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
      ],
    );
  }
}

class _TaskGroupLabel extends StatelessWidget {
  final _TaskPriority priority;
  final int count;

  const _TaskGroupLabel({required this.priority, required this.count});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: priority.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            priority.label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: themeProvider.textTertiary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: priority.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: priority.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final DailyTodo todo;
  final _TaskPriority priority;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskRow({
    required this.todo,
    required this.priority,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final time = DateFormat('HH:mm').format(todo.createdAt);
    final textColor = todo.isCompleted
        ? themeProvider.textTertiary
        : themeProvider.textPrimary;

    return SwipeToDismissWrapper(
      itemId: todo.id,
      onDelete: onDelete,
      child: Material(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeProvider.isDarkMode
                    ? Colors.white.withValues(alpha: 0.07)
                    : AppColors.textPrimary.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: themeProvider.isDarkMode ? 0.22 : 0.04,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                  spreadRadius: -12,
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: todo.isCompleted
                        ? priority.color
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: todo.isCompleted
                          ? priority.color
                          : themeProvider.textTertiary.withValues(alpha: 0.42),
                      width: 2,
                    ),
                  ),
                  child: todo.isCompleted
                      ? const Icon(
                          LucideIcons.check,
                          color: Colors.white,
                          size: 15,
                        )
                      : null,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 12,
                            color: themeProvider.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: themeProvider.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: priority.color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                priority.shortLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: priority.color,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  LucideIcons.chevronLeft,
                  size: 16,
                  color: themeProvider.textTertiary.withValues(alpha: 0.65),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTasksBlock extends StatelessWidget {
  final VoidCallback onAddTap;

  const _EmptyTasksBlock({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: themeProvider.isDarkMode
              ? Colors.white.withValues(alpha: 0.07)
              : AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Image.asset('assets/images/tasks_card_1.png', width: 116),
          const SizedBox(height: 12),
          Text(
            'No tasks here',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add one gentle next step for today.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeProvider.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAddTap,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add task'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  final ThemeProvider themeProvider;

  const _LoadingBlock({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: CircularProgressIndicator(color: themeProvider.primaryColor),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBlock({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: themeProvider.textPrimary),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  final Color trackColor;

  const _ProgressRing({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: CustomPaint(
        painter: _ProgressRingPainter(
          progress: progress.clamp(0.0, 1.0).toDouble(),
          color: color,
          trackColor: trackColor,
        ),
        child: Center(
          child: Text(
            '${(progress * 100).round()}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - 6) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

enum _TaskPriority {
  high('High Priority', 'High', AppColors.primary),
  medium('Medium Priority', 'Medium', AppColors.moodDeep),
  low('Low Priority', 'Low', AppColors.routineDeep);

  final String label;
  final String shortLabel;
  final Color color;

  const _TaskPriority(this.label, this.shortLabel, this.color);
}
