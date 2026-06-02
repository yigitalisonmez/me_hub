import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/services.dart';
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
    as routines_repo;
import 'features/routines/domain/usecases/usecases.dart' as routines_usecases;
import 'features/routines/domain/entities/routine.dart' as routine_entities;
import 'features/water/presentation/providers/water_provider.dart';
import 'features/mood_tracker/presentation/providers/mood_provider.dart';
import 'features/mood_tracker/data/datasources/mood_local_datasource.dart';
import 'features/mood_tracker/domain/entities/mood_entry.dart';
import 'features/water/data/datasources/water_local_datasource.dart';
import 'features/water/data/repositories/water_repository_impl.dart';
import 'features/water/domain/usecases/usecases.dart' as water_usecases;
import 'features/water/domain/entities/water_intake.dart';
import 'core/services/notification_service.dart';
import 'features/analytics/domain/usecases/compute_weekly_insight.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/timer/presentation/providers/timer_provider.dart';

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
import 'features/gratitude/domain/usecases/usecases.dart' as gratitude_usecases;
import 'features/gratitude/presentation/providers/gratitude_provider.dart';

// Challenges feature imports
import 'features/challenges/domain/entities/challenge.dart'
    as challenge_entities;
import 'features/challenges/domain/entities/weekly_goal.dart'
    as weekly_goal_entities;
import 'features/challenges/domain/entities/badge.dart' as badge_entities;
import 'features/challenges/domain/entities/user_progress.dart'
    as user_progress_entities;
import 'features/challenges/data/datasources/challenges_local_datasource.dart';
import 'features/challenges/data/repositories/challenges_repository_impl.dart';
import 'features/challenges/presentation/providers/challenges_provider.dart';

// Calendar imports
import 'features/calendar/presentation/providers/calendar_provider.dart';
import 'features/calendar/data/datasources/calendar_local_datasource.dart';
import 'features/calendar/domain/entities/calendar_event.dart';
import 'features/calendar/domain/entities/event_category.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Hive'ı başlat
  await Hive.initFlutter();

  // Hive adapter'larını kaydet
  Hive.registerAdapter(DailyTodoAdapter());
  Hive.registerAdapter(DailyTodoModelAdapter());
  Hive.registerAdapter(routine_entities.RoutineItemAdapter());
  Hive.registerAdapter(routine_entities.RoutineAdapter());
  Hive.registerAdapter(WaterIntakeAdapter());
  Hive.registerAdapter(WaterLogAdapter());
  Hive.registerAdapter(MoodEntryAdapter());
  Hive.registerAdapter(GratitudeEntryAdapter());
  Hive.registerAdapter(GratitudeItemAdapter());
  Hive.registerAdapter(EntryTypeAdapter());

  // Challenges adapters
  Hive.registerAdapter(challenge_entities.ChallengeAdapter());
  Hive.registerAdapter(challenge_entities.ChallengeCategoryAdapter());
  Hive.registerAdapter(challenge_entities.DailyProgressAdapter());
  Hive.registerAdapter(weekly_goal_entities.WeeklyGoalAdapter());
  Hive.registerAdapter(weekly_goal_entities.GoalTypeAdapter());
  Hive.registerAdapter(badge_entities.BadgeAdapter());
  Hive.registerAdapter(badge_entities.BadgeTierAdapter());
  Hive.registerAdapter(badge_entities.BadgeRequirementTypeAdapter());
  Hive.registerAdapter(user_progress_entities.UserProgressAdapter());

  // Calendar adapters
  Hive.registerAdapter(CalendarEventAdapter());
  Hive.registerAdapter(HiveReminderOffsetAdapter());
  Hive.registerAdapter(EventCategoryAdapter());

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
  final calendarDataSource = CalendarLocalDatasource();

  // Notification service'i başlat
  await NotificationService().initialize();

  // Weekly insight notification — reschedule on every app open.
  // Wrapped in try/catch: failure must never crash startup.
  try {
    final insight = await ComputeWeeklyInsight()();
    final name =
        await const FlutterSecureStorage().read(key: 'user_name') ?? 'there';
    if (insight != null) {
      await NotificationService().scheduleWeeklyInsight(insight, name);
    } else {
      await NotificationService().cancelNotification(9001);
    }
  } catch (e) {
    debugPrint('Weekly insight notification skipped: $e');
  }

  // Check onboarding status
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = !prefs.containsKey('onboarding_completed');

  runApp(
    KoraApp(
      todoDataSource: todoDataSource,
      routinesDataSource: routinesDataSource,
      waterDataSource: waterDataSource,
      moodDataSource: moodDataSource,
      gratitudeDataSource: gratitudeDataSource,
      challengesDataSource: challengesDataSource,
      calendarDataSource: calendarDataSource,
      showOnboarding: showOnboarding,
    ),
  );
}

