import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../domain/entities/daily_todo.dart';
import '../../../../core/theme/app_colors.dart';

/// Todo item widget'ı
class TodoItem extends StatelessWidget {
  final DailyTodo todo;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const TodoItem({
    super.key,
    required this.todo,
    this.onTap,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildCheckbox(),
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
                              ? AppColors.grey
                              : AppColors.darkGrey,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildSubtitle(),
                    ],
                  ),
                ),
                _buildTrailing(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: todo.isCompleted ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: todo.isCompleted
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: todo.isCompleted
          ? const Icon(LucideIcons.check, color: AppColors.white, size: 16)
          : null,
    );
  }

  Widget _buildSubtitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            todo.priorityText,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // No extra subtitle colors needed currently

  Widget _buildTrailing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (todo.isCompleted) ...[
          Icon(LucideIcons.circleCheck, color: AppColors.success, size: 20),
          const SizedBox(width: 8),
        ],
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'toggle':
                onToggle?.call();
                break;
              case 'delete':
                onDelete?.call();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    todo.isCompleted ? LucideIcons.undo2 : LucideIcons.check,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(todo.isCompleted ? 'Geri Al' : 'Tamamla'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Sil'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
