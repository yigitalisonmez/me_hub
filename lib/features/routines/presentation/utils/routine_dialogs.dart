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
      try {
        await provider.deleteRoutine(routine.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Routine "${routine.name}" deleted successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting routine: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    return confirmed;
  }

  static Future<void> showAddRoutine(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateRoutinePage()),
    );
  }
}

class _DeleteRoutineDialog extends StatelessWidget {
  final Routine routine;

  const _DeleteRoutineDialog({required this.routine});

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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(20),
          // Bevel shadow for dialog
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
          children: [
            // Icon - with raised bevel
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
                boxShadow: _getRaisedShadow(isDark),
              ),
              child: const Icon(
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
                color: themeProvider.primaryColor,
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
                // Cancel button - raised
                Expanded(
                  child: Container(
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: themeProvider.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Delete button - active glow
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _getActiveShadow(Colors.red, isDark),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(true),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
