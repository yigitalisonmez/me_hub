import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/theme_provider.dart';

/// Generic confirmation dialog for delete/destructive actions
///
/// Example usage:
/// ```dart
/// final confirmed = await showConfirmationDialog(
///   context: context,
///   title: 'Delete Item',
///   message: 'Are you sure you want to delete this item?',
/// );
/// if (confirmed == true) {
///   // Perform delete action
/// }
/// ```
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Delete',
  String cancelText = 'Cancel',
  bool isDangerous = true,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ConfirmationDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      isDangerous: isDangerous,
    ),
  );
}

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDangerous;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Delete',
    this.cancelText = 'Cancel',
    this.isDangerous = true,
  });

  /// Elevated element color - lighter than card
  Color _getElevatedColor(bool isDark) {
    return isDark ? const Color(0xFF454545) : Colors.white;
  }

  /// Bevel shadow for raised elements
  List<BoxShadow> _getRaisedShadow(bool isDark) {
    return [
      // Top highlight
      BoxShadow(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.9),
        offset: const Offset(0, -1),
        blurRadius: 2,
      ),
      // Bottom shadow
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
        offset: const Offset(0, 3),
        blurRadius: 6,
        spreadRadius: 1,
      ),
    ];
  }

  /// Active element shadow with color glow
  List<BoxShadow> _getActiveShadow(Color color, bool isDark) {
    return [
      // Color glow
      BoxShadow(
        color: color.withValues(alpha: isDark ? 0.4 : 0.3),
        offset: Offset.zero,
        blurRadius: 10,
      ),
      // Top highlight
      BoxShadow(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.9),
        offset: const Offset(0, -1),
        blurRadius: 2,
      ),
      // Bottom shadow
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
        offset: const Offset(0, 4),
        blurRadius: 8,
        spreadRadius: 1,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final confirmColor = isDangerous
        ? AppColors.error
        : themeProvider.primaryColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            // Top highlight
            BoxShadow(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.7),
              offset: const Offset(0, -2),
              blurRadius: 4,
            ),
            // Bottom shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.25),
              offset: const Offset(0, 8),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeProvider.primaryColor,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Cancel button - raised
                Container(
                  decoration: BoxDecoration(
                    color: _getElevatedColor(isDark),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _getRaisedShadow(isDark),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(false),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Text(
                          cancelText,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: themeProvider.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Confirm button - active glow
                Container(
                  decoration: BoxDecoration(
                    color: confirmColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _getActiveShadow(confirmColor, isDark),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(true),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
