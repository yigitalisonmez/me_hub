import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_extensions.dart';
import 'core/theme/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'features/todo/data/datasources/todo_local_datasource.dart';
import 'features/todo/data/repositories/todo_repository_impl.dart';
import 'features/todo/domain/usecases/get_today_todos.dart';
import 'features/todo/domain/usecases/get_all_todos.dart';
import 'features/todo/domain/usecases/add_todo.dart';
import 'features/todo/domain/usecases/update_todo.dart';
import 'features/todo/domain/usecases/delete_todo.dart';
import 'features/todo/domain/usecases/toggle_todo_completion.dart';
import 'features/todo/presentation/providers/todo_provider.dart';
import 'features/todo/presentation/widgets/add_todo_dialog.dart';
import 'features/todo/domain/entities/daily_todo.dart';
import 'features/todo/data/models/daily_todo_model.dart';
import 'features/quote/presentation/widgets/daily_quote_widget.dart';
import 'core/presentation/splash_screen.dart';
import 'features/celebration/presentation/widgets/celebration_overlay.dart';
import 'features/routines/presentation/pages/routines_page.dart';
import 'features/routines/presentation/providers/routines_provider.dart';
import 'features/routines/data/datasources/routine_local_datasource.dart';
import 'features/routines/data/repositories/routine_repository_impl.dart' as RoutinesRepo;
import 'features/routines/domain/usecases/usecases.dart' as RoutinesUsecases;
import 'features/routines/domain/entities/routine.dart' as RoutineEntities;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive'ı başlat
  await Hive.initFlutter();

  // Hive adapter'larını kaydet
  Hive.registerAdapter(DailyTodoAdapter());
  Hive.registerAdapter(DailyTodoModelAdapter());
  Hive.registerAdapter(RoutineEntities.RoutineItemAdapter());
  Hive.registerAdapter(RoutineEntities.RoutineAdapter());

  // Todo data source'unu başlat
  final todoDataSource = TodoLocalDataSourceImpl();
  await todoDataSource.init();
  final routinesDataSource = RoutineLocalDataSourceImpl();
  await routinesDataSource.init();

  runApp(MeHubApp(
    todoDataSource: todoDataSource,
    routinesDataSource: routinesDataSource,
  ));
}

class MeHubApp extends StatelessWidget {
  final TodoLocalDataSource todoDataSource;
  final RoutineLocalDataSource routinesDataSource;

  const MeHubApp({
    super.key,
    required this.todoDataSource,
    required this.routinesDataSource,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TodoRepositoryImpl>(
          create: (_) => TodoRepositoryImpl(localDataSource: todoDataSource),
        ),
        Provider<RoutinesRepo.RoutineRepositoryImpl>(
          create: (_) => RoutinesRepo.RoutineRepositoryImpl(local: routinesDataSource),
      ),
        ChangeNotifierProvider<TodoProvider>(
          create: (context) => TodoProvider(
            getTodayTodos: GetTodayTodos(context.read<TodoRepositoryImpl>()),
            getAllTodos: GetAllTodos(context.read<TodoRepositoryImpl>()),
            addTodo: AddTodo(context.read<TodoRepositoryImpl>()),
            updateTodo: UpdateTodo(context.read<TodoRepositoryImpl>()),
            deleteTodo: DeleteTodo(context.read<TodoRepositoryImpl>()),
            toggleTodoCompletion: ToggleTodoCompletion(
              context.read<TodoRepositoryImpl>(),
            ),
          ),
        ),
        ChangeNotifierProvider<RoutinesProvider>(
          create: (context) => RoutinesProvider(
            getRoutines: RoutinesUsecases.GetRoutines(
              context.read<RoutinesRepo.RoutineRepositoryImpl>(),
            ),
            addRoutine: RoutinesUsecases.AddRoutine(
              context.read<RoutinesRepo.RoutineRepositoryImpl>(),
            ),
            updateRoutine: RoutinesUsecases.UpdateRoutine(
              context.read<RoutinesRepo.RoutineRepositoryImpl>(),
            ),
            deleteRoutine: RoutinesUsecases.DeleteRoutine(
              context.read<RoutinesRepo.RoutineRepositoryImpl>(),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(
          extensions: const <ThemeExtension<dynamic>>[AppColorScheme.light],
        ),
        home: SplashScreen(child: const HomePage()),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoProvider>().loadTodayTodos();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Stack(children: [_buildPageView(), _buildCelebrationOverlay()]),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildPageView() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      children: [
        _buildHomeContent(),
        _buildProgressPage(),
        const RoutinesPage(),
        _buildSettingsPage(),
      ],
    );
  }

  Widget _buildHomeContent() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const DailyQuoteWidget(),
              _buildMainCard(context),
              const SizedBox(height: 20),
              _buildQuickActions(context),
              const SizedBox(height: 20), // Bottom padding for navigation bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressPage() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildProgressCard(),
              const SizedBox(height: 20), // Bottom padding for navigation bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsPage() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildSettingsCard(),
              const SizedBox(height: 20), // Bottom padding for navigation bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryOrange, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
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
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryOrange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'TODAY\'S GOALS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOrange,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryOrange,
                    size: 24,
                  ),
                ],
              ),
              Container(
                height: 2,
                width: 100,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 20),

