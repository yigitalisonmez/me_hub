import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
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
  final Color? borderColor;
  final Gradient? gradient;

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
    this.borderColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final baseColor =
        backgroundColor ??
        (isSurface ? themeProvider.surfaceColor : themeProvider.cardColor);

    final hairline =
        borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.07)
            : AppColors.textPrimary.withValues(alpha: 0.08));

    final decoration = BoxDecoration(
      color: baseColor,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: hairline),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.34)
              : const Color(0xFF7C5E42).withValues(alpha: 0.08),
          offset: const Offset(0, 12),
          blurRadius: 28,
          spreadRadius: -10,
        ),
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.7),
          offset: const Offset(0, 1),
          blurRadius: 1,
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
