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
  final double? width;
  final double? height;

  const ElevatedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 24,
    this.backgroundColor,
    this.onTap,
    this.isSurface = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final baseColor =
        backgroundColor ??
        (isSurface ? themeProvider.surfaceColor : themeProvider.cardColor);

    final decoration = BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        // Neumorphic: Light shadow (top-left) - ışık kaynağı
        BoxShadow(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.white.withValues(alpha: 0.5),
          offset: const Offset(-3, -3),
          blurRadius: 6,
        ),
        // Neumorphic: Dark shadow (bottom-right) - gölge
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.12),
          offset: const Offset(3, 3),
          blurRadius: 6,
        ),
      ],
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: themeProvider.primaryColor.withValues(alpha: 0.2),
            highlightColor: themeProvider.primaryColor.withValues(alpha: 0.1),
            child: Container(
              width: width,
              height: height,
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }
}
