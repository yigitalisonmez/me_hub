import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoProvider>().loadTodayTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Daily Goals',
          style: TextStyle(
            color: AppColors.darkGrey,
            fontWeight: FontWeight.bold,
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
      body: Consumer<TodoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.todos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return _buildErrorWidget(provider);
          }

          return _buildTodoList(provider);
        },
      ),
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
          label: const Text(
            'Add Goal',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
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
            style: const TextStyle(color: AppColors.grey),
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
        _buildDateHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: provider.todos.length,
            itemBuilder: (context, index) {
              final todo = provider.todos[index];
              return TodoItem(
                todo: todo,
                onToggle: () => provider.toggleTodoCompletion(todo.id),
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
          const Text(
            'Start by adding your first daily goal',
            style: TextStyle(color: AppColors.grey),
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

  Widget _buildDateHeader() {
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
                  style: const TextStyle(
                    color: AppColors.darkGrey,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  weekdays[now.weekday - 1],
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
}
