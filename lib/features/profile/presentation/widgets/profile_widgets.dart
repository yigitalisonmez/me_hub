import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/elevated_card.dart';

/// Hero section with gradient background and settings button
class ProfileHeroSection extends StatelessWidget {
  final VoidCallback? onSettingsTap;
  final Widget child;

  const ProfileHeroSection({
    super.key,
    this.onSettingsTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeProvider.primaryColor,
            themeProvider.primaryColor.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            children: [
              // Header row with title and settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  _SettingsButton(onTap: onSettingsTap),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple settings button without heavy blur
class _SettingsButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _SettingsButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: const Icon(LucideIcons.settings, color: Colors.white, size: 20),
      ),
    );
  }
}

/// Profile card with avatar and stats - using ElevatedCard pattern
class ProfileCard extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? avatarInitials;
  final bool isPremium;
  final int totalTasksCompleted;
  final int maxStreak;
  final int totalWaterMl;
  final VoidCallback? onEditTap;
  final ThemeProvider themeProvider;

  const ProfileCard({
    super.key,
    required this.userName,
    required this.userEmail,
    this.avatarInitials,
    this.isPremium = false,
    required this.totalTasksCompleted,
    required this.maxStreak,
    required this.totalWaterMl,
    this.onEditTap,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        children: [
          // Profile header row
          Row(
            children: [
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeProvider.primaryColor,
                          themeProvider.primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.primaryColor.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        avatarInitials ??
                            (userName.isNotEmpty
                                ? userName.substring(0, 2).toUpperCase()
                                : 'U'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Edit button
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: onEditTap,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: themeProvider.surfaceColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.pencil,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 13,
                        color: themeProvider.textSecondary,
                      ),
                    ),
                    if (isPremium) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('✨ ', style: TextStyle(fontSize: 10)),
                            Text(
                              'PREMIUM',
                              style: TextStyle(
                                color: themeProvider.primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats row - 3 total stats
          Row(
            children: [
              _MiniStat(
                value: '$totalTasksCompleted',
                label: 'Tasks Done',
                themeProvider: themeProvider,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                value: '$maxStreak',
                label: 'Max Streak',
                themeProvider: themeProvider,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                value: '${(totalWaterMl / 1000).toStringAsFixed(1)}L',
                label: 'Water Drinked',
                themeProvider: themeProvider,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final ThemeProvider themeProvider;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : themeProvider.backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: themeProvider.primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: themeProvider.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Streak motivation banner
class StreakBanner extends StatelessWidget {
  final int streakDays;
  final ThemeProvider themeProvider;

  const StreakBanner({
    super.key,
    required this.streakDays,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (streakDays <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "You're on fire!",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Keep the momentum going',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$streakDays',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick access grid with 3D assets - using ElevatedCard
class QuickAccessGrid extends StatelessWidget {
  final VoidCallback? onTasksTap;
  final VoidCallback? onWaterTap;
  final VoidCallback? onMoodTap;
  final VoidCallback? onMindfulnessTap;
  final int todayTasksCount;
  final ThemeProvider themeProvider;

  const QuickAccessGrid({
    super.key,
    this.onTasksTap,
    this.onWaterTap,
    this.onMoodTap,
    this.onMindfulnessTap,
    required this.todayTasksCount,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: themeProvider.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                imagePath: 'assets/images/checklist_2.png',
                title: 'My Tasks',
                subtitle: 'View all tasks',
                badge: todayTasksCount > 0 ? '$todayTasksCount Today' : null,
                onTap: onTasksTap,
                themeProvider: themeProvider,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                imagePath: 'assets/images/water_glass_check.png',
                title: 'Hydration',
                subtitle: 'Track water intake',
                onTap: onWaterTap,
                themeProvider: themeProvider,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                imagePath: 'assets/images/mood_circle.png',
                title: 'Mood Log',
                subtitle: 'How are you feeling?',
                onTap: onMoodTap,
                themeProvider: themeProvider,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                imagePath: 'assets/images/breathing.png',
                title: 'Mindfulness',
                subtitle: 'Breathing & meditation',
                onTap: onMindfulnessTap,
                themeProvider: themeProvider,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onTap;
  final ThemeProvider themeProvider;

  const _QuickCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderRadius: 20,
      height: 120,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    LucideIcons.sparkles,
                    size: 28,
                    color: themeProvider.primaryColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: themeProvider.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: themeProvider.textSecondary,
                ),
              ),
            ],
          ),
          if (badge != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Achievements horizontal carousel - simplified without heavy blur
class AchievementsCarousel extends StatelessWidget {
  final ThemeProvider themeProvider;

  const AchievementsCarousel({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final achievements = [
      _Achievement('🏆', 'First Steps', true),
      _Achievement('💪', 'Week Warrior', true),
      _Achievement('🎯', 'Goal Crusher', true),
      _Achievement('🌊', 'Hydration', true),
      _Achievement('🔒', 'Zen Master', false),
      _Achievement('🔒', '30 Day Streak', false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: themeProvider.textPrimary,
              ),
            ),
            Text(
              'See All',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: themeProvider.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 95,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: achievements.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _AchievementCard(
                icon: achievement.icon,
                name: achievement.name,
                isUnlocked: achievement.isUnlocked,
                themeProvider: themeProvider,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Achievement {
  final String icon;
  final String name;
  final bool isUnlocked;

  _Achievement(this.icon, this.name, this.isUnlocked);
}

class _AchievementCard extends StatelessWidget {
  final String icon;
  final String name;
  final bool isUnlocked;
  final ThemeProvider themeProvider;

  const _AchievementCard({
    required this.icon,
    required this.name,
    required this.isUnlocked,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.5,
      child: Container(
        width: 85,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeProvider.isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: themeProvider.isDarkMode
                  ? Colors.black.withValues(alpha: 0.2)
                  : themeProvider.primaryColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isUnlocked
                    ? LinearGradient(
                        colors: [
                          themeProvider.primaryColor,
                          themeProvider.primaryColor.withValues(alpha: 0.7),
                        ],
                      )
                    : null,
                color: isUnlocked
                    ? null
                    : themeProvider.textSecondary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: themeProvider.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings menu section - using ElevatedCard pattern
class SettingsMenuSection extends StatelessWidget {
  final ThemeProvider themeProvider;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onVoiceCommandsTap;
  final VoidCallback? onExportDataTap;
  final VoidCallback? onHelpTap;
  final VoidCallback? onSignOutTap;

  const SettingsMenuSection({
    super.key,
    required this.themeProvider,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    this.onNotificationsTap,
    this.onVoiceCommandsTap,
    this.onExportDataTap,
    this.onHelpTap,
    this.onSignOutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: themeProvider.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedCard(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          borderRadius: 20,
          child: Column(
            children: [
              _SettingsMenuItem(
                icon: LucideIcons.moon,
                iconColor: themeProvider.primaryColor,
                iconBgColor: themeProvider.primaryColor.withValues(alpha: 0.12),
                title: 'Dark Mode',
                subtitle: 'Switch theme appearance',
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: onDarkModeChanged,
                  activeColor: themeProvider.primaryColor,
                ),
                themeProvider: themeProvider,
              ),
              _menuDivider(),
              _SettingsMenuItem(
                icon: LucideIcons.bell,
                iconColor: const Color(0xFF4FC3F7),
                iconBgColor: const Color(0xFF4FC3F7).withValues(alpha: 0.12),
                title: 'Notifications',
                subtitle: 'Reminders & alerts',
                onTap: onNotificationsTap,
                themeProvider: themeProvider,
              ),
              _menuDivider(),
              _SettingsMenuItem(
                icon: LucideIcons.mic,
                iconColor: const Color(0xFF9575CD),
                iconBgColor: const Color(0xFF9575CD).withValues(alpha: 0.12),
                title: 'Voice Commands',
                subtitle: 'Language & settings',
                onTap: onVoiceCommandsTap,
                themeProvider: themeProvider,
              ),
              _menuDivider(),
              _SettingsMenuItem(
                icon: LucideIcons.download,
                iconColor: const Color(0xFF81C784),
                iconBgColor: const Color(0xFF81C784).withValues(alpha: 0.12),
                title: 'Export Data',
                subtitle: 'Download your progress',
                onTap: onExportDataTap,
                themeProvider: themeProvider,
              ),
              _menuDivider(),
              _SettingsMenuItem(
                icon: LucideIcons.info,
                iconColor: themeProvider.primaryColor,
                iconBgColor: themeProvider.primaryColor.withValues(alpha: 0.12),
                title: 'Help & Support',
                subtitle: 'FAQ, contact us',
                onTap: onHelpTap,
                themeProvider: themeProvider,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Sign out button
        GestureDetector(
          onTap: onSignOutTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.logOut,
                  color: const Color(0xFFD32F2F),
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD32F2F),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _menuDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: themeProvider.isDarkMode
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.05),
    );
  }
}

class _SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final ThemeProvider themeProvider;

  const _SettingsMenuItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  LucideIcons.chevronRight,
                  color: themeProvider.textSecondary,
                  size: 16,
                ),
          ],
        ),
      ),
    );
  }
}
