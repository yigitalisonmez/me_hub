import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/constants/routine_icons.dart';
import '../../domain/entities/routine.dart';
import '../providers/routines_provider.dart';

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
      await provider.deleteItem(widget.routine.id, item.id);
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

  Future<void> _saveRoutine() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routine name cannot be empty')),
      );
      return;
    }

    final provider = context.read<RoutinesProvider>();
    final updatedRoutine = widget.routine.copyWith(
      name: _nameController.text.trim(),
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
              orElse: () => widget.routine,
            );

            return Column(
              children: [
                // Header section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Edit Routine',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        updatedRoutine.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.darkGrey.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Habits list
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: updatedRoutine.items.length,
                      onReorder: (oldIndex, newIndex) {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        provider.reorderItems(
                          widget.routine.id,
                          oldIndex,
                          newIndex,
                        );
                      },
                      itemBuilder: (context, index) {
                        final item = updatedRoutine.items[index];
                        return _HabitListItem(
                          key: ValueKey(item.id),
                          item: item,
                          index: index,
                          onDelete: () => _confirmDeleteItem(context, item),
                          onEdit: () => _editHabit(context, item),
                        );
                      },
                    ),
                  ),
                ),
                // Bottom buttons section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Add New Item button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Navigate back - user can add items from main page
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            LucideIcons.plus,
                            color: AppColors.primaryOrange,
                          ),
                          label: const Text(
                            'Add New Item',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: AppColors.primaryOrange,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Save Changes button
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryOrange.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _saveRoutine,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Cancel button
                      SizedBox(
                        width: double.infinity,
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGrey.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HabitListItem extends StatelessWidget {
  final RoutineItem item;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _HabitListItem({
    super.key,
    required this.item,
    required this.index,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Drag handle
          ReorderableDragStartListener(
            index: index,
            child: Icon(
              LucideIcons.gripVertical,
              color: AppColors.primaryOrange.withValues(alpha: 0.6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Icon with background
          if (item.iconCodePoint != null)
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryCream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  IconData(item.iconCodePoint!, fontFamily: 'MaterialIcons'),
                  color: AppColors.primaryOrange,
                  size: 24,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryCream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.circle,
                  color: AppColors.primaryOrange.withValues(alpha: 0.5),
                  size: 24,
                ),
              ),
            ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: GestureDetector(
              onTap: onEdit,
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGrey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Delete button
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              LucideIcons.trash2,
              color: Colors.red.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
        ],
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
          _IconPickerDialog(selectedIconCodePoint: _selectedIconCodePoint),
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
                const Text(
                  'Edit Habit',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
            const Text(
              'Habit Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter habit name',
                hintStyle: TextStyle(
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
            const Text(
              'Icon',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
                          IconData(
                            _selectedIconCodePoint!,
                            fontFamily: 'MaterialIcons',
                          ),
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
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
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.darkGrey,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
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
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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

class _IconPickerDialog extends StatefulWidget {
  final int? selectedIconCodePoint;

  const _IconPickerDialog({this.selectedIconCodePoint});

  @override
  State<_IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<_IconPickerDialog> {
  final _searchController = TextEditingController();
  late int? _selectedIconCodePoint;

  @override
  void initState() {
    super.initState();
    _selectedIconCodePoint = widget.selectedIconCodePoint;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredIcons {
    if (_searchController.text.isEmpty) {
      return RoutineIcons.allIcons;
    }
    return RoutineIcons.allIcons
        .where(
          (iconData) => iconData['name'].toString().toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ),
        )
        .toList();
  }

  Widget _buildIconPageView() {
    const iconsPerPage = 30; // 5 rows x 6 columns
    final pageCount = (_filteredIcons.length / iconsPerPage).ceil();

    return PageView.builder(
      itemCount: pageCount,
      itemBuilder: (context, pageIndex) {
        final startIndex = pageIndex * iconsPerPage;
        final endIndex = (startIndex + iconsPerPage).clamp(
          0,
          _filteredIcons.length,
        );
        final pageIcons = _filteredIcons.sublist(startIndex, endIndex);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: pageIcons.length,
          itemBuilder: (context, index) {
            final iconData = pageIcons[index];
            final icon = iconData['icon'] as IconData;
            final isSelected = _selectedIconCodePoint == icon.codePoint;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedIconCodePoint = icon.codePoint;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: AppColors.primaryOrange, width: 2.5)
                      : Border.all(color: Colors.transparent, width: 2.5),
                ),
                child: Icon(icon, color: AppColors.primaryOrange, size: 24),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryOrange, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.layoutGrid,
                        color: AppColors.primaryOrange,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SELECT ICON',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        LucideIcons.layoutGrid,
                        color: AppColors.primaryOrange,
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search input
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search icons...',
                        hintStyle: TextStyle(
                          color: AppColors.darkGrey.withValues(alpha: 0.4),
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          color: AppColors.primaryOrange,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primaryOrange.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primaryOrange.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primaryOrange,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    // Icon grid
                    Expanded(
                      child: _filteredIcons.isEmpty
                          ? Center(
                              child: Text(
                                'No icons found',
                                style: TextStyle(
                                  color: AppColors.darkGrey.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : _buildIconPageView(),
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: AppColors.darkGrey.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.darkGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, _selectedIconCodePoint);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Select',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
