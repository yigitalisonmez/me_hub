import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/todo_provider.dart';
import '../../../../core/providers/theme_provider.dart';

/// Todo header widget'ı - HomePage ve TodoPage'de kullanılabilir
class TodoHeaderWidget extends StatelessWidget {
  const TodoHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
}

