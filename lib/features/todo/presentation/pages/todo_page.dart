import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/page_header.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_card_widget.dart';

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TodoProvider>().loadTodayTodos();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page Header with Settings button (using PageHeader for consistency)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: PageHeader(
            title: "Today's Goals",
            subtitle: 'One task at a time, you got this!',
            actionIcon: LucideIcons.settings,
            onActionTap: () {
              // TODO: Open todo settings
            },
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
