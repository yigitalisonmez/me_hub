import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_extensions.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/theme_provider.dart';
import 'features/home/presentation/pages/home_page.dart';
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
import 'features/routines/presentation/providers/routines_provider.dart';
import 'features/routines/data/datasources/routine_local_datasource.dart';
import 'features/routines/data/repositories/routine_repository_impl.dart'
    as RoutinesRepo;
import 'features/routines/domain/usecases/usecases.dart' as RoutinesUsecases;
import 'features/routines/domain/entities/routine.dart' as RoutineEntities;
import 'features/water/presentation/providers/water_provider.dart';
import 'features/mood_tracker/presentation/providers/mood_provider.dart';
import 'features/mood_tracker/data/datasources/mood_local_datasource.dart';
import 'features/mood_tracker/domain/entities/mood_entry.dart';
import 'features/water/data/datasources/water_local_datasource.dart';
import 'features/water/data/repositories/water_repository_impl.dart';
import 'features/water/domain/usecases/usecases.dart' as WaterUsecases;
import 'features/water/domain/entities/water_intake.dart';
import 'core/services/notification_service.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';

import 'features/profile/presentation/pages/profile_page.dart';
import 'core/widgets/voice_command_sheet.dart';
import 'core/providers/voice_settings_provider.dart';
import 'core/widgets/glass_nav_bar.dart';
import 'features/affirmations/presentation/providers/affirmation_provider.dart';
import 'features/breathing/presentation/providers/breathing_provider.dart';
import 'features/gratitude/domain/entities/gratitude_entry.dart';
import 'features/gratitude/domain/entities/gratitude_item.dart';
import 'features/gratitude/data/datasources/gratitude_local_datasource.dart';
import 'features/gratitude/data/repositories/gratitude_repository_impl.dart';
import 'features/gratitude/domain/usecases/usecases.dart' as GratitudeUsecases;
import 'features/gratitude/presentation/providers/gratitude_provider.dart';

// Challenges feature imports
import 'features/challenges/domain/entities/challenge.dart'
    as ChallengeEntities;
import 'features/challenges/domain/entities/weekly_goal.dart'
    as WeeklyGoalEntities;
import 'features/challenges/domain/entities/badge.dart' as BadgeEntities;
import 'features/challenges/domain/entities/user_progress.dart'
    as UserProgressEntities;
import 'features/challenges/data/datasources/challenges_local_datasource.dart';
import 'features/challenges/data/repositories/challenges_repository_impl.dart';
import 'features/challenges/presentation/providers/challenges_provider.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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
  Hive.registerAdapter(GratitudeEntryAdapter());
  Hive.registerAdapter(GratitudeItemAdapter());
  Hive.registerAdapter(EntryTypeAdapter());

  // Challenges adapters
  Hive.registerAdapter(ChallengeEntities.ChallengeAdapter());
  Hive.registerAdapter(ChallengeEntities.ChallengeCategoryAdapter());
  Hive.registerAdapter(ChallengeEntities.DailyProgressAdapter());
  Hive.registerAdapter(WeeklyGoalEntities.WeeklyGoalAdapter());
  Hive.registerAdapter(WeeklyGoalEntities.GoalTypeAdapter());
  Hive.registerAdapter(BadgeEntities.BadgeAdapter());
  Hive.registerAdapter(BadgeEntities.BadgeTierAdapter());
  Hive.registerAdapter(BadgeEntities.BadgeRequirementTypeAdapter());
  Hive.registerAdapter(UserProgressEntities.UserProgressAdapter());

  // Data source'ları başlat
  final todoDataSource = TodoLocalDataSourceImpl();
  await todoDataSource.init();
  final routinesDataSource = RoutineLocalDataSourceImpl();
  await routinesDataSource.init();
  final waterBox = await Hive.openBox<WaterIntake>('water_intake');
  final waterDataSource = WaterLocalDataSource(waterBox);
  final moodDataSource = MoodLocalDataSource();
  await moodDataSource.init();
  final gratitudeDataSource = GratitudeLocalDataSource();
  await gratitudeDataSource.init();
  final challengesDataSource = ChallengesLocalDataSource();
  await challengesDataSource.init();

  // Notification service'i başlat
  await NotificationService().initialize();

  // Check onboarding status
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = !prefs.containsKey('onboarding_completed');

  runApp(
    MeHubApp(
      todoDataSource: todoDataSource,
      routinesDataSource: routinesDataSource,
      waterDataSource: waterDataSource,
      moodDataSource: moodDataSource,
      gratitudeDataSource: gratitudeDataSource,
      challengesDataSource: challengesDataSource,
      showOnboarding: showOnboarding,
    ),
  );
}

