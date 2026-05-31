import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/services/quote_cache_service.dart';
import '../../../../core/services/quote_service.dart';
import '../../../../core/widgets/glass_container.dart';

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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: PageHeader(
                title: _userName.isNotEmpty
                    ? '${_getGreeting()}, $_userName'
                    : _getGreeting(),
                subtitle: 'Welcome to your home',
                centerTitle: false,
                actionWidget: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    return RotationTransition(
                      turns: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Icon(
                    themeProvider.isDarkMode
                        ? LucideIcons.sun
                        : LucideIcons.moon,
                    key: ValueKey(themeProvider.isDarkMode),
                    color: themeProvider.primaryColor,
                    size: 20,
                  ),
                ),
                onActionTap: () => themeProvider.toggleTheme(),
              ),
            ),
            const SizedBox(height: 16),

            // Hero Card with 3D character and quote
            _buildHeroCard(themeProvider),
            const SizedBox(height: 24),

            // Daily Progress Section
            const DailyProgressSection(),
            const SizedBox(height: 24),

            // Productivity Section
            ProductivitySection(
              onTasksTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TodoPage()),
              ),
              onRoutinesTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoutinesPage()),
              ),
              onPomodoroTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TimerPage()),
              ),
              onGoalsTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChallengesPage()),
              ),
              onCalendarTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarPage()),
              ),
            ),
            const SizedBox(height: 20),

            // Wellness Section
            WellnessSection(
              onWaterTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WaterPage()),
              ),
              onMoodTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MoodPage()),
              ),
            ),
            const SizedBox(height: 20),

            // Mindfulness Section
            MindfulnessSection(
              onAffirmationsTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AffirmationsPage()),
              ),
              onBreathingTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BreathingPage()),
              ),
              onGratitudeTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GratitudePage()),
              ),
            ),
            const SizedBox(height: 24),

            // Gamification Section
            GamificationSection(
              onChallengesTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChallengesPage()),
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
              padding: const EdgeInsets.all(16),
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
                      maxLines: 3,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
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
