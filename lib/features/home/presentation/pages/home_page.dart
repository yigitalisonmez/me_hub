import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/app_route.dart';
import '../../../../core/services/quote_cache_service.dart';
import '../../../../core/services/quote_service.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../todo/presentation/providers/todo_provider.dart';
import '../../../todo/presentation/pages/todo_page.dart';
import '../../../water/presentation/providers/water_provider.dart';
import '../../../mood_tracker/presentation/providers/mood_provider.dart';
import '../../../routines/presentation/providers/routines_provider.dart';
import '../../../routines/presentation/pages/routines_page.dart';
import '../../../mood_tracker/presentation/pages/mood_page.dart';
import '../../../timer/presentation/pages/timer_page.dart';
import '../../../affirmations/presentation/pages/affirmations_page.dart';
import '../../../breathing/presentation/pages/breathing_page.dart';
import '../../../gratitude/presentation/pages/gratitude_page.dart';
import '../../../challenges/presentation/pages/challenges_page.dart';
import '../../../water/presentation/pages/water_page.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';

// Use existing dashboard widgets from todo feature
import '../../../todo/presentation/widgets/dashboard_widgets.dart';

/// Home page - Dashboard with daily overview and quick actions
class HomePage extends StatefulWidget {
  final void Function(int)? onNavigateToPage;

  const HomePage({super.key, this.onNavigateToPage});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Quote? _quote;
  bool _isLoadingQuote = true;
  bool _dataLoaded = false;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadQuote();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    // Securely read user name
    const secureStorage = FlutterSecureStorage();
    final userName = await secureStorage.read(key: 'user_name');

