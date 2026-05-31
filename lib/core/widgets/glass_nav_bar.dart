import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';

/// A beautiful glassmorphism navigation bar with frosted glass effect
/// and center mic FAB for voice commands
class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onMicTap;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.only(left: 18, right: 18, bottom: bottomPadding + 12),
      height: 74,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(color: Colors.transparent),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AppColors.darkCard.withValues(alpha: 0.78),
                              AppColors.darkSurface.withValues(alpha: 0.58),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.78),
                              AppColors.surface.withValues(alpha: 0.58),
                            ],
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.09)
                          : Colors.white.withValues(alpha: 0.72),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.42)
                            : const Color(0xFF7C5E42).withValues(alpha: 0.14),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                ),
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
                      const SizedBox(width: 56),
                      _buildNavItem(
                        context,
                        icon: LucideIcons.user,
                        label: 'Profile',
                        index: 1,
                        themeProvider: themeProvider,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: -20,
            child: Center(
              child: GestureDetector(
                onTap: onMicTap,
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.48),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.primaryColor.withValues(
                          alpha: 0.42,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.mic,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? themeProvider.primaryColor.withValues(
                  alpha: isDark ? 0.18 : 0.16,
                )
              : Colors.transparent,
          border: isSelected
              ? Border.all(
                  color: themeProvider.primaryColor.withValues(alpha: 0.18),
                )
              : null,
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
