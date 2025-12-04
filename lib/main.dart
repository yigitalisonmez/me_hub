import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_extensions.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/theme_provider.dart';
import 'features/todo/data/datasources/todo_local_datasource.dart';
import 'features/todo/data/repositories/todo_repository_impl.dart';
import 'features/todo/domain/usecases/get_today_todos.dart';
import 'features/todo/domain/usecases/get_all_todos.dart';
import 'features/todo/domain/usecases/add_todo.dart';
import 'features/todo/domain/usecases/update_todo.dart';
import 'features/todo/domain/usecases/delete_todo.dart';
import 'features/todo/domain/usecases/toggle_todo_completion.dart';
import 'features/todo/presentation/providers/todo_provider.dart';
import 'features/todo/domain/entities/daily_todo.dart';
import 'features/todo/data/models/daily_todo_model.dart';
import 'features/quote/presentation/widgets/daily_quote_widget.dart';
import 'features/todo/presentation/widgets/todo_header_widget.dart';
import 'features/todo/presentation/widgets/todo_card_widget.dart';
import 'features/routines/presentation/pages/routines_page.dart';
import 'features/routines/presentation/providers/routines_provider.dart';
import 'features/routines/data/datasources/routine_local_datasource.dart';
import 'features/routines/data/repositories/routine_repository_impl.dart'
    as RoutinesRepo;
import 'features/routines/domain/usecases/usecases.dart' as RoutinesUsecases;
import 'features/routines/domain/entities/routine.dart' as RoutineEntities;
import 'features/water/presentation/pages/water_page.dart';
import 'features/water/presentation/providers/water_provider.dart';
import 'features/mood_tracker/presentation/pages/mood_page.dart';
import 'features/mood_tracker/presentation/providers/mood_provider.dart';
import 'features/mood_tracker/data/datasources/mood_local_datasource.dart';
import 'features/mood_tracker/domain/entities/mood_entry.dart';
import 'features/water/data/datasources/water_local_datasource.dart';
import 'features/water/data/repositories/water_repository_impl.dart';
import 'features/water/domain/usecases/usecases.dart' as WaterUsecases;
import 'features/water/domain/entities/water_intake.dart';
import 'core/services/notification_service.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive'ı başlat
  await Hive.initFlutter();

  // Hive adapter'larını kaydet
  Hive.registerAdapter(DailyTodoAdapter());
  Hive.registerAdapter(DailyTodoModelAdapter());
  Hive.registerAdapter(RoutineEntities.RoutineItemAdapter());
  Hive.registerAdapter(RoutineEntities.RoutineAdapter());
  Hive.registerAdapter(WaterIntakeAdapter());
  Hive.registerAdapter(WaterLogAdapter());
  Hive.registerAdapter(MoodEntryAdapter());

  // Data source'ları başlat
  final todoDataSource = TodoLocalDataSourceImpl();
  await todoDataSource.init();
  final routinesDataSource = RoutineLocalDataSourceImpl();
  await routinesDataSource.init();
  final waterBox = await Hive.openBox<WaterIntake>('water_intake');
  final waterDataSource = WaterLocalDataSource(waterBox);
  final moodDataSource = MoodLocalDataSource();
  await moodDataSource.init();

  // Notification service'i başlat
  await NotificationService().initialize();

  // Check onboarding status
  // final prefs = await SharedPreferences.getInstance();
  final showOnboarding = true; // !prefs.containsKey('onboarding_completed'); // Forced true for testing

  runApp(
    MeHubApp(
      todoDataSource: todoDataSource,
      routinesDataSource: routinesDataSource,
      waterDataSource: waterDataSource,
      moodDataSource: moodDataSource,
      showOnboarding: showOnboarding,
    ),
  );
}

class MeHubApp extends StatelessWidget {
  final TodoLocalDataSource todoDataSource;
  final RoutineLocalDataSource routinesDataSource;
  final WaterLocalDataSource waterDataSource;
  final MoodLocalDataSource moodDataSource;
  final bool showOnboarding;

