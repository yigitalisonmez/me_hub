import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/cumulative_stats_service.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../widgets/profile_widgets.dart';

/// Profile page with user info, stats, achievements, and settings
class ProfilePage extends StatefulWidget {
  final void Function(int)? onNavigateToPage;

  const ProfilePage({super.key, this.onNavigateToPage});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  String _userName = '';
  int _allTimeTasksCompleted = 0;
  int _allTimeWaterMl = 0;
  int _maxStreak = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAllTimeStats();
  }

  Future<void> _loadUserData() async {
    const secureStorage = FlutterSecureStorage();
    final userName = await secureStorage.read(key: 'user_name');

    if (mounted) {
      setState(() {
        _userName = userName ?? 'User';
      });
    }
  }

  Future<void> _loadAllTimeStats() async {
    // Ensure stats are initialized/migrated from existing data
    await CumulativeStatsService.initializeIfNeeded();

    // Load from SharedPreferences (reliable persistent storage)
    final waterMl = await CumulativeStatsService.getAllTimeWaterMl();
    final tasksCompleted =
        await CumulativeStatsService.getAllTimeTasksCompleted();
    final maxStreak = await CumulativeStatsService.getMaxStreak();

    if (mounted) {
      setState(() {
        _allTimeWaterMl = waterMl;
        _allTimeTasksCompleted = tasksCompleted;
        _maxStreak = maxStreak;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload stats when dependencies change (e.g. after adding water/completing tasks)
    _loadAllTimeStats();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = context.watch<ThemeProvider>();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              ProfileHeroSection(
                onSettingsTap: () => _navigateToSettings(context),
                child: ProfileCard(
                  userName: _userName,
                  profileLabel: 'Local profile',
                  totalTasksCompleted: _allTimeTasksCompleted,
                  maxStreak: _maxStreak,
                  totalWaterMl: _allTimeWaterMl,
                  onEditTap: () => _showEditProfileDialog(context),
                  themeProvider: themeProvider,
                ),
              ),

              // Content below hero
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Streak banner
                    StreakBanner(
                      streakDays: _maxStreak,
                      themeProvider: themeProvider,
                    ),
                    const SizedBox(height: 24),

                    // Achievements carousel
                    AchievementsCarousel(themeProvider: themeProvider),
                    const SizedBox(height: 24),

                    // Settings menu
                    SettingsMenuSection(
                      themeProvider: themeProvider,
                      isDarkMode: themeProvider.isDarkMode,
                      onDarkModeChanged: (value) =>
                          themeProvider.setTheme(value),
                      onVoiceCommandsTap: () => _navigateToSettings(context),
                      onHelpTap: () => _showHelpDialog(context),
                    ),

                    SizedBox(
                      height: LayoutConstants.getNavbarClearance(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final nameController = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Profile',
          style: TextStyle(color: themeProvider.textPrimary),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            labelStyle: TextStyle(color: themeProvider.textSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          style: TextStyle(color: themeProvider.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeProvider.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              const secureStorage = FlutterSecureStorage();
              await secureStorage.write(
                key: 'user_name',
                value: nameController.text,
              );
              if (!mounted || !context.mounted) return;
              setState(() {
                _userName = nameController.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'About Kora',
          style: TextStyle(color: themeProvider.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kora keeps your profile and progress on this device.',
              style: TextStyle(color: themeProvider.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              'Cloud accounts, export, and support channels will be added only when they are fully ready.',
              style: TextStyle(color: themeProvider.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: themeProvider.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
