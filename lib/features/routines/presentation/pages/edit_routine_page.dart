import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/constants/routine_icons.dart';

import '../../domain/entities/routine.dart';
import '../providers/routines_provider.dart';
import '../providers/edit_routine_provider.dart';
import '../widgets/icon_picker_dialog.dart';
import '../widgets/habit_list_item.dart';
import '../widgets/add_item_dialog.dart';
import '../widgets/routine_icon_picker.dart';
import '../widgets/routine_time_picker.dart';
import '../utils/routine_dialogs.dart';
import '../../../../core/widgets/clay_container.dart';

class EditRoutinePage extends StatefulWidget {
  final Routine routine;

  const EditRoutinePage({super.key, required this.routine});

  @override
  State<EditRoutinePage> createState() => _EditRoutinePageState();
}

class _EditRoutinePageState extends State<EditRoutinePage> {
  late TextEditingController _nameController;
  late EditRoutineProvider _editProvider;

  @override
  void initState() {
    super.initState();
    final routinesProvider = context.read<RoutinesProvider>();
    _editProvider = EditRoutineProvider(
      routinesProvider: routinesProvider,
      routineId: widget.routine.id,
    );
    _nameController = TextEditingController(text: _editProvider.name);
    _nameController.addListener(() {
      _editProvider.updateName(_nameController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _editProvider.dispose();
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
      try {
        await _editProvider.deleteItem(item.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete habit: $e')));
        }
      }
    }
  }

  Future<void> _editHabit(
    BuildContext context,
    RoutineItem item,
    EditRoutineProvider editProvider,
  ) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditHabitBottomSheet(item: item),
    );

    if (result != null && context.mounted) {
      await editProvider.editItem(
        item.id,
        title: result['title'] as String?,
        iconCodePoint: result['iconCodePoint'] as int?,
      );
    }
  }

