import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smooth_gradient/smooth_gradient.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/constants/routine_icons.dart';
import '../../domain/entities/routine.dart';
import '../providers/routines_provider.dart';
import '../widgets/icon_picker_dialog.dart';
import '../widgets/habit_list_item.dart';
import '../widgets/add_item_dialog.dart';

class EditRoutinePage extends StatefulWidget {
  final Routine routine;

  const EditRoutinePage({super.key, required this.routine});

  @override
  State<EditRoutinePage> createState() => _EditRoutinePageState();
}

class _EditRoutinePageState extends State<EditRoutinePage> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteItem(
    BuildContext context,
    RoutineItem item,
  ) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete Habit',
      message: 'Are you sure you want to delete "${item.title}"?',
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<RoutinesProvider>();
      try {
        await provider.deleteItem(widget.routine.id, item.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete habit: $e')));
        }
      }
    }
  }

  Future<void> _editHabit(BuildContext context, RoutineItem item) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditHabitBottomSheet(item: item),
    );

    if (result != null && context.mounted) {
      final provider = context.read<RoutinesProvider>();
      await provider.editItem(
        widget.routine.id,
        item.id,
        title: result['title'] as String?,
        iconCodePoint: result['iconCodePoint'] as int?,
      );
    }
  }

  Future<void> _addItem(BuildContext context) async {
    final provider = context.read<RoutinesProvider>();
    final currentRoutine =
        provider.getRoutineById(widget.routine.id) ?? widget.routine;

    await showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        onAdd: (title, iconCodePoint) async {
          final item = provider.createRoutineItem(
            title: title,
            iconCodePoint: iconCodePoint,
          );
          await provider.addItem(currentRoutine.id, item);
        },
      ),
    );
  }

  Future<void> _saveRoutine() async {
    final provider = context.read<RoutinesProvider>();
    final error = await provider.updateRoutineName(
      widget.routine.id,
      _nameController.text,
    );

    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: SmoothGradient(
            from: themeProvider.primaryColor.withValues(alpha: 0.3),
            to: themeProvider.backgroundColor,
            curve: Curves.easeInOut,
          ),
        ),
        child: SafeArea(
          child: Consumer<RoutinesProvider>(
            builder: (context, provider, _) {
              final updatedRoutine =
                  provider.getRoutineById(widget.routine.id) ?? widget.routine;

              return Column(
                children: [
                  _buildHeader(context, updatedRoutine),
                  _buildHabitsList(context, provider, updatedRoutine),
                  _buildAddItemButton(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Routine routine) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          _buildHeaderButtons(context),
          const SizedBox(height: 16),
          _buildHeaderIcon(routine),
          const SizedBox(height: 12),
          _buildHeaderTitle(context),
          const SizedBox(height: 8),
          _buildRoutineNameBadge(context, routine),
        ],
      ),
    );
  }

  Widget _buildHeaderButtons(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back button (circular, white background)
        Container(
          decoration: BoxDecoration(
            color: themeProvider.cardColor.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: themeProvider.primaryColor.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              LucideIcons.arrowLeft,
              color: themeProvider.primaryColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // Save button (circular, orange background)
        Container(
          decoration: BoxDecoration(
            color: themeProvider.primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: themeProvider.primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              LucideIcons.check,
              color: themeProvider.textPrimary,
              size: 20,
            ),
            onPressed: _saveRoutine,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(Routine routine) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        routine.items.isNotEmpty && routine.items.first.iconCodePoint != null
            ? (RoutineIcons.getIconFromCodePoint(
                    routine.items.first.iconCodePoint!,
                  ) ??
                  LucideIcons.sun)
            : LucideIcons.sun,
        color: themeProvider.primaryColor,
        size: 28,
      ),
    );
  }

  Widget _buildHeaderTitle(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Text(
      'Edit Routine',
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(color: themeProvider.primaryColor),
    );
  }

  Widget _buildRoutineNameBadge(BuildContext context, Routine routine) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Material(
      elevation: 0.5,
      borderRadius: BorderRadius.circular(100),
      color: themeProvider.cardColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: themeProvider.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              routine.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: themeProvider.textPrimary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsList(
    BuildContext context,
    RoutinesProvider provider,
    Routine routine,
  ) {
    return Expanded(
      child: ReorderableListView.builder(
        key: ValueKey('habits_list_${routine.id}_${routine.items.length}'),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: routine.items.length,
        onReorder: (oldIndex, newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          provider.reorderItems(widget.routine.id, oldIndex, newIndex);
        },
        proxyDecorator: (child, index, animation) {
          final themeProvider = context.watch<ThemeProvider>();
          final item = routine.items[index];
          return Material(
            color: themeProvider.cardColor,
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: HabitListItem(
              item: item,
              index: index,
              onDelete: () => _confirmDeleteItem(context, item),
              onEdit: () => _editHabit(context, item),
            ),
          );
        },
        itemBuilder: (context, index) {
          final item = routine.items[index];
          return Padding(
            key: ValueKey(item.id),
            padding: const EdgeInsets.only(bottom: 12),
            child: HabitListItem(
              item: item,
              index: index,
              onDelete: () => _confirmDeleteItem(context, item),
              onEdit: () => _editHabit(context, item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddItemButton(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: themeProvider.backgroundColor),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _addItem(context),
            icon: Icon(LucideIcons.plus, color: themeProvider.primaryColor),
            label: Text(
              'Add New Item',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeProvider.primaryColor,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: themeProvider.cardColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: themeProvider.borderColor, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditHabitBottomSheet extends StatefulWidget {
  final RoutineItem item;

  const _EditHabitBottomSheet({required this.item});

  @override
  State<_EditHabitBottomSheet> createState() => _EditHabitBottomSheetState();
}

class _EditHabitBottomSheetState extends State<_EditHabitBottomSheet> {
  late TextEditingController _titleController;
  late int? _selectedIconCodePoint;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _selectedIconCodePoint = widget.item.iconCodePoint;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final iconCodePoint = await showDialog<int>(
      context: context,
      builder: (context) =>
          IconPickerDialog(selectedIconCodePoint: _selectedIconCodePoint),
    );

    if (iconCodePoint != null) {
      setState(() {
        _selectedIconCodePoint = iconCodePoint;
      });
    }
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit name cannot be empty')),
      );
      return;
    }

    Navigator.pop(context, {
      'title': _titleController.text.trim(),
      'iconCodePoint': _selectedIconCodePoint,
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.pencilLine,
                  color: themeProvider.primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Edit Habit',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: themeProvider.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.pencilLine,
                  color: themeProvider.primaryColor,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                height: 2,
                width: 60,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Title field
            Text(
              'Habit Name',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: themeProvider.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: TextStyle(color: themeProvider.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter habit name',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeProvider.textSecondary.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: themeProvider.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: themeProvider.borderColor.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: themeProvider.borderColor.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: themeProvider.borderColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Icon picker
            Text(
              'Icon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: themeProvider.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickIcon,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeProvider.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: themeProvider.borderColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    if (_selectedIconCodePoint != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeProvider.cardColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          RoutineIcons.getIconFromCodePoint(
                                _selectedIconCodePoint!,
                              ) ??
                              LucideIcons.circle,
                          color: themeProvider.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      _selectedIconCodePoint != null
                          ? 'Change Icon'
                          : 'Select Icon',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: themeProvider.textPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: themeProvider.textSecondary.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: themeProvider.textSecondary.withValues(
                          alpha: 0.3,
                        ),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: themeProvider.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: themeProvider.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.primaryColor.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: themeProvider.textPrimary,
                              fontWeight: FontWeight.bold,
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
