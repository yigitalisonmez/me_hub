import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Snackbar type variants
enum AppSnackBarType { success, error, warning, info }

/// A unified snackbar system with consistent styling.
///
/// Example:
/// ```dart
/// AppSnackBar.show(
///   context,
///   message: 'Item deleted',
///   type: AppSnackBarType.info,
///   action: SnackBarAction(label: 'Undo', onPressed: () => ...),
/// )
/// ```
class AppSnackBar {
  AppSnackBar._();

  /// Show a styled snackbar
  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarType type = AppSnackBarType.info,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
    bool clearPrevious = true,
  }) {
    final themeProvider = context.read<ThemeProvider>();

    if (clearPrevious) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }

    final config = _getTypeConfig(type, themeProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(config.icon, color: config.iconColor, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: themeProvider.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: themeProvider.surfaceColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: config.borderColor, width: 1),
        ),
        duration: duration,
        action: action != null
            ? SnackBarAction(
                label: action.label,
                textColor: themeProvider.primaryColor,
                onPressed: action.onPressed,
              )
            : null,
      ),
    );
  }

  /// Show a success snackbar
  static void success(BuildContext context, String message) {
    show(context, message: message, type: AppSnackBarType.success);
  }

  /// Show an error snackbar
  static void error(BuildContext context, String message) {
    show(
      context,
      message: message,
      type: AppSnackBarType.error,
      duration: const Duration(seconds: 4),
    );
  }

  /// Show a warning snackbar
  static void warning(BuildContext context, String message) {
    show(context, message: message, type: AppSnackBarType.warning);
  }

  /// Show an info snackbar
  static void info(BuildContext context, String message) {
    show(context, message: message, type: AppSnackBarType.info);
  }

  /// Show a snackbar with undo action
  static void withUndo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 5),
  }) {
    show(
      context,
      message: message,
      type: AppSnackBarType.info,
      duration: duration,
      action: SnackBarAction(label: 'Undo', onPressed: onUndo),
    );
  }

  static _SnackBarTypeConfig _getTypeConfig(
    AppSnackBarType type,
    ThemeProvider themeProvider,
  ) {
    switch (type) {
      case AppSnackBarType.success:
        return _SnackBarTypeConfig(
          icon: LucideIcons.circleCheck,
          iconColor: const Color(0xFF4CAF50),
          borderColor: const Color(0xFF4CAF50).withValues(alpha: 0.3),
        );
      case AppSnackBarType.error:
        return _SnackBarTypeConfig(
          icon: LucideIcons.circleX,
          iconColor: const Color(0xFFE53935),
          borderColor: const Color(0xFFE53935).withValues(alpha: 0.3),
        );
      case AppSnackBarType.warning:
        return _SnackBarTypeConfig(
          icon: LucideIcons.triangleAlert,
          iconColor: const Color(0xFFFF9800),
          borderColor: const Color(0xFFFF9800).withValues(alpha: 0.3),
        );
      case AppSnackBarType.info:
        return _SnackBarTypeConfig(
          icon: LucideIcons.info,
          iconColor: themeProvider.primaryColor,
          borderColor: themeProvider.primaryColor.withValues(alpha: 0.2),
        );
    }
  }
}

class _SnackBarTypeConfig {
  final IconData icon;
  final Color iconColor;
  final Color borderColor;

  _SnackBarTypeConfig({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
  });
}
