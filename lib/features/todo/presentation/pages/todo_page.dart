import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/layout_constants.dart';
import '../providers/todo_provider.dart';

import '../widgets/todo_card_widget.dart';
import '../widgets/dashboard_widgets.dart';
import '../../../../core/providers/theme_provider.dart';

import '../../../../core/services/quote_cache_service.dart';
import '../../../../core/services/quote_service.dart';
import '../../../../core/widgets/glass_container.dart';

import '../../../water/presentation/providers/water_provider.dart';
import '../../../mood_tracker/presentation/providers/mood_provider.dart';
import '../../../routines/presentation/providers/routines_provider.dart';
import '../widgets/add_todo_dialog.dart';

/// Dashboard / Home page - shows daily overview and quick actions
class TodoPage extends StatefulWidget {
  final bool showFullPage;

  const TodoPage({super.key, this.showFullPage = true});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  Quote? _quote;
  bool _isLoadingQuote = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
    _loadQuote();
  }

  void _loadAllData() {
    // Load all providers data
    context.read<TodoProvider>().loadTodayTodos();
    context.read<WaterProvider>().loadTodayWaterIntake();
    context.read<MoodProvider>().loadTodayMood();
    context.read<RoutinesProvider>().loadRoutines();
  }

  Future<void> _loadQuote() async {
    try {
      final quote = await QuoteCacheService.getDailyQuote();
      if (mounted) {
        setState(() {
          _quote = quote;
          _isLoadingQuote = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingQuote = false;
        });
      }
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

  void _addQuickWater() {
    // Add 250ml water quickly
    context.read<WaterProvider>().addWaterAmount(250);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added 250ml water 💧'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final content = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Card with 3D character and quote
          _buildHeroCard(themeProvider),
          const SizedBox(height: 24),

          // Daily Progress Section
          const DailyProgressSection(),
          const SizedBox(height: 24),

          // Quick Actions
          QuickActionsSection(
            onAddWater: _addQuickWater,
            onAddTask: _showAddTodoDialog,
            onLogMood: () {
              // Navigate to mood tab (index 3)
              // This would need access to the main page controller
            },
            onStartRoutine: () {
              // Navigate to routines tab (index 2)
            },
          ),
          const SizedBox(height: 24),

          // AI Insights Card
          const InsightsCard(),
          const SizedBox(height: 24),

          // Today's Tasks Header
          const TodayTasksPreview(),

          // Todo List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const TodoCardWidget(),
          ),

          SizedBox(height: LayoutConstants.getNavbarClearance(context)),
        ],
      ),
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

  Widget _buildHeroCard(ThemeProvider themeProvider) {
    return Container(
      height: 280,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeProvider.primaryColor.withValues(alpha: 0.9),
                    themeProvider.primaryColor,
                  ],
                ),
              ),
            ),
          ),

          // 3D Character
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            bottom: 80,
            child: Center(
              child: Image.asset(
                'assets/images/home_page_character.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Glassmorphism Quote Overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoadingQuote)
                    Text(
                      'Loading inspiration...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else if (_quote != null) ...[
                    Text(
                      '"${_quote!.text}"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '— ${_quote!.author}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else
                    const Text(
                      'Start your day with purpose.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Greeting Badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getGreeting(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '☀️ Good Morning';
    } else if (hour < 17) {
      return '🌤️ Good Afternoon';
    } else {
      return '🌙 Good Evening';
    }
  }
}
