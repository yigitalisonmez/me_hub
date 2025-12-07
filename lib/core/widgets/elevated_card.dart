import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ElevatedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool isSurface; // If true, uses surfaceColor default, else cardColor

  const ElevatedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 24,
    this.backgroundColor,
    this.onTap,
    this.isSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final baseColor =
        backgroundColor ??
        (isSurface ? themeProvider.surfaceColor : themeProvider.cardColor);

    final Widget content = Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          // Shadow 1 (Top - Light Source)
          BoxShadow(
            color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
            offset: const Offset(0, -2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
          // Shadow 2 (Bottom - Ground Separation)
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : themeProvider.primaryColor.withValues(alpha: 0.15),
            offset: const Offset(0, 8),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }
}