  Future<void> _addItem(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        onAdd: (title, iconCodePoint) async {
          await _editProvider.addItem(title, iconCodePoint);
        },
      ),
    );
  }

  Future<void> _saveRoutine() async {
    await _editProvider.saveRoutine();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return ChangeNotifierProvider.value(
      value: _editProvider,
      child: Material(
        color: themeProvider.backgroundColor,
        child: SafeArea(
          child: Consumer2<EditRoutineProvider, RoutinesProvider>(
            builder: (context, editProvider, routinesProvider, _) {
              final updatedRoutine =
                  editProvider.currentRoutine ??
                  routinesProvider.getRoutineById(widget.routine.id) ??
                  widget.routine;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeader(context, updatedRoutine, editProvider),
                          _buildRoutineSettings(context, editProvider),
                          const SizedBox(height: 16),
                          _buildHabitsSection(
                            context,
                            routinesProvider,
                            updatedRoutine,
                            editProvider,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildAddItemButton(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Routine routine,
    EditRoutineProvider editProvider,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          _buildHeaderButtons(context),
          const SizedBox(height: 16),
          _buildHeaderIcon(editProvider),
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
        // Back button (circular)
        SizedBox(
          width: 40,
          height: 40,
          child: ClayContainer(
            padding: EdgeInsets.zero,
            borderRadius: 20,
            color: themeProvider.surfaceColor,
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Icon(
                LucideIcons.arrowLeft,
                color: themeProvider.primaryColor,
                size: 20,
              ),
            ),
          ),
        ),
        // Save button (circular)
        SizedBox(
          width: 40,
          height: 40,
          child: ClayContainer(
            padding: EdgeInsets.zero,
            borderRadius: 20,
            color: themeProvider.primaryColor,
            onTap: _saveRoutine,
            child: Center(
              child: Icon(
                LucideIcons.check,
                color: themeProvider.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(EditRoutineProvider editProvider) {
    final themeProvider = context.watch<ThemeProvider>();
    final icon = editProvider.selectedIconCodePoint != null
        ? RoutineIcons.getIconFromCodePoint(editProvider.selectedIconCodePoint!)
        : null;

    return GestureDetector(
      onTap: () => _pickRoutineIcon(context, editProvider),
      child: SizedBox(
        width: 80,
        height: 80,
        child: ClayContainer(
          padding: EdgeInsets.zero,
          borderRadius: 20,
          color: editProvider.selectedIconCodePoint != null
              ? themeProvider.primaryColor
              : themeProvider.surfaceColor,
          child: Center(
            child: Icon(
              icon ?? LucideIcons.circle,
              color: editProvider.selectedIconCodePoint != null
                  ? Colors.white
                  : themeProvider.primaryColor,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickRoutineIcon(
    BuildContext context,
    EditRoutineProvider editProvider,
  ) async {
    final iconCodePoint = await showDialog<int>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = MediaQuery.of(context).size.height * 0.7;
            return Container(
              constraints: BoxConstraints(
                maxHeight: maxHeight,
                maxWidth: constraints.maxWidth,
              ),
              decoration: BoxDecoration(
                color: context.watch<ThemeProvider>().cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Icon',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: context
                                    .watch<ThemeProvider>()
                                    .textPrimary,
                              ),
                        ),
                        IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            color: context.watch<ThemeProvider>().textSecondary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SizedBox(
                      height: maxHeight * 0.6,
                      child: RoutineIconPicker(
                        selectedIconCodePoint:
                            editProvider.selectedIconCodePoint,
                        onIconSelected: (codePoint) {
                          editProvider.updateIconCodePoint(codePoint);
                          Navigator.pop(context, codePoint);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (iconCodePoint != null) {
      editProvider.updateIconCodePoint(iconCodePoint);
    }
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
          color: themeProvider.surfaceColor,
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

  Widget _buildRoutineSettings(
    BuildContext context,
    EditRoutineProvider editProvider,
  ) {
    final themeProvider = context.watch<ThemeProvider>();

    return ClayContainer(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          Text(
            'Routine Name',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: themeProvider.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildInsetContainer(
            context,
            child: TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: themeProvider.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter routine name...',
                hintStyle: TextStyle(
                  color: themeProvider.textSecondary.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Time picker
          Text(
            'Time',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: themeProvider.textPrimary),
          ),
          const SizedBox(height: 12),
          RoutineTimePicker(
            selectedTime: editProvider.selectedTime,
            onTimeSelected: (time) {
              editProvider.updateTime(time);
            },
          ),
          const SizedBox(height: 24),
          // Days selector
          Text(
            'Active Days',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: themeProvider.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildCompactDaysSelector(context, editProvider),
          const SizedBox(height: 32),
          // Delete button
          _buildDeleteButton(context, editProvider),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(
    BuildContext context,
    EditRoutineProvider editProvider,
  ) {
    final themeProvider = context.watch<ThemeProvider>();
    return ClayContainer(
      onTap: () => _showDeleteRoutineDialog(context, editProvider),
      color: themeProvider.surfaceColor,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.trash2, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Text(
            'Delete Routine',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteRoutineDialog(
    BuildContext context,
    EditRoutineProvider editProvider,
  ) async {
    final routine = editProvider.currentRoutine ?? widget.routine;
    final confirmed = await RoutineDialogs.showDeleteRoutine(context, routine);

    if (confirmed == true && mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildHabitsSection(
    BuildContext context,
    RoutinesProvider provider,
    Routine routine,
    EditRoutineProvider editProvider,
  ) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Habits',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: themeProvider.textPrimary),
          ),
          const SizedBox(height: 12),
          ClayContainer(
            padding: EdgeInsets.zero,
            borderRadius: 20,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
                minHeight: 120,
              ),
              child: routine.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.listTodo,
                            size: 48,
                            color: themeProvider.textSecondary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No habits yet',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: themeProvider.textSecondary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add your first habit below',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: themeProvider.textSecondary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      key: ValueKey(
                        'habits_list_${routine.id}_${routine.items.length}',
                      ),
                      padding: const EdgeInsets.all(16),
                      itemCount: routine.items.length,
                      onReorder: (oldIndex, newIndex) {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        editProvider.reorderItems(oldIndex, newIndex);
                      },
                      proxyDecorator: (child, index, animation) {
                        final themeProvider = context.watch<ThemeProvider>();
                        final item = routine.items[index];
                        return ClayContainer(
                          color: themeProvider.surfaceColor,
                          borderRadius: 16,
                          child: HabitListItem(
                            item: item,
                            index: index,
                            onDelete: () => _confirmDeleteItem(context, item),
                            onEdit: () =>
                                _editHabit(context, item, editProvider),
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
                            onEdit: () =>
                                _editHabit(context, item, editProvider),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDaysSelector(
    BuildContext context,
    EditRoutineProvider editProvider,
  ) {
    final themeProvider = context.watch<ThemeProvider>();
    const List<String> dayAbbreviations = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      children: List.generate(7, (index) {
        final isSelected = editProvider.selectedDays.contains(index);

        return Expanded(
          child: GestureDetector(
            onTap: () => editProvider.toggleDay(index),
            child: ClayContainer(
              margin: EdgeInsets.only(right: index < 6 ? 6 : 0),
              height: 44,
              borderRadius: 12,
              color: isSelected
                  ? themeProvider.primaryColor
                  : themeProvider.surfaceColor,
              emboss: isSelected, // Pressed effect for selected
              child: Center(
                child: Text(
                  dayAbbreviations[index],
                  style: TextStyle(
                    color: isSelected
                        ? themeProvider.textPrimary
                        : themeProvider.textSecondary,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInsetContainer(BuildContext context, {required Widget child}) {
    final themeProvider = context.watch<ThemeProvider>();

    return ClayContainer(
      emboss: true, // Inner shadow for input field
      borderRadius: 12,
      color: themeProvider.surfaceColor,
      child: child,
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
          child: ClayContainer(
            onTap: () => _addItem(context),
            color: themeProvider.surfaceColor,
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.plus, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Add New Item',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: themeProvider.primaryColor,
                  ),
                ),
              ],
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
            Container(
              decoration: BoxDecoration(
                color: themeProvider.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.isDarkMode
                        ? Colors.black.withValues(alpha: 0.5)
                        : Colors.grey.withValues(alpha: 0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: themeProvider.isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white,
                    offset: const Offset(0, -1),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: _titleController,
                style: TextStyle(color: themeProvider.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter habit name',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: themeProvider.textSecondary.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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
                  color: themeProvider.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.isDarkMode
                          ? Colors.black.withValues(alpha: 0.5)
                          : Colors.grey.withValues(alpha: 0.1),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                    BoxShadow(
                      color: themeProvider.isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      offset: const Offset(0, -1),
                      blurRadius: 0,
                    ),
                  ],
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