class KoraApp extends StatelessWidget {
  final TodoLocalDataSource todoDataSource;
  final RoutineLocalDataSource routinesDataSource;
  final WaterLocalDataSource waterDataSource;
  final MoodLocalDataSource moodDataSource;
  final GratitudeLocalDataSource gratitudeDataSource;
  final ChallengesLocalDataSource challengesDataSource;
  final CalendarLocalDatasource calendarDataSource;
  final bool showOnboarding;

  const KoraApp({
    super.key,
    required this.todoDataSource,
    required this.routinesDataSource,
    required this.waterDataSource,
    required this.moodDataSource,
    required this.gratitudeDataSource,
    required this.challengesDataSource,
    required this.calendarDataSource,
    required this.showOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TodoRepositoryImpl>(
          create: (_) => TodoRepositoryImpl(localDataSource: todoDataSource),
        ),
        Provider<routines_repo.RoutineRepositoryImpl>(
          create: (_) =>
              routines_repo.RoutineRepositoryImpl(local: routinesDataSource),
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
            getRoutines: routines_usecases.GetRoutines(
              context.read<routines_repo.RoutineRepositoryImpl>(),
            ),
            addRoutine: routines_usecases.AddRoutine(
              context.read<routines_repo.RoutineRepositoryImpl>(),
            ),
            updateRoutine: routines_usecases.UpdateRoutine(
              context.read<routines_repo.RoutineRepositoryImpl>(),
            ),
            deleteRoutine: routines_usecases.DeleteRoutine(
              context.read<routines_repo.RoutineRepositoryImpl>(),
            ),
          ),
        ),
        ChangeNotifierProvider<WaterProvider>(
          create: (context) => WaterProvider(
            getTodayWaterIntake: water_usecases.GetTodayWaterIntake(
              context.read<WaterRepositoryImpl>(),
            ),
            addWater: water_usecases.AddWater(
              context.read<WaterRepositoryImpl>(),
            ),
            removeLastLog: water_usecases.RemoveLastLog(
              context.read<WaterRepositoryImpl>(),
            ),
            updateWaterIntake: water_usecases.UpdateWaterIntake(
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
            addEntry: gratitude_usecases.AddGratitudeEntry(
              context.read<GratitudeRepositoryImpl>(),
            ),
            getTodayEntry: gratitude_usecases.GetTodayGratitudeEntry(
              context.read<GratitudeRepositoryImpl>(),
            ),
            getAllEntries: gratitude_usecases.GetAllGratitudeEntries(
              context.read<GratitudeRepositoryImpl>(),
            ),
            getRandomPastEntry: gratitude_usecases.GetRandomPastGratitudeEntry(
              context.read<GratitudeRepositoryImpl>(),
            ),
            updateEntry: gratitude_usecases.UpdateGratitudeEntry(
              context.read<GratitudeRepositoryImpl>(),
            ),
            deleteEntry: gratitude_usecases.DeleteGratitudeEntry(
              context.read<GratitudeRepositoryImpl>(),
            ),
            getStreak: gratitude_usecases.GetGratitudeStreak(
              context.read<GratitudeRepositoryImpl>(),
            ),
            getEmotionTagStats: gratitude_usecases.GetEmotionTagStats(
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
        // Calendar Provider
        ChangeNotifierProvider<CalendarProvider>(
          create: (_) => CalendarProvider(
            datasource: calendarDataSource,
            notificationService: NotificationService(),
          ),
        ),
        // Timer Provider
        ChangeNotifierProvider<TimerProvider>(create: (_) => TimerProvider()),
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
