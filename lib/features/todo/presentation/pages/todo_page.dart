import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/page_header.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_card_widget.dart';
import '../widgets/add_todo_dialog.dart';

/// Tasks page - Today's Goals and task management
class TodoPage extends StatefulWidget {
  final bool showFullPage;

  const TodoPage({super.key, this.showFullPage = true});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  bool _dataLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoaded) {
      _dataLoaded = true;
      context.read<TodoProvider>().loadTodayTodos();
    }
  }

  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddTodoDialog(
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page Header with Add button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PageHeader(
                  title: "Today's Goals",
                  subtitle: 'One task at a time, you got this!',
                ),
              ),
              const SizedBox(width: 16),
              // Add button
              Container(
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showAddTodoDialog,
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Icon(
                        LucideIcons.plus,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tasks List
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TodoCardWidget(),
                ),
                SizedBox(height: LayoutConstants.getNavbarClearance(context)),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.showFullPage) {
      return Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        body: SafeArea(child: content),
      );
    } else {
      return SafeArea(child: content);
    }
  }
}