    if (mounted) {
      setState(() {
        _userName = userName ?? '';
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoaded) {
      _dataLoaded = true;
      // Defer loading to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAllData();
      });
    }
  }

  void _loadAllData() {
    context.read<TodoProvider>().loadTodayTodos();
    context.read<WaterProvider>().loadTodayWaterIntake();
    context.read<MoodProvider>().loadTodayMood();
    context.read<RoutinesProvider>().loadRoutines();
    context.read<CalendarProvider>().loadEvents();
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: _buildHomeHeader(themeProvider),
            ),
            const SizedBox(height: 12),

            _buildRhythmStrip(themeProvider),
            const SizedBox(height: 14),

            _buildHeroCard(themeProvider),
            const SizedBox(height: 22),

            // Daily Progress Section
            const DailyProgressSection(),
            const SizedBox(height: 18),

            _buildQuoteCard(themeProvider),
            const SizedBox(height: 24),

            ExploreSection(
              onTasksTap: () => Navigator.push(
                context,
                AppRoute(page: const TodoPage()),
              ),
              onRoutinesTap: () => Navigator.push(
                context,
                AppRoute(page: const RoutinesPage()),
              ),
              onPomodoroTap: () => Navigator.push(
                context,
                AppRoute(page: const TimerPage()),
              ),
              onGoalsTap: () => Navigator.push(
                context,
                AppRoute(page: const ChallengesPage()),
              ),
              onCalendarTap: () => Navigator.push(
                context,
                AppRoute(page: const CalendarPage()),
              ),
              onWaterTap: () => Navigator.push(
                context,
                AppRoute(page: const WaterPage()),
              ),
              onMoodTap: () => Navigator.push(
                context,
                AppRoute(page: const MoodPage()),
              ),
              onAffirmationsTap: () => Navigator.push(
                context,
                AppRoute(page: const AffirmationsPage()),
              ),
              onBreathingTap: () => Navigator.push(
                context,
                AppRoute(page: const BreathingPage()),
              ),
              onGratitudeTap: () => Navigator.push(
                context,
                AppRoute(page: const GratitudePage()),
              ),
            ),
            const SizedBox(height: 24),

            // Daily Tip Card
            const InsightsCard(),

            SizedBox(height: LayoutConstants.getNavbarClearance(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeHeader(ThemeProvider themeProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.sun, color: AppColors.mood, size: 16),
                  const SizedBox(width: 7),
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      color: themeProvider.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _userName.isNotEmpty ? _userName : 'Kora',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: themeProvider.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => themeProvider.toggleTheme(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            width: 58,
            height: 32,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: themeProvider.surfaceColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: themeProvider.isDarkMode
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.textPrimary.withValues(alpha: 0.08),
              ),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  alignment: themeProvider.isDarkMode
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: themeProvider.cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Icon(
                      LucideIcons.sun,
                      size: 13,
                      color: AppColors.mood,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Icon(
                      LucideIcons.moon,
                      size: 13,
                      color: themeProvider.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.moodTint,
            shape: BoxShape.circle,
            border: Border.all(color: themeProvider.cardColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/mood_circle.png',
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _buildRhythmStrip(ThemeProvider themeProvider) {
    final todo = context.watch<TodoProvider>();
    final water = context.watch<WaterProvider>();
    final mood = context.watch<MoodProvider>();
    final routineProgress = _todayRoutineProgress();
    final signals = [
      todo.completionRate > 0,
      water.todayProgress > 0.2,
      mood.hasTodayMood,
      routineProgress > 0,
    ];
    final activeCount = signals.where((isActive) => isActive).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: themeProvider.isDarkMode
                ? Colors.white.withValues(alpha: 0.07)
                : AppColors.textPrimary.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.flame, color: AppColors.moodDeep, size: 16),
            const SizedBox(width: 7),
            Text(
              '$activeCount/4 daily anchors active',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            ...signals.map(
              (isActive) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.mood
                      : themeProvider.textTertiary.withValues(alpha: 0.28),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeProvider themeProvider) {
    final progress = _todayOverallProgress();
    final percent = (progress * 100).round();
    final todo = context.watch<TodoProvider>();

    return Container(
      height: 154,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.3),
            blurRadius: 28,
            offset: const Offset(0, 16),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -46,
            top: -58,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 18,
            bottom: 18,
            width: 205,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _todayLabel(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "You're $percent% through your day",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.26),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${todo.incompleteCount} tasks left · keep the rhythm',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Positioned(
            right: -14,
            bottom: -17,
            child: Image.asset(
              'assets/images/home_page_character.png',
              width: 150,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                LucideIcons.sparkles,
                color: themeProvider.primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _isLoadingQuote
                  ? Text(
                      'Loading daily intention...',
                      style: TextStyle(
                        color: themeProvider.textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _quote?.text ??
                              'Small steps every day add up to big change.',
                          style: TextStyle(
                            color: themeProvider.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.bookOpen,
                              color: themeProvider.textTertiary,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _quote?.author ?? 'Daily intention',
                                style: TextStyle(
                                  color: themeProvider.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _todayOverallProgress() {
    final todo = context.watch<TodoProvider>();
    final water = context.watch<WaterProvider>();
    final mood = context.watch<MoodProvider>();
    final routineProgress = _todayRoutineProgress();
    final moodProgress = mood.hasTodayMood ? 1.0 : 0.0;

    return ((todo.completionRate +
                water.todayProgress +
                moodProgress +
                routineProgress) /
            4)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _todayRoutineProgress() {
    final routinesProvider = context.watch<RoutinesProvider>();
    final weekday = DateTime.now().weekday - 1;
    final activeRoutines = routinesProvider.getActiveRoutinesForDay(weekday);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    var totalItems = 0;
    var completedItems = 0;
    for (final routine in activeRoutines) {
      totalItems += routine.items.length;
      completedItems += routine.items
          .where((i) => i.isCheckedToday(todayDate))
          .length;
    }

    return totalItems > 0 ? completedItems / totalItems : 0.0;
  }

  String _todayLabel() {
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final now = DateTime.now();
    return 'TODAY · ${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 21 || hour < 3) {
      return 'Good Night';
    } else if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}
