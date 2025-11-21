import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_header_widget.dart';
import '../widgets/todo_card_widget.dart';
import '../../../../core/providers/theme_provider.dart';

/// Ana todo sayfası - main.dart'taki todo gösterim kodlarından taşındı
class TodoPage extends StatefulWidget {
  final bool showFullPage;

  const TodoPage({super.key, this.showFullPage = true});

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
    final themeProvider = context.watch<ThemeProvider>();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TodoHeaderWidget(),
        const SizedBox(height: 24),
        const TodoCardWidget(),
      ],
    );

    if (widget.showFullPage) {
      return Container(
        decoration: BoxDecoration(color: themeProvider.backgroundColor),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                content,
                const SizedBox(height: 20), // Bottom padding for navigation bar
              ],
            ),
          ),
        ),
      );
    } else {
      return content;
    }
  }
}
