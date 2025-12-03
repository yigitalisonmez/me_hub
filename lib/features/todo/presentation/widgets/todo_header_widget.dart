import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/todo_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/page_header.dart';

/// Todo header widget'ı - HomePage ve TodoPage'de kullanılabilir
class TodoHeaderWidget extends StatelessWidget {
  const TodoHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      title: 'Daily Goals',
      subtitle: 'Stay consistent & achieve',
      actionIcon: LucideIcons.refreshCw,
      onActionTap: () => context.read<TodoProvider>().loadTodayTodos(),
    );
  }
}

