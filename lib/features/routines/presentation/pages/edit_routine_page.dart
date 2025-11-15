import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
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
      debugPrint(
        '_confirmDeleteItem: Deleting item ${item.id} from routine ${widget.routine.id}',
      );
      try {
        await provider.deleteItem(widget.routine.id, item.id);
        debugPrint('_confirmDeleteItem: Delete completed');
      } catch (e, stackTrace) {
        debugPrint('_confirmDeleteItem error: $e');
        debugPrint('Stack trace: $stackTrace');
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
    final currentRoutine = provider.routines.firstWhere(
      (r) => r.id == widget.routine.id,
      orElse: () => widget.routine,
    );

    await showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        onAdd: (title, iconCodePoint) async {
          final item = RoutineItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title,
            iconCodePoint: iconCodePoint,
          );
          await provider.addItem(currentRoutine.id, item);
        },
      ),
    );
  }

  Future<void> _saveRoutine() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routine name cannot be empty')),
      );
      return;
    }

    final provider = context.read<RoutinesProvider>();

    // Get the current routine from provider (not widget.routine which is stale)
    final currentRoutine = provider.routines.firstWhere(
      (r) => r.id == widget.routine.id,
      orElse: () => widget.routine,
    );

    final updatedRoutine = currentRoutine.copyWith(
      name: _nameController.text.trim(),
    );

    debugPrint(
      '_saveRoutine: Saving routine with ${updatedRoutine.items.length} items',
    );
    await provider.updateRoutine(updatedRoutine);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Consumer<RoutinesProvider>(
          builder: (context, provider, _) {
            final updatedRoutine = provider.routines.firstWhere(
              (r) => r.id == widget.routine.id,
              orElse: () {
                debugPrint(
                  'EditRoutinePage: Routine not found in provider, using widget.routine',
                );
                return widget.routine;
              },
            );
            debugPrint(
              'EditRoutinePage: Consumer rebuild - routine has ${updatedRoutine.items.length} items',
            );

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
    );
  }

  Widget _buildHeader(BuildContext context, Routine routine) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.7],
          colors: [
            Color(0xFFFFE8D6), // Açık turuncu/krem - header'ın başı
            AppColors.backgroundCream, // Header'ın ortası - sayfa rengi
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back button (circular, white background)
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: AppColors.primaryOrange,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // Save button (circular, orange background)
        Container(
          decoration: BoxDecoration(
            color: AppColors.primaryOrange,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.check, color: Colors.white, size: 20),
            onPressed: _saveRoutine,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(Routine routine) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
        color: AppColors.primaryOrange,
        size: 28,
      ),
    );
  }

  Widget _buildHeaderTitle(BuildContext context) {
    return Text(
      'Edit Routine',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: AppColors.primaryOrange,
      ),
    );
  }

  Widget _buildRoutineNameBadge(BuildContext context, Routine routine) {
    final theme = Theme.of(context);
    return Material(
      elevation: 0.5,
      borderRadius: BorderRadius.circular(100),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primaryOrange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              routine.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.darkGrey.withValues(alpha: 0.7),
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
    debugPrint(
      '_buildHabitsList: Building list with ${routine.items.length} items',
    );
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
          final item = routine.items[index];
          return Material(
            color: Colors.white,
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _addItem(context),
            icon: const Icon(LucideIcons.plus, color: AppColors.primaryOrange),
            label: Text(
              'Add New Item',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primaryOrange,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.primaryOrange, width: 2),
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.only(
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
                const Icon(
                  LucideIcons.pencilLine,
                  color: AppColors.primaryOrange,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Edit Habit',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.pencilLine,
                  color: AppColors.primaryOrange,
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
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Title field
            Text(
              'Habit Name',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter habit name',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkGrey.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primaryOrange.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primaryOrange.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryOrange,
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
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickIcon,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    if (_selectedIconCodePoint != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryCream,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          RoutineIcons.getIconFromCodePoint(
                                _selectedIconCodePoint!,
                              ) ??
                              LucideIcons.circle,
                          color: AppColors.primaryOrange,
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
                        color: AppColors.darkGrey.withValues(alpha: 0.7),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: AppColors.darkGrey.withValues(alpha: 0.4),
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
                        color: AppColors.darkGrey.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOrange.withValues(alpha: 0.3),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
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
