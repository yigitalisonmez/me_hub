import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mesh_gradient/mesh_gradient.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/app_route.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../../challenges/domain/entities/badge.dart' as challenge_badge;
import '../../../challenges/presentation/pages/challenges_page.dart';
import '../../../challenges/presentation/providers/challenges_provider.dart';
import '../../../challenges/presentation/utils/challenge_icon_lookup.dart';

/// Hero section with animated mesh gradient background and settings button
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
    final primary = themeProvider.primaryColor;

    // Define colors based on theme - using primaryColor
    final gradientColors = themeProvider.isDarkMode
        ? [
            primary,
            const Color(0xFF8B5A3C), // Dark terracotta
            const Color(0xFF5C4033), // Deep brown
            primary.withValues(alpha: 0.6),
          ]
        : [
            primary, // Terracotta from theme
            const Color(0xFFD4A574), // Soft tan
            primary.withValues(alpha: 0.7),
            const Color(0xFFF5DEB3), // Wheat
          ];

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Animated mesh gradient background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: AnimatedMeshGradient(
                colors: gradientColors,
                options: AnimatedMeshGradientOptions(
                  speed: 0.8,
                  frequency: 3,
                  amplitude: 80,
                  grain: 0.0,
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
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
        ],
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
  final String profileLabel;
  final String? avatarInitials;
  final int totalTasksCompleted;
  final int maxStreak;
  final int totalWaterMl;
  final VoidCallback? onEditTap;
  final ThemeProvider themeProvider;

  const ProfileCard({
    super.key,
    required this.userName,
    required this.profileLabel,
    this.avatarInitials,
    required this.totalTasksCompleted,
    required this.maxStreak,
    required this.totalWaterMl,
    this.onEditTap,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _buildInitials(userName);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(
                  alpha: themeProvider.isDarkMode ? 0.15 : 0.7,
                ),
                Colors.white.withValues(
                  alpha: themeProvider.isDarkMode ? 0.08 : 0.5,
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                            avatarInitials ?? initials,
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
                                color: Colors.white.withValues(alpha: 0.5),
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
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : themeProvider.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profileLabel,
                          style: TextStyle(
                            fontSize: 13,
                            color: themeProvider.isDarkMode
                                ? Colors.white70
                                : themeProvider.textSecondary,
                          ),
                        ),
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
                    isGlass: true,
                  ),
                  const SizedBox(width: 12),
                  _MiniStat(
                    value: '$maxStreak',
                    label: 'Max Streak',
                    themeProvider: themeProvider,
                    isGlass: true,
                  ),
                  const SizedBox(width: 12),
                  _MiniStat(
                    value: '${(totalWaterMl / 1000).toStringAsFixed(1)}L',
                    label: 'Water Logged',
                    themeProvider: themeProvider,
                    isGlass: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }

    final end = trimmed.length >= 2 ? 2 : 1;
    return trimmed.substring(0, end).toUpperCase();
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final ThemeProvider themeProvider;
  final bool isGlass;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.themeProvider,
    this.isGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isGlass
              ? Colors.white.withValues(alpha: 0.2)
              : (themeProvider.isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : themeProvider.backgroundColor),
          borderRadius: BorderRadius.circular(12),
          border: isGlass
              ? Border.all(color: Colors.white.withValues(alpha: 0.3))
              : null,
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
                color: isGlass && !themeProvider.isDarkMode
                    ? themeProvider.textSecondary
                    : themeProvider.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

/// Achievements horizontal carousel - dynamically loads from ChallengesProvider
class AchievementsCarousel extends StatelessWidget {
  final ThemeProvider themeProvider;

  const AchievementsCarousel({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final challengesProvider = context.watch<ChallengesProvider>();
    final allBadges = challengesProvider.allBadges;

    // Show up to 6 badges. Prefer unlocked badges first, then locked ones.
    final displayBadges = [...allBadges];
    displayBadges.sort((a, b) {
      if (a.isUnlocked && !b.isUnlocked) return -1;
      if (!a.isUnlocked && b.isUnlocked) return 1;
      return 0; // Keep original order otherwise
    });

    final carouselBadges = displayBadges.take(6).toList();

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
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  AppRoute(page: const ChallengesPage()),
                );
              },
              child: Text(
                'See All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (carouselBadges.isEmpty)
          const Text(
            'No achievements yet.',
            style: TextStyle(color: Colors.grey),
          )
        else
          SizedBox(
            height: 95,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: carouselBadges.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final badge = carouselBadges[index];
                return _AchievementCard(
                  badge: badge,
                  themeProvider: themeProvider,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final challenge_badge.Badge badge;
  final ThemeProvider themeProvider;

  const _AchievementCard({required this.badge, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = badge.isUnlocked;
    final iconData = materialIconFromCodePoint(badge.iconCodePoint);

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
                child: isUnlocked
                    ? Icon(iconData, color: Colors.white, size: 20)
                    : const Icon(
                        LucideIcons.lock,
                        color: Colors.white70,
                        size: 18,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.name,
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
  final VoidCallback? onVoiceCommandsTap;
  final VoidCallback? onHelpTap;

  const SettingsMenuSection({
    super.key,
    required this.themeProvider,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    this.onVoiceCommandsTap,
    this.onHelpTap,
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
                title: 'Reminders',
                subtitle: 'Managed in routines & calendar',
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
                icon: LucideIcons.info,
                iconColor: themeProvider.primaryColor,
                iconBgColor: themeProvider.primaryColor.withValues(alpha: 0.12),
                title: 'About Kora',
                subtitle: 'Local data & app info',
                onTap: onHelpTap,
                themeProvider: themeProvider,
              ),
            ],
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
                (onTap == null
                    ? const SizedBox.shrink()
                    : Icon(
                        LucideIcons.chevronRight,
                        color: themeProvider.textSecondary,
                        size: 16,
                      )),
          ],
        ),
      ),
    );
  }
}
