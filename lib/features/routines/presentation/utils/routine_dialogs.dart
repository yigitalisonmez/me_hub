import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../domain/entities/routine.dart';
import '../providers/routines_provider.dart';
import '../widgets/add_item_dialog.dart';
import '../pages/edit_routine_page.dart';
import '../pages/create_routine_page.dart';

class RoutineDialogs {
  RoutineDialogs._();

  static Future<void> showAddItem(BuildContext context, Routine routine) async {
    final provider = context.read<RoutinesProvider>();
    await showDialog(
      context: context,
      builder: (_) => AddItemDialog(
        onAdd: (title, iconCodePoint) async {
          final item = RoutineItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title,
            iconCodePoint: iconCodePoint,
          );
          await provider.addItem(routine.id, item);
        },
      ),
    );
  }

  static Future<void> showEditRoutine(
    BuildContext context,
    Routine routine,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRoutinePage(routine: routine),
      ),
    );
  }

  static Future<bool?> showDeleteRoutine(
    BuildContext context,
    Routine routine,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => _DeleteRoutineDialog(routine: routine),
    );

    if (confirmed == true) {
      final provider = context.read<RoutinesProvider>();
      await provider.deleteRoutine(routine.id);
    }

    return confirmed;
  }

  static Future<void> showAddRoutine(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateRoutinePage(),
      ),
    );
  }
}

class _DeleteRoutineDialog extends StatelessWidget {
  final Routine routine;

  const _DeleteRoutineDialog({required this.routine});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: themeProvider.borderColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.trash2,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              'Delete Routine',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: themeProvider.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            // Message
            Text(
              'Are you sure you want to delete "${routine.name}"? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: themeProvider.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: themeProvider.borderColor,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: themeProvider.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Delete button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
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
