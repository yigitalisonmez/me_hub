import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lottie/lottie.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item.dart';
import '../widgets/add_todo_dialog.dart';
import '../../../../core/theme/app_colors.dart';
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
    print('🔵 TodoPage: initState() called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔵 TodoPage: PostFrameCallback called');
      final provider = context.read<TodoProvider>();
      provider.loadTodayTodos().then((_) {
        // Initialize flag based on current state after loading
        if (mounted) {
          setState(() {
            _previousAllCompleted = provider.allTodosCompleted;
            print('🔵 TodoPage: initState - Initial _previousAllCompleted set to: $_previousAllCompleted');
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 TodoPage: build() called');
    final provider = context.watch<TodoProvider>();
    print('🔵 TodoPage: context.watch called - provider obtained');
    
    // Check if all todos are completed
    final isAllCompleted = provider.allTodosCompleted;
    final todosCount = provider.todos.length;
    
    print('🔵 TodoPage: Rebuild - isAllCompleted: $isAllCompleted, todosCount: $todosCount, _previousAllCompleted: $_previousAllCompleted');
    print('🔵 TodoPage: Completed count: ${provider.completedCount}, Total count: ${provider.totalTodos}');
    
    // Debug: Print condition check
    print('🔵 TodoPage: Condition check - !_previousAllCompleted: ${!_previousAllCompleted}, isAllCompleted: $isAllCompleted, todosCount > 0: ${todosCount > 0}');
    
    // If all todos just became completed (wasn't before, but is now)
    if (!_previousAllCompleted && isAllCompleted && todosCount > 0) {
      print('🟢 TodoPage: Condition met! All todos just completed!');
      // Update previous state BEFORE showing animation to prevent multiple triggers
      _previousAllCompleted = true;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print('🟢 TodoPage: All todos completed! Showing celebration dialog');
          print('🟢 TodoPage: Total todos: $todosCount');
          print('🟢 TodoPage: Completed todos: ${provider.completedCount}');
          _showCelebrationDialog(context);
        }
      });
    } else if (!isAllCompleted) {
      // Reset flag when todos become incomplete again
      if (_previousAllCompleted) {
        print('🟡 TodoPage: Todos became incomplete, resetting flag');
      }
      _previousAllCompleted = false;
    } else {
      print('🔴 TodoPage: Condition NOT met - _previousAllCompleted: $_previousAllCompleted, isAllCompleted: $isAllCompleted');
    }
    
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.arrowLeft,
              color: AppColors.primaryOrange,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Daily Goals',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.darkGrey,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.refreshCw,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
              ),
              onPressed: () => context.read<TodoProvider>().loadTodayTodos(),
            ),
          ),
        ],
      ),
      body: provider.isLoading && provider.todos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _buildErrorWidget(provider)
              : _buildTodoList(provider),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddTodoDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(LucideIcons.plus, color: AppColors.white),
          label: Text(
            'Add Goal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(TodoProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.circleAlert, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'An error occurred',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            provider.error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.grey,
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
      children: [
        _buildDateHeader(context),
        Expanded(
          child: ListView.builder(
            itemCount: provider.todos.length,
            itemBuilder: (context, index) {
              final todo = provider.todos[index];
              return TodoItem(
                todo: todo,
                onToggle: () {
                  print('🟡 TodoPage: onToggle called for todo: ${todo.title}');
                  provider.toggleTodoCompletion(todo.id);
                },
                onDelete: () => _showDeleteDialog(context, provider, todo.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.clipboardList,
            size: 80,
            color: AppColors.primaryOrange.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No todos yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first daily goal',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Add Todo',
            onPressed: () => _showAddTodoDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    final theme = Theme.of(context);
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
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.08),
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
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.calendar,
              color: AppColors.primaryOrange,
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
                    color: AppColors.darkGrey,
                  ),
                ),
                Text(
                  weekdays[now.weekday - 1],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey,
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
    print('🟢 TodoPage: _showCelebrationDialog called');
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      barrierDismissible: true,
      builder: (context) {
        print('🟢 TodoPage: Dialog builder called');
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
                  print('🔴 TodoPage: Lottie error: $error');
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
                  color: Colors.white,
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
