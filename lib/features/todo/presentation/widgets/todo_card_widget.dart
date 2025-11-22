import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lottie/lottie.dart';
import '../providers/todo_provider.dart';
import 'add_todo_dialog.dart';
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
            children: [
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

              // Todo list inside the card
              if (provider.todos.isEmpty) ...[
                Icon(
                  LucideIcons.clipboardList200,
                  size: 60,
                  color: themeProvider.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Set your daily goals and track your progress',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: themeProvider.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Productivity',
                    style: TextStyle(
                      color: themeProvider.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  context: context,
                  text: 'Add New Goal',
                  icon: LucideIcons.plus,
                  isPrimary: true,
                  onPressed: () => _showAddTodoDialog(context),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context: context,
                  text: 'View Progress',
                  icon: LucideIcons.trendingUp,
                  isPrimary: false,
                  onPressed: () {
                    // TODO: Navigate to progress page
                  },
                ),
              ] else ...[
                // Show todos inside the card
                ...provider.todos.map(
                  (todo) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: _buildTodoItem(context, todo, provider),
                  ),
                ),
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

  Widget _buildActionButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    final themeProvider = context.watch<ThemeProvider>();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: isPrimary ? null : themeProvider.cardColor,
              foregroundColor: isPrimary
                  ? AppColors.white
                  : themeProvider.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isPrimary
                    ? BorderSide.none
                    : BorderSide(
                        color: themeProvider.primaryColor.withValues(
                          alpha: 0.3,
                        ),
                      ),
              ),
            ).copyWith(
              backgroundColor: isPrimary
                  ? MaterialStateProperty.all<Color>(themeProvider.primaryColor)
                  : MaterialStateProperty.all<Color>(themeProvider.cardColor),
            ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoItem(BuildContext context, todo, TodoProvider provider) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeProvider.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => provider.toggleTodoCompletion(todo.id),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: todo.isCompleted
                    ? themeProvider.primaryColor
                    : Colors.transparent,
                border: Border.all(
                  color: todo.isCompleted
                      ? themeProvider.primaryColor
                      : themeProvider.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: todo.isCompleted
                  ? const Icon(
                      LucideIcons.check,
                      color: AppColors.white,
                      size: 16,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        todo.priorityText,
                        style: TextStyle(
                          color: themeProvider.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                provider.deleteTodo(todo.id);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.trash2,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete',
                      style: TextStyle(color: themeProvider.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
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
