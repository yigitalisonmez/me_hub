import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/app_route.dart';
import '../../../../core/services/cumulative_stats_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../../settings/presentation/pages/settings_page.dart';

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
          child: _ProfileRedesign(
            userName: _userName,
            tasksCompleted: _allTimeTasksCompleted,
            maxStreak: _maxStreak,
            totalWaterMl: _allTimeWaterMl,
            themeProvider: themeProvider,
            onSettingsTap: () => _navigateToSettings(context),
            onEditTap: () => _showEditProfileDialog(context),
            onDarkModeChanged: (value) => themeProvider.setTheme(value),
            onHelpTap: () => _showHelpDialog(context),
            bottomClearance: LayoutConstants.getNavbarClearance(context),
          ),
        ),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      AppRoute(page: const SettingsPage()),
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

class _ProfileRedesign extends StatelessWidget {
  final String userName;
  final int tasksCompleted;
  final int maxStreak;
  final int totalWaterMl;
  final ThemeProvider themeProvider;
  final VoidCallback onSettingsTap;
  final VoidCallback onEditTap;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onHelpTap;
  final double bottomClearance;

  const _ProfileRedesign({
    required this.userName,
    required this.tasksCompleted,
    required this.maxStreak,
    required this.totalWaterMl,
    required this.themeProvider,
    required this.onSettingsTap,
    required this.onEditTap,
    required this.onDarkModeChanged,
    required this.onHelpTap,
    required this.bottomClearance,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = userName.trim().isEmpty ? 'User' : userName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHero(
          userName: displayName,
          themeProvider: themeProvider,
          onSettingsTap: onSettingsTap,
          onEditTap: onEditTap,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ProfileStatCard(
                      icon: LucideIcons.check,
                      value: '$tasksCompleted',
                      label: 'Tasks done',
                      color: AppColors.primary,
                      tint: AppColors.terraTint,
                      themeProvider: themeProvider,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProfileStatCard(
                      icon: LucideIcons.flame,
                      value: '$maxStreak',
                      label: 'Day streak',
                      color: AppColors.mood,
                      tint: AppColors.moodTint,
                      themeProvider: themeProvider,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProfileStatCard(
                      icon: LucideIcons.droplet,
                      value: '${(totalWaterMl / 1000).toStringAsFixed(1)}L',
                      label: 'Water',
                      color: AppColors.water,
                      tint: AppColors.waterTint,
                      themeProvider: themeProvider,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ProfileInsightCard(
                completionRate: _routineCompletionEstimate(),
                themeProvider: themeProvider,
              ),
              const SizedBox(height: 22),
              _SettingsGroupLabel('Preferences', themeProvider: themeProvider),
              const SizedBox(height: 10),
              _SettingsCard(
                themeProvider: themeProvider,
                rows: [
                  _ProfileSettingRow(
                    icon: LucideIcons.moon,
                    label: 'Dark mode',
                    color: AppColors.mindful,
                    themeProvider: themeProvider,
                    trailing: Switch.adaptive(
                      value: themeProvider.isDarkMode,
                      onChanged: onDarkModeChanged,
                      activeColor: AppColors.primary,
                    ),
                  ),
                  _ProfileSettingRow(
                    icon: LucideIcons.bell,
                    label: 'Reminders',
                    value: 'On',
                    color: AppColors.mood,
                    themeProvider: themeProvider,
                    onTap: onSettingsTap,
                  ),
                  _ProfileSettingRow(
                    icon: LucideIcons.droplet,
                    label: 'Water goal',
                    value: '8 glasses',
                    color: AppColors.water,
                    themeProvider: themeProvider,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _SettingsGroupLabel('General', themeProvider: themeProvider),
              const SizedBox(height: 10),
              _SettingsCard(
                themeProvider: themeProvider,
                rows: [
                  _ProfileSettingRow(
                    icon: LucideIcons.heart,
                    label: 'Health sync',
                    value: 'Local',
                    color: AppColors.primary,
                    themeProvider: themeProvider,
                  ),
                  _ProfileSettingRow(
                    icon: LucideIcons.bookmark,
                    label: 'Privacy',
                    color: AppColors.routine,
                    themeProvider: themeProvider,
                    onTap: onSettingsTap,
                  ),
                  _ProfileSettingRow(
                    icon: LucideIcons.lightbulb,
                    label: 'Help & feedback',
                    color: AppColors.mood,
                    themeProvider: themeProvider,
                    onTap: onHelpTap,
                  ),
                ],
              ),
              SizedBox(height: bottomClearance),
            ],
          ),
        ),
      ],
    );
  }

  int _routineCompletionEstimate() {
    if (tasksCompleted <= 0 && maxStreak <= 0) return 0;
    final score = 55 + maxStreak.clamp(0, 30);
    return score.clamp(55, 92);
  }
}

class _ProfileHero extends StatelessWidget {
  final String userName;
  final ThemeProvider themeProvider;
  final VoidCallback onSettingsTap;
  final VoidCallback onEditTap;

  const _ProfileHero({
    required this.userName,
    required this.themeProvider,
    required this.onSettingsTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 310,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/mesh-gradient.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    themeProvider.backgroundColor.withValues(alpha: 0.92),
                  ],
                  stops: const [0.08, 0.94],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  GestureDetector(
                    onTap: onSettingsTap,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.24),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.32),
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.settings,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.moodTint,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: themeProvider.cardColor,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/mood_circle.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: themeProvider.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                Text(
                  'With Kora on this device',
                  style: TextStyle(
                    color: themeProvider.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onEditTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: themeProvider.isDarkMode
                            ? Colors.white.withValues(alpha: 0.07)
                            : AppColors.textPrimary.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.pencil,
                          color: themeProvider.primaryColor,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Edit profile',
                          style: TextStyle(
                            color: themeProvider.primaryColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color tint;
  final ThemeProvider themeProvider;

  const _ProfileStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.tint,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTint = themeProvider.isDarkMode
        ? Color.alphaBlend(color.withValues(alpha: 0.14), AppColors.darkCard)
        : tint;

    return ElevatedCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      borderRadius: 22,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: effectiveTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProfileInsightCard extends StatelessWidget {
  final int completionRate;
  final ThemeProvider themeProvider;

  const _ProfileInsightCard({
    required this.completionRate,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final bg = themeProvider.isDarkMode
        ? Color.alphaBlend(
            AppColors.routine.withValues(alpha: 0.16),
            AppColors.darkCard,
          )
        : AppColors.routineTint;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.routine.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/analytics.png',
            width: 82,
            height: 82,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completionRate == 0
                      ? 'Your rhythm starts here'
                      : 'Your best week yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: themeProvider.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  completionRate == 0
                      ? 'Complete a few routines and Kora will surface your weekly insight.'
                      : 'You completed $completionRate% of your core rhythm signals.',
                  style: TextStyle(
                    color: themeProvider.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Text(
                      'See full report',
                      style: TextStyle(
                        color: AppColors.routineDeep,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      LucideIcons.arrowRight,
                      color: AppColors.routineDeep,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroupLabel extends StatelessWidget {
  final String label;
  final ThemeProvider themeProvider;

  const _SettingsGroupLabel(this.label, {required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: themeProvider.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final ThemeProvider themeProvider;
  final List<_ProfileSettingRow> rows;

  const _SettingsCard({required this.themeProvider, required this.rows});

  @override
  Widget build(BuildContext context) {
    return ElevatedCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      borderRadius: 24,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Divider(
                indent: 54,
                height: 1,
                color: themeProvider.isDarkMode
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.textPrimary.withValues(alpha: 0.07),
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileSettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color color;
  final ThemeProvider themeProvider;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ProfileSettingRow({
    required this.icon,
    required this.label,
    this.value,
    required this.color,
    required this.themeProvider,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: themeProvider.isDarkMode ? 0.18 : 0.13,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: themeProvider.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing ??
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (value != null && value!.isNotEmpty)
                      Text(
                        value!,
                        style: TextStyle(
                          color: themeProvider.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(width: 6),
                    Icon(
                      LucideIcons.chevronRight,
                      color: themeProvider.textTertiary,
                      size: 16,
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
