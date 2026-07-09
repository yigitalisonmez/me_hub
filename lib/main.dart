import 'dart:convert';

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
import 'features/home/presentation/widgets/quick_log_sheet.dart';
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
import 'features/water/data/services/daily_goal_service.dart';
import 'features/water/domain/usecases/usecases.dart' as water_usecases;
import 'features/water/domain/entities/water_intake.dart';
import 'core/services/notification_service.dart';
import 'core/utils/result.dart';
import 'core/reminders/data/reminder_preferences_repository.dart';
import 'core/reminders/domain/reminder_feature.dart';
import 'core/reminders/presentation/reminder_settings_provider.dart';
import 'core/reminders/services/reminder_coordinator.dart';
import 'core/reminders/services/reminder_id_registry.dart';
import 'features/analytics/domain/usecases/compute_weekly_insight.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/timer/presentation/providers/timer_provider.dart';
import 'features/timer/presentation/pages/timer_page.dart';

import 'features/profile/presentation/pages/profile_page.dart';
import 'core/widgets/voice_command_sheet.dart';
import 'core/providers/voice_settings_provider.dart';
import 'core/widgets/glass_nav_bar.dart';
import 'core/utils/app_route.dart';
import 'features/affirmations/presentation/providers/affirmation_provider.dart';
import 'features/affirmations/presentation/pages/affirmations_page.dart';
import 'features/breathing/presentation/providers/breathing_provider.dart';
import 'features/breathing/presentation/pages/breathing_page.dart';
import 'features/gratitude/domain/entities/gratitude_entry.dart';
import 'features/gratitude/domain/entities/gratitude_item.dart';
import 'features/gratitude/data/datasources/gratitude_local_datasource.dart';
import 'features/gratitude/data/repositories/gratitude_repository_impl.dart';
import 'features/gratitude/domain/usecases/usecases.dart' as gratitude_usecases;
import 'features/gratitude/presentation/providers/gratitude_provider.dart';
import 'features/gratitude/presentation/pages/gratitude_page.dart';
import 'features/todo/presentation/pages/todo_page.dart';
import 'features/water/presentation/pages/water_page.dart';
import 'features/mood_tracker/presentation/pages/mood_page.dart';
import 'features/routines/presentation/pages/routines_page.dart';
import 'features/routines/presentation/pages/guided_routine_flow_page.dart';
import 'features/challenges/presentation/pages/challenges_page.dart';
import 'features/calendar/presentation/pages/calendar_page.dart';

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
  final notificationService = NotificationService();
  await notificationService.initialize();
  final reminderCoordinator = ReminderCoordinator(
    notifications: notificationService,
    preferencesRepository: await ReminderPreferencesRepository.create(),
    idRegistry: await ReminderIdRegistry.create(),
  );
  final routines = await routinesDataSource.getRoutines();
  final calendarEvents = await calendarDataSource.getAllEvents();
  await reminderCoordinator.initialize(
    hasLegacyReminders:
        routines.any(
          (routine) => routine.time != null && routine.reminderEnabled,
        ) ||
        calendarEvents.any((event) => event.hasReminder && !event.isPast),
  );
  await reminderCoordinator.reconcileRoutines(routines);
  await reminderCoordinator.reconcileCalendarEvents(calendarEvents);

  final todayWater = await waterDataSource.getWaterIntake(DateTime.now());
  final savedWaterGoal = await DailyGoalService.getDailyGoal();
  await reminderCoordinator.reconcileWater(
    goalReached: (todayWater?.amountMl ?? 0) >= savedWaterGoal,
  );
  await reminderCoordinator.reconcileDailyFeature(
    feature: ReminderFeature.mood,
    completedToday: await moodDataSource.getTodayMood() != null,
    actionable: true,
    title: 'How are you feeling?',
    body: 'Take a quiet moment to check in with yourself.',
    payload: 'kora://mood',
  );
  final morningGratitude = await gratitudeDataSource.getEntryByDateAndType(
    DateTime.now(),
    EntryType.morning,
  );
  final eveningGratitude = await gratitudeDataSource.getEntryByDateAndType(
    DateTime.now(),
    EntryType.evening,
  );
  await reminderCoordinator.reconcileDailyFeature(
    feature: ReminderFeature.gratitudeMorning,
    completedToday: morningGratitude?.isComplete ?? false,
    actionable: true,
    title: 'Morning gratitude',
    body: 'Begin today by naming three things you appreciate.',
    payload: 'kora://gratitude',
  );
  await reminderCoordinator.reconcileDailyFeature(
    feature: ReminderFeature.gratitudeEvening,
    completedToday: eveningGratitude?.isComplete ?? false,
    actionable: true,
    title: 'Evening gratitude',
    body: 'Close the day with a short reflection.',
    payload: 'kora://gratitude',
  );
  final todayTodosResult = await todoDataSource.getTodayTodos();
  final todayTodos = todayTodosResult.data ?? const <DailyTodo>[];
  await reminderCoordinator.reconcileDailyFeature(
    feature: ReminderFeature.todo,
    completedToday:
        todayTodos.isNotEmpty && todayTodos.every((todo) => todo.isCompleted),
    actionable: todayTodos.any((todo) => !todo.isCompleted),
    title: 'Tasks for today',
    body: 'A quick review can help you close the day with less on your mind.',
    payload: 'kora://todo',
  );

  final startupPrefs = await SharedPreferences.getInstance();
  await reminderCoordinator.reconcileDailyFeature(
    feature: ReminderFeature.breathing,
    completedToday: _historyHasCompletionToday(
      startupPrefs.getString('breathing_session_history'),
    ),
    actionable: true,
    title: 'A moment to breathe',
    body: 'A short breathing session can reset the pace of your day.',
    payload: 'kora://breathing',
  );
  await reminderCoordinator.reconcileDailyFeature(
    feature: ReminderFeature.affirmations,
    completedToday: _historyHasCompletionToday(
      startupPrefs.getString('affirmation_session_history'),
    ),
    actionable: true,
    title: 'Your affirmation practice',
    body: 'Take a few minutes for the words you want to carry today.',
    payload: 'kora://affirmations',
  );

  final startupChallengesRepository = ChallengesRepositoryImpl(
    challengesDataSource,
  );
  final activeChallenges = await startupChallengesRepository
      .getActiveChallenges();
  final weeklyGoals = await startupChallengesRepository.getCurrentWeekGoals();
  final now = DateTime.now();
  final challengeActionable =
      activeChallenges.any((challenge) => !challenge.isCompleted) ||
      weeklyGoals.any((goal) => !goal.isCompleted);
  final challengesCompletedToday =
      challengeActionable &&
      activeChallenges
          .where((challenge) => !challenge.isCompleted)
          .every((challenge) => challenge.isTodayCompleted(now)) &&
      weeklyGoals
          .where((goal) => !goal.isCompleted)
          .every((goal) => goal.isTodayCompleted(now));
  await reminderCoordinator.reconcileDailyFeature(
    feature: ReminderFeature.challenges,
    completedToday: challengesCompletedToday,
    actionable: challengeActionable,
    title: 'Today’s challenge check-in',
    body: 'Mark today’s progress while it is still fresh.',
    payload: 'kora://challenges',
  );

  // Weekly insight notification — reschedule on every app open.
  // Wrapped in try/catch: failure must never crash startup.
  try {
    final insight = await ComputeWeeklyInsight()();
    final name =
        await const FlutterSecureStorage().read(key: 'user_name') ?? 'there';
    if (insight != null) {
      await reminderCoordinator.reconcileWeeklyInsight(
        insight: insight,
        userName: name,
      );
    } else {
      await reminderCoordinator.reconcileWeeklyInsight(
        insight: null,
        userName: name,
      );
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
      reminderCoordinator: reminderCoordinator,
      notificationService: notificationService,
      preferences: prefs,
      showOnboarding: showOnboarding,
    ),
  );
  _configureNotificationNavigation(
    notificationService,
    enabled: !showOnboarding,
  );
}

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<_MainScreenState> _mainScreenKey =
    GlobalKey<_MainScreenState>();