              // Todo list inside the card
              if (provider.todos.isEmpty) ...[
                const Icon(
                  Icons.checklist_rtl,
                  size: 60,
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Set your daily goals and track your progress',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.darkGrey,
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
                    color: AppColors.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Productivity',
                    style: TextStyle(
                      color: AppColors.primaryOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  context: context,
                  text: 'Add New Goal',
                  icon: Icons.add,
                  isPrimary: true,
                  onPressed: () => _showAddTodoDialog(context),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context: context,
                  text: 'View Progress',
                  icon: Icons.trending_up,
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
                    child: _buildTodoItem(todo, provider),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  context: context,
                  text: 'Add New Goal',
                  icon: Icons.add,
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: isPrimary ? null : AppColors.white,
              foregroundColor: isPrimary
                  ? AppColors.white
                  : AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isPrimary
                    ? BorderSide.none
                    : BorderSide(
                        color: AppColors.primaryOrange.withValues(alpha: 0.3),
                      ),
              ),
            ).copyWith(
              backgroundColor: isPrimary
                  ? MaterialStateProperty.all<Color>(AppColors.primaryOrange)
                  : MaterialStateProperty.all<Color>(AppColors.white),
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

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.add,
            title: 'Add Goal',
            subtitle: 'New goal',
            onTap: () => _showAddTodoDialog(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.timeline,
            title: 'Progress',
            subtitle: 'Track growth',
            onTap: () {
              // TODO: Navigate to progress page
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryOrange, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGrey,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primaryOrange,
        unselectedItemColor: AppColors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.repeat), label: 'Routines'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.1),
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
              const Icon(
                Icons.trending_up,
                color: AppColors.primaryOrange,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'YOUR PROGRESS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.trending_up,
                color: AppColors.primaryOrange,
                size: 24,
              ),
            ],
          ),
          Container(
            height: 2,
            width: 100,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.analytics, size: 60, color: AppColors.primaryOrange),
          const SizedBox(height: 16),
          const Text(
            'Track your daily progress and see your growth over time',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.darkGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Analytics',
              style: TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.1),
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
              const Icon(
                Icons.settings,
                color: AppColors.primaryOrange,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.settings,
                color: AppColors.primaryOrange,
                size: 24,
              ),
            ],
          ),
          Container(
            height: 2,
            width: 100,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.tune, size: 60, color: AppColors.primaryOrange),
          const SizedBox(height: 16),
          const Text(
            'Customize your experience and manage your preferences',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.darkGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Preferences',
              style: TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoItem(todo, TodoProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.08),
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
                    ? AppColors.primaryOrange
                    : Colors.transparent,
                border: Border.all(
                  color: todo.isCompleted
                      ? AppColors.primaryOrange
                      : AppColors.primaryOrange.withValues(alpha: 0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: todo.isCompleted
                  ? const Icon(Icons.check, color: AppColors.white, size: 16)
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
                        ? AppColors.grey
                        : AppColors.darkGrey,
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
                        color: AppColors.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        todo.priorityText,
                        style: const TextStyle(
                          color: AppColors.primaryOrange,
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
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Relative date text removed for daily-only UI

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

  Widget _buildCelebrationOverlay() {
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        if (!provider.shouldShowCelebration) {
          return const SizedBox.shrink();
        }

        return CelebrationOverlay(
          onAnimationComplete: () {
            provider.markCelebrationShown();
          },
        );
      },
    );
  }
}
