import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// A beautiful glassmorphism navigation bar with frosted glass effect
class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, bottom: bottomPadding + 12),
      height: 70,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Blur layer - this blurs what's behind
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.transparent),
            ),
            // Glass overlay - much more transparent to show blur
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.04),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.15),
                        ],
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.4),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            // Nav items
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context,
                    icon: LucideIcons.house,
                    label: 'Home',
                    index: 0,
                    themeProvider: themeProvider,
                  ),
                  _buildNavItem(
                    context,
                    icon: LucideIcons.listTodo,
                    label: 'Tasks',
                    index: 1,
                    themeProvider: themeProvider,
                  ),
                  _buildNavItem(
                    context,
                    icon: LucideIcons.droplet,
                    label: 'Water',
                    index: 2,
                    themeProvider: themeProvider,
                  ),
                  _buildNavItem(
                    context,
                    icon: LucideIcons.repeat,
                    label: 'Routines',
                    index: 3,
                    themeProvider: themeProvider,
                  ),
                  _buildNavItem(
                    context,
                    icon: LucideIcons.heart,
                    label: 'Mood',
                    index: 4,
                    themeProvider: themeProvider,
                  ),
                  _buildNavItem(
                    context,
                    icon: LucideIcons.settings,
                    label: 'Settings',
                    index: 5,
                    themeProvider: themeProvider,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required ThemeProvider themeProvider,
  }) {
    final isSelected = currentIndex == index;
    final isDark = themeProvider.isDarkMode;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isSelected
              ? themeProvider.primaryColor.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? themeProvider.primaryColor
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : themeProvider.textSecondary.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? themeProvider.primaryColor
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : themeProvider.textSecondary.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