class KoraApp extends StatelessWidget {
  final TodoLocalDataSource todoDataSource;
  final RoutineLocalDataSource routinesDataSource;
  final WaterLocalDataSource waterDataSource;
  final MoodLocalDataSource moodDataSource;
  final GratitudeLocalDataSource gratitudeDataSource;
  final ChallengesLocalDataSource challengesDataSource;
  final CalendarLocalDatasource calendarDataSource;
  final ReminderCoordinator reminderCoordinator;
  final NotificationService notificationService;
  final SharedPreferences preferences;
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
    required this.reminderCoordinator,
    required this.notificationService,
    required this.preferences,
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
            reminders: reminderCoordinator,
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
            reminders: reminderCoordinator,
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
            reminders: reminderCoordinator,
          ),
        ),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<MoodProvider>(
          create: (_) =>
              MoodProvider(moodDataSource, reminders: reminderCoordinator),
        ),
        ChangeNotifierProvider<VoiceSettingsProvider>(
          create: (_) => VoiceSettingsProvider(),
        ),
        ChangeNotifierProvider<AffirmationProvider>(
          create: (_) => AffirmationProvider(reminders: reminderCoordinator),
        ),
        ChangeNotifierProvider<BreathingProvider>(
          create: (_) => BreathingProvider(reminders: reminderCoordinator),
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
            reminders: reminderCoordinator,
          ),
        ),
        // Challenges Provider
        Provider<ChallengesRepositoryImpl>(
          create: (_) => ChallengesRepositoryImpl(challengesDataSource),
        ),
        ChangeNotifierProvider<ChallengesProvider>(
          create: (context) => ChallengesProvider(
            context.read<ChallengesRepositoryImpl>(),
            reminders: reminderCoordinator,
          ),
        ),
        // Calendar Provider
        ChangeNotifierProvider<CalendarProvider>(
          create: (_) => CalendarProvider(
            datasource: calendarDataSource,
            notificationService: NotificationService(),
            reminders: reminderCoordinator,
          ),
        ),
        Provider<ReminderCoordinator>.value(value: reminderCoordinator),
        ChangeNotifierProvider<ReminderSettingsProvider>(
          create: (_) => ReminderSettingsProvider(reminderCoordinator),
        ),
        // Timer Provider
        ChangeNotifierProvider<TimerProvider>(
          lazy: false,
          create: (_) => TimerProvider(
            notifications: notificationService,
            preferences: preferences,
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
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
            home: showOnboarding
                ? const OnboardingPage()
                : MainScreen(key: _mainScreenKey),
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
      final reminderCoordinator = context.read<ReminderCoordinator>();
      await routinesProvider.loadRoutines();
      final routines = routinesProvider.routines;
      if (routines.isNotEmpty) {
        await reminderCoordinator.reconcileRoutines(routines);
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

  void showHome() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
            _buildQuickLogButton(),
          ],
        ),
        // FAB removed - mic is now in navbar
      ),
    );
  }

  /// Floating "+ Quick log" pill above the navbar, Home tab only.
  Widget _buildQuickLogButton() {
    final themeProvider = context.watch<ThemeProvider>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      right: 18,
      bottom: bottomPadding + 12 + 74 + 12,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        offset: _currentIndex == 0 ? Offset.zero : const Offset(0, 0.4),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 240),
          opacity: _currentIndex == 0 ? 1 : 0,
          child: IgnorePointer(
            ignoring: _currentIndex != 0,
            child: GestureDetector(
              onTap: () => showQuickLogSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 19),
                    SizedBox(width: 5),
                    Text(
                      'Quick log',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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

bool _historyHasCompletionToday(String? rawJson) {
  if (rawJson == null || rawJson.isEmpty) return false;
  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List) return false;
    final now = DateTime.now();
    return decoded.whereType<Map>().any((entry) {
      final value = entry['completedAt'];
      if (value is! String) return false;
      final completedAt = DateTime.tryParse(value);
      return completedAt != null &&
          completedAt.year == now.year &&
          completedAt.month == now.month &&
          completedAt.day == now.day;
    });
  } catch (_) {
    return false;
  }
}

