import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';

/// Button style variants
enum ActionButtonVariant { primary, secondary, ghost }

/// A reusable action button with consistent styling.
///
/// Supports primary, secondary, and ghost variants.
///
/// Example:
/// ```dart
/// ActionButton(
///   label: 'Add New Goal',
///   icon: LucideIcons.plus,
///   variant: ActionButtonVariant.primary,
///   onPressed: () => ...,
/// )
/// ```
class ActionButton extends StatelessWidget {
  /// Button label text
  final String label;

  /// Optional leading icon
  final IconData? icon;

  /// Button style variant
  final ActionButtonVariant variant;

  /// Tap handler
  final VoidCallback? onPressed;

  /// Whether to expand to full width
  final bool fullWidth;

  /// Button padding
  final EdgeInsetsGeometry? padding;

  /// Custom border radius
  final double borderRadius;

  const ActionButton({
    super.key,
    required this.label,
    this.icon,
    this.variant = ActionButtonVariant.primary,
    this.onPressed,
    this.fullWidth = true,
    this.padding,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final isPrimary = variant == ActionButtonVariant.primary;
    final isGhost = variant == ActionButtonVariant.ghost;

    final backgroundColor = isPrimary
        ? themeProvider.primaryColor
        : isGhost
        ? Colors.transparent
        : themeProvider.surfaceColor;

    final foregroundColor = isPrimary
        ? AppColors.white
        : themeProvider.primaryColor;

    final borderSide = isPrimary || isGhost
        ? BorderSide.none
        : BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : themeProvider.primaryColor.withValues(alpha: 0.2),
            width: 1,
          );

    final buttonPadding =
        padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 24);

    final button = Container(
      decoration: isPrimary
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.primaryColor.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            )
          : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: buttonPadding,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: borderSide,
          ),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// An icon-only action button
class IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const IconActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final buttonColor = color ?? themeProvider.primaryColor;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: themeProvider.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeProvider.isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: themeProvider.isDarkMode
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.white,
              offset: const Offset(0, -1),
              blurRadius: 2,
            ),
            BoxShadow(
              color: themeProvider.isDarkMode
                  ? Colors.black.withValues(alpha: 0.2)
                  : themeProvider.primaryColor.withValues(alpha: 0.05),
              offset: const Offset(0, 3),
              blurRadius: 6,
              spreadRadius: -1,
            ),
          ],
        ),
        child: Icon(icon, color: buttonColor, size: 20),
      ),
    );
  }
}
