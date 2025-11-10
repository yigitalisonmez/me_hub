import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    final confirmColor = isDangerous ? Colors.red : AppColors.primaryOrange;
    final confirmBgColor = isDangerous
        ? Colors.red.withValues(alpha: 0.1)
        : AppColors.primaryOrange.withValues(alpha: 0.1);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.darkGrey,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          color: AppColors.darkGrey,
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: AppColors.darkGrey.withValues(alpha: 0.3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            cancelText,
            style: const TextStyle(
              color: AppColors.darkGrey,
            ),
          ),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: OutlinedButton.styleFrom(
            backgroundColor: confirmBgColor,
            side: BorderSide(color: confirmColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            confirmText,
            style: TextStyle(
              color: confirmColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

