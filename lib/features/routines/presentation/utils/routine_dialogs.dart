import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateRoutinePage(),
      ),
    );
  }
}