  const MeHubApp({
    super.key,
    required this.todoDataSource,
    required this.routinesDataSource,
    required this.waterDataSource,
    required this.moodDataSource,
    required this.showOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TodoRepositoryImpl>(
          create: (_) => TodoRepositoryImpl(localDataSource: todoDataSource),
        ),
        Provider<RoutinesRepo.RoutineRepositoryImpl>(
          create: (_) =>
              RoutinesRepo.RoutineRepositoryImpl(local: routinesDataSource),
        ),
        Provider<WaterRepositoryImpl>(
          create: (_) => WaterRepositoryImpl(waterDataSource),
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
        ChangeNotifierProvider<WaterProvider>(
          create: (context) => WaterProvider(
            getTodayWaterIntake: WaterUsecases.GetTodayWaterIntake(
              context.read<WaterRepositoryImpl>(),
            ),
            addWater: WaterUsecases.AddWater(
              context.read<WaterRepositoryImpl>(),
            ),
            removeLastLog: WaterUsecases.RemoveLastLog(
              context.read<WaterRepositoryImpl>(),
            ),
            updateWaterIntake: WaterUsecases.UpdateWaterIntake(
              context.read<WaterRepositoryImpl>(),
            ),
          ),
        ),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<MoodProvider>(
          create: (_) => MoodProvider(moodDataSource),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme.copyWith(
              extensions: const <ThemeExtension<dynamic>>[AppColorScheme.light],
            ),
            darkTheme: AppTheme.darkTheme.copyWith(
              extensions: const <ThemeExtension<dynamic>>[AppColorScheme.dark],
            ),
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: showOnboarding ? const OnboardingPage() : const HomePage(),
          );
        },
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
      // Uygulama açıldığında rutinleri yükle ve bildirimleri yeniden zamanla
      _rescheduleNotifications();
    });
  }

  Future<void> _rescheduleNotifications() async {
    try {
      final routinesProvider = context.read<RoutinesProvider>();
      await routinesProvider.loadRoutines();
      final routines = routinesProvider.routines;
      if (routines.isNotEmpty) {
        await NotificationService().rescheduleAllRoutineNotifications(routines);
        // Debug: Zamanlanmış bildirimleri kontrol et
        await NotificationService().checkPendingNotifications();
      }
    } catch (e) {
      debugPrint('Bildirimleri yeniden zamanlama hatası: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: Stack(children: [_buildPageView(), _buildCelebrationOverlay()]),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildPageView() {
    // Use PageView.builder for true lazy loading - pages are only built when needed
    return PageView.builder(
      controller: _pageController,
      physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      itemCount: 5, // Total number of pages
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return _buildHomeContent();
          case 1:
            return const WaterPage();
          case 2:
            return const RoutinesPage();
          case 3:
            return const MoodPage();
          case 4:
            return _buildSettingsPage();
          default:
            return _buildHomeContent();
        }
      },
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Header - TodoPage'den
            const TodoHeaderWidget(),
            const SizedBox(height: 24),
            const DailyQuoteWidget(),
            const SizedBox(height: 20),
            // Todo Card - TodoPage'den
            const TodoCardWidget(),
            const SizedBox(height: 20), // Bottom padding for navigation bar
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPage() {
    return SafeArea(
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
    );
  }

  Widget _buildBottomNavigationBar() {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.1),
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
        backgroundColor: themeProvider.cardColor,
        selectedItemColor: themeProvider.primaryColor,
        unselectedItemColor: themeProvider.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.calendar),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.droplet),
            label: 'Water',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.repeat),
            label: 'Routines',
          ),
          BottomNavigationBarItem(icon: Icon(LucideIcons.heart), label: 'Mood'),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

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
                LucideIcons.settings,
                color: themeProvider.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.settings,
                color: themeProvider.primaryColor,
                size: 24,
              ),
            ],
          ),
          Container(
            height: 2,
            width: 100,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 20),
          Icon(
            LucideIcons.slidersHorizontal,
            size: 60,
            color: themeProvider.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Customize your experience and manage your preferences',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: themeProvider.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          // Dark Mode Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeProvider.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeProvider.borderColor, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.palette,
                      color: themeProvider.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dark Mode',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: themeProvider.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Switch to dark theme',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: themeProvider.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.setTheme(value);
                  },
                  activeColor: themeProvider.primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Test Notification Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeProvider.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeProvider.borderColor, width: 2),
            ),
            child: InkWell(
              onTap: () async {
                try {
                  await NotificationService().showTestNotification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Test bildirimi gönderildi!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.bell,
                    color: themeProvider.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Notification',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: themeProvider.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Send a test notification now',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: themeProvider.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Check Pending Notifications Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeProvider.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeProvider.borderColor, width: 2),
            ),
            child: InkWell(
              onTap: () async {
                try {
                  await NotificationService().checkPendingNotifications();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Bildirimler kontrol edildi! Console loglarına bakın.'),
                        backgroundColor: Colors.blue,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.check,
                    color: themeProvider.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check Notifications',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: themeProvider.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Check scheduled notifications',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: themeProvider.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationOverlay() {
    return const SizedBox.shrink();
  }
}
