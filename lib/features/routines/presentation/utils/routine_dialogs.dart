import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../domain/entities/routine.dart';
import '../providers/routines_provider.dart';
import '../widgets/add_item_dialog.dart';
import '../widgets/edit_routine_dialog.dart';

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
    final provider = context.read<RoutinesProvider>();
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => EditRoutineDialog(routine: routine),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      // Get the current routine from provider (it might have been updated with deletions)
      final currentRoutine = provider.routines.firstWhere(
        (r) => r.id == routine.id,
        orElse: () => routine,
      );
      final updatedRoutine = currentRoutine.copyWith(name: newName.trim());
      await provider.updateRoutine(updatedRoutine);
    }
  }

  static Future<void> showDeleteRoutine(
    BuildContext context,
    Routine routine,
  ) async {
    final provider = context.read<RoutinesProvider>();
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete Routine',
      message: 'Are you sure you want to delete "${routine.name}"?',
    );

    if (confirmed == true) {
      await provider.deleteRoutine(routine.id);
    }
  }

  static Future<void> showAddRoutine(BuildContext context) async {
    final provider = context.read<RoutinesProvider>();
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Routine'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Routine name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      await provider.addNewRoutine(
        DateTime.now().microsecondsSinceEpoch.toString(),
        controller.text.trim(),
      );
    }
  }
}
