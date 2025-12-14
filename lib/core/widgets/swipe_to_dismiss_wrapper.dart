import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// Reusable swipe-to-delete wrapper for consistent delete behavior across the app.
///
/// Features:
/// - Swipe left to reveal delete action
/// - Red background with trash icon
/// - Haptic feedback on delete
/// - Optional confirmation dialog
class SwipeToDismissWrapper extends StatelessWidget {
  final Widget child;
  final String itemId;
  final VoidCallback onDelete;
  final bool requireConfirmation;
  final String? confirmationTitle;
  final String? confirmationMessage;

  const SwipeToDismissWrapper({
    super.key,
    required this.child,
    required this.itemId,
    required this.onDelete,
    this.requireConfirmation = false,
    this.confirmationTitle,
    this.confirmationMessage,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Dismissible(
      key: Key(itemId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.trash2, color: AppColors.error, size: 20),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();

        if (requireConfirmation) {
          final result = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: themeProvider.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                confirmationTitle ?? 'Delete Item',
                style: TextStyle(color: themeProvider.textPrimary),
              ),
              content: Text(
                confirmationMessage ??
                    'Are you sure you want to delete this item?',
                style: TextStyle(color: themeProvider.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: themeProvider.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          );

          if (result == true) {
            onDelete();
          }
          return false; // Always return false to prevent Dismissible state issues
        } else {
          onDelete();
          return false; // Return false, widget will be removed by state update
        }
      },
      child: child,
    );
  }
}