void _configureNotificationNavigation(
  NotificationService notifications, {
  required bool enabled,
}) {
  if (!enabled) return;
  notifications.payloads.listen(_openNotificationPayload);
  final pending = notifications.takePendingPayload();
  if (pending != null) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _openNotificationPayload(pending),
    );
  }
}

void _openNotificationPayload(String payload) {
  final navigator = _navigatorKey.currentState;
  final context = _navigatorKey.currentContext;
  if (navigator == null || context == null) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _openNotificationPayload(payload),
    );
    return;
  }

  Widget? page;
  if (payload == 'kora://home') {
    navigator.popUntil((route) => route.isFirst);
    _mainScreenKey.currentState?.showHome();
    return;
  } else if (payload == 'kora://todo') {
    page = const TodoPage();
  } else if (payload == 'kora://water') {
    page = const WaterPage();
  } else if (payload == 'kora://mood') {
    page = const MoodPage();
  } else if (payload == 'kora://gratitude') {
    page = const GratitudePage();
  } else if (payload == 'kora://breathing') {
    page = const BreathingPage();
  } else if (payload == 'kora://affirmations') {
    page = const AffirmationsPage();
  } else if (payload == 'kora://challenges') {
    page = const ChallengesPage(initialTab: 1);
  } else if (payload == 'kora://timer') {
    page = const TimerPage();
  } else if (payload.startsWith('kora://routine/')) {
    final id = payload.substring('kora://routine/'.length);
    final routine = context.read<RoutinesProvider>().getRoutineById(id);
    page = routine == null
        ? const RoutinesPage()
        : GuidedRoutineFlowPage(routineId: routine.id);
  } else if (payload.startsWith('kora://calendar')) {
    page = const CalendarPage();
  }

  if (page != null) navigator.push(AppRoute(page: page));
}
