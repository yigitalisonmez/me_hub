import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lottie/lottie.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item.dart';
import '../widgets/add_todo_dialog.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/custom_button.dart';

/// Ana todo sayfası
class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  bool _previousAllCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TodoProvider>();
      provider.loadTodayTodos().then((_) {
        // Initialize flag based on current state after loading
        if (mounted) {
          setState(() {
            _previousAllCompleted = provider.allTodosCompleted;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();

    // Check if all todos are completed
    final isAllCompleted = provider.allTodosCompleted;
    final todosCount = provider.todos.length;

    // If all todos just became completed (wasn't before, but is now)
    if (!_previousAllCompleted && isAllCompleted && todosCount > 0) {
      // Update previous state BEFORE showing animation to prevent multiple triggers
      _previousAllCompleted = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showCelebrationDialog(context);
        }
      });
    } else if (!isAllCompleted) {
      // Reset flag when todos become incomplete again
      _previousAllCompleted = false;
    }

    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      decoration: BoxDecoration(color: themeProvider.backgroundColor),
      child: SafeArea(
        child: Consumer<TodoProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.todos.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return _buildErrorWidget(provider);
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
                  // Content
                  provider.todos.isEmpty
                      ? SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: _buildEmptyState(),
                        )
                      : _buildTodoList(provider),
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
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Goals',
              style: theme.textTheme.displaySmall?.copyWith(
                color: themeProvider.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Stay consistent & achieve',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: themeProvider.textSecondary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => context.read<TodoProvider>().loadTodayTodos(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: themeProvider.borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.refreshCw,
              color: themeProvider.primaryColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(TodoProvider provider) {
    final themeProvider = context.watch<ThemeProvider>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.circleAlert, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'An error occurred',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: themeProvider.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeProvider.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Try Again',
            onPressed: () => provider.loadTodayTodos(),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList(TodoProvider provider) {
    if (provider.todos.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateHeader(context),
        const SizedBox(height: 24),
        ...provider.todos.map((todo) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TodoItem(
              todo: todo,
              onToggle: () => provider.toggleTodoCompletion(todo.id),
              onDelete: () => _showDeleteDialog(context, provider, todo.id),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.clipboardList,
          size: 80,
          color: themeProvider.primaryColor.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 24),
        Text(
          'No todos yet',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: themeProvider.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start by adding your first daily goal',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: themeProvider.textSecondary),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Add Todo',
          onPressed: () => _showAddTodoDialog(context),
        ),
      ],
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: themeProvider.primaryGradient,
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.calendar,
              color: themeProvider.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${now.day} ${months[now.month - 1]}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: themeProvider.textPrimary,
                  ),
                ),
                Text(
                  weekdays[now.weekday - 1],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: themeProvider.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  void _showDeleteDialog(
    BuildContext context,
    TodoProvider provider,
    String todoId,
  ) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete Todo',
      message: 'Are you sure you want to delete this todo?',
    );

    if (confirmed == true) {
      provider.deleteTodo(todoId);
    }
  }

  void _showCelebrationDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/done.lottie',
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
              const SizedBox(height: 16),
              Text(
                'All tasks completed! 🎉',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: themeProvider.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
