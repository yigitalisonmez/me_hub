import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import '../providers/todo_provider.dart';
import '../../domain/entities/daily_todo.dart';
import 'add_todo_dialog.dart';
import '../../../../core/widgets/elevated_card.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';

/// Todo card widget'ı - HomePage ve TodoPage'de kullanılabilir
class TodoCardWidget extends StatelessWidget {
  const TodoCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        // Show celebration if all todos just became completed (only after toggle/delete)
        if (provider.justCompletedAllTodos) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showCelebrationDialog(context);
            provider.resetJustCompletedAllTodos();
          });
        }

        return ElevatedCard(
          child: Column(
            children: [
              // Header with title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.target,
                    color: themeProvider.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'TODAY\'S GOALS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.primaryColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                height: 2,
                width: 60,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),

              // Progress Stats Header (only if there are todos)
              if (provider.todos.isNotEmpty) ...[
                _buildProgressHeader(context, provider, themeProvider),
                const SizedBox(height: 20),
              ],

              // Todo list inside the card
              if (provider.todos.isEmpty) ...[
                _buildEnhancedEmptyState(context, themeProvider),
              ] else ...[
                // Priority Grouped Todos
                _buildPriorityGroupedTodos(context, provider, themeProvider),
                const SizedBox(height: 16),
                _buildActionButton(
                  context: context,
                  text: 'Add New Goal',
                  icon: LucideIcons.plus,
                  isPrimary: true,
                  onPressed: () => _showAddTodoDialog(context),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Progress header with circular indicator
  Widget _buildProgressHeader(
    BuildContext context,
    TodoProvider provider,
    ThemeProvider themeProvider,
  ) {
    final completedCount = provider.completedCount;
    final totalCount = provider.totalTodos;
    final progress = provider.completionRate;
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeProvider.primaryColor.withValues(alpha: 0.1),
            themeProvider.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Circular Progress Indicator
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 6,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      themeProvider.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                // Progress circle
                SizedBox(
                  width: 64,
                  height: 64,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return CustomPaint(
                        painter: _CircularProgressPainter(
                          progress: value,
                          color: themeProvider.primaryColor,
                          strokeWidth: 6,
                        ),
                      );
                    },
                  ),
                ),
                // Center text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress == 1.0 ? '🎉 All Done!' : 'Keep going!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedCount of $totalCount tasks completed',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: themeProvider.primaryColor.withValues(
                      alpha: 0.2,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      themeProvider.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Enhanced empty state with Lottie animation
  Widget _buildEnhancedEmptyState(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return Column(
      children: [
        // Lottie animation
        Lottie.asset(
          'assets/animations/streak.json',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              LucideIcons.clipboardList200,
              size: 60,
              color: themeProvider.primaryColor,
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'No goals yet!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeProvider.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'What would you like to accomplish today?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: themeProvider.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Quick add suggestions
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildQuickAddChip(context, '🏃 Exercise', themeProvider),
            _buildQuickAddChip(context, '📚 Read', themeProvider),
            _buildQuickAddChip(context, '🧘 Meditate', themeProvider),
          ],
        ),
        const SizedBox(height: 24),

        _buildActionButton(
          context: context,
          text: 'Add New Goal',
          icon: LucideIcons.plus,
          isPrimary: true,
          onPressed: () => _showAddTodoDialog(context),
        ),
      ],
    );
  }

  /// Quick add chip for empty state
  Widget _buildQuickAddChip(
    BuildContext context,
    String label,
    ThemeProvider themeProvider,
  ) {
    return InkWell(
      onTap: () {
        context.read<TodoProvider>().addTodo(title: label, priority: 2);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: themeProvider.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: themeProvider.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: themeProvider.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Priority grouped todos
  Widget _buildPriorityGroupedTodos(
    BuildContext context,
    TodoProvider provider,
    ThemeProvider themeProvider,
  ) {
    // Group todos by priority
    final highPriority = provider.todos.where((t) => t.priority == 1).toList();
    final mediumPriority = provider.todos
        .where((t) => t.priority == 2)
        .toList();
    final lowPriority = provider.todos.where((t) => t.priority == 3).toList();

    return Column(
      children: [
        if (highPriority.isNotEmpty) ...[
          _buildPrioritySection(
            context,
            'High Priority',
            highPriority,
            const Color(0xFFE57373),
            LucideIcons.circleAlert,
            provider,
            themeProvider,
          ),
        ],
        if (mediumPriority.isNotEmpty) ...[
          if (highPriority.isNotEmpty) const SizedBox(height: 12),
          _buildPrioritySection(
            context,
            'Medium Priority',
            mediumPriority,
            const Color(0xFFFFB74D),
            LucideIcons.minus,
            provider,
            themeProvider,
          ),
        ],
        if (lowPriority.isNotEmpty) ...[
          if (highPriority.isNotEmpty || mediumPriority.isNotEmpty)
            const SizedBox(height: 12),
          _buildPrioritySection(
            context,
            'Low Priority',
            lowPriority,
            const Color(0xFF81C784),
            LucideIcons.arrowDown,
            provider,
            themeProvider,
          ),
        ],
      ],
    );
  }

  /// Priority section with header and todos
  Widget _buildPrioritySection(
    BuildContext context,
    String title,
    List<DailyTodo> todos,
    Color color,
    IconData icon,
    TodoProvider provider,
    ThemeProvider themeProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: themeProvider.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${todos.length}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Todo items
        ...todos.map(
          (todo) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildTodoItem(context, todo, provider, color),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    final themeProvider = context.watch<ThemeProvider>();

    final isDark = themeProvider.isDarkMode;

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: themeProvider.primaryColor.withValues(alpha: 0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary
                ? themeProvider.primaryColor
                : themeProvider.surfaceColor,
            foregroundColor: isPrimary
                ? AppColors.white
                : themeProvider.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isPrimary
                  ? BorderSide.none
                  : BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : themeProvider.primaryColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodoItem(
    BuildContext context,
    DailyTodo todo,
    TodoProvider provider,
    Color priorityColor,
  ) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(LucideIcons.trash2, color: AppColors.error),
      ),
      confirmDismiss: (direction) async {
        // Delete the todo and return false to prevent Dismissible state issues
        // The widget will be removed when provider notifies listeners
        provider.deleteTodo(todo.id);
        return false;
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeProvider.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.white,
              offset: const Offset(0, -1),
              blurRadius: 2,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : themeProvider.primaryColor.withValues(alpha: 0.05),
              offset: const Offset(0, 3),
              blurRadius: 6,
              spreadRadius: -1,
            ),
          ],
        ),
        child: Row(
          children: [
            // Priority color indicator
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Animated Checkbox
            _AnimatedCheckbox(
              isChecked: todo.isCompleted,
              color: themeProvider.primaryColor,
              onTap: () => provider.toggleTodoCompletion(todo.id),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: TextStyle(
                      decoration: todo.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: todo.isCompleted
                          ? themeProvider.textSecondary
                          : themeProvider.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Swipe hint
            Icon(
              LucideIcons.chevronLeft,
              size: 16,
              color: themeProvider.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
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

  void _showCelebrationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      barrierDismissible: false,
      builder: (context) {
        // Auto-close after 1.5 seconds
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
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
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              );
            },
          ),
        );
      },
    );
  }
}

/// Animated Checkbox with scale effect
class _AnimatedCheckbox extends StatefulWidget {
  final bool isChecked;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedCheckbox({
    required this.isChecked,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<_AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: widget.isChecked ? widget.color : Colors.transparent,
                border: Border.all(
                  color: widget.isChecked
                      ? widget.color
                      : widget.color.withValues(alpha: 0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: widget.isChecked
                  ? const Icon(
                      LucideIcons.check,
                      color: AppColors.white,
                      size: 16,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for circular progress
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularProgressPainter({
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
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