class MeHubApp extends StatelessWidget {
  final TodoLocalDataSource todoDataSource;
  final RoutineLocalDataSource routinesDataSource;
  final WaterLocalDataSource waterDataSource;
  final MoodLocalDataSource moodDataSource;
  final GratitudeLocalDataSource gratitudeDataSource;
  final ChallengesLocalDataSource challengesDataSource;
  final bool showOnboarding;

  const MeHubApp({
    super.key,
    required this.todoDataSource,
    required this.routinesDataSource,
    required this.waterDataSource,
    required this.moodDataSource,
    required this.gratitudeDataSource,
    required this.challengesDataSource,
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
        ChangeNotifierProvider<VoiceSettingsProvider>(
          create: (_) => VoiceSettingsProvider(),
        ),
        ChangeNotifierProvider<AffirmationProvider>(
          create: (_) => AffirmationProvider(),
        ),
        ChangeNotifierProvider<BreathingProvider>(
          create: (_) => BreathingProvider(),
        ),
        Provider<GratitudeRepositoryImpl>(
          create: (_) => GratitudeRepositoryImpl(gratitudeDataSource),
        ),
        ChangeNotifierProvider<GratitudeProvider>(
          create: (context) => GratitudeProvider(
            addEntry: GratitudeUsecases.AddGratitudeEntry(
              context.read<GratitudeRepositoryImpl>(),
            ),
            getTodayEntry: GratitudeUsecases.GetTodayGratitudeEntry(
              context.read<GratitudeRepositoryImpl>(),
            ),
            getAllEntries: GratitudeUsecases.GetAllGratitudeEntries(
              context.read<GratitudeRepositoryImpl>(),
            ),
            getRandomPastEntry: GratitudeUsecases.GetRandomPastGratitudeEntry(
              context.read<GratitudeRepositoryImpl>(),
            ),
            updateEntry: GratitudeUsecases.UpdateGratitudeEntry(
              context.read<GratitudeRepositoryImpl>(),
            ),
            deleteEntry: GratitudeUsecases.DeleteGratitudeEntry(
              context.read<GratitudeRepositoryImpl>(),
            ),
            getStreak: GratitudeUsecases.GetGratitudeStreak(
              context.read<GratitudeRepositoryImpl>(),
            ),
            getEmotionTagStats: GratitudeUsecases.GetEmotionTagStats(
              context.read<GratitudeRepositoryImpl>(),
            ),
          ),
        ),
        // Challenges Provider
        Provider<ChallengesRepositoryImpl>(
          create: (_) => ChallengesRepositoryImpl(challengesDataSource),
        ),
        ChangeNotifierProvider<ChallengesProvider>(
          create: (context) =>
              ChallengesProvider(context.read<ChallengesRepositoryImpl>()),
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
            home: showOnboarding ? const OnboardingPage() : const MainScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        extendBody: true,
        body: Stack(
          children: [
            _buildPageView(),
            _buildCelebrationOverlay(),
            // Navbar positioned at the bottom of the Stack
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomNavigationBar(),
            ),
          ],
        ),
        // FAB removed - mic is now in navbar
      ),
    );
  }

  Widget _buildPageView() {
    // 2 pages: Home, Profile
    return PageView.builder(
      controller: _pageController,
      physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      itemCount: 2,
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return HomePage(
              onNavigateToPage: (pageIndex) {
                _pageController.animateToPage(
                  pageIndex,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ); // Home/Dashboard
          case 1:
            return ProfilePage(
              onNavigateToPage: (pageIndex) {
                _pageController.animateToPage(
                  pageIndex,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            );
          default:
            return const HomePage();
        }
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return GlassNavBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      onMicTap: () => showVoiceCommandSheet(context),
    );
  }

  Widget _buildCelebrationOverlay() {
    return const SizedBox.shrink();
  }
}
