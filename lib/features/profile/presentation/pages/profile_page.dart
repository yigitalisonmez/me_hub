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
  String _userEmail = '';
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
    final userEmail = await secureStorage.read(key: 'user_email');

    if (mounted) {
      setState(() {
        _userName = userName ?? 'User';
        _userEmail = userEmail ?? 'user@example.com';
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
                  userEmail: _userEmail,
                  isPremium: true, // TODO: Check actual premium status
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
                      onNotificationsTap: () => _navigateToSettings(context),
                      onVoiceCommandsTap: () => _navigateToSettings(context),
                      onExportDataTap: () => _showExportDialog(context),
                      onHelpTap: () => _showHelpDialog(context),
                      onSignOutTap: () => _showSignOutDialog(context),
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
              if (mounted) {
                setState(() {
                  _userName = nameController.text;
                });
                Navigator.pop(context);
              }
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

  void _showExportDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Export Data',
          style: TextStyle(color: themeProvider.textPrimary),
        ),
        content: Text(
          'Export your data for backup or analysis. This feature is coming soon!',
          style: TextStyle(color: themeProvider.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: themeProvider.primaryColor),
            ),
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
          'Help & Support',
          style: TextStyle(color: themeProvider.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need help? Contact us:',
              style: TextStyle(color: themeProvider.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              '📧 support@mehub.app',
              style: TextStyle(color: themeProvider.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              '🌐 www.mehub.app/help',
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

  void _showSignOutDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: TextStyle(color: themeProvider.textPrimary),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: themeProvider.textSecondary),
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
            onPressed: () {
              // TODO: Implement actual sign out logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Sign out functionality coming soon!'),
                  backgroundColor: themeProvider.primaryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
