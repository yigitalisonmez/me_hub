import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/routine_icons.dart';
import '../../../../core/theme/app_colors.dart';

class AddItemDialog extends StatefulWidget {
  final Function(String title, int? iconCodePoint) onAdd;

  const AddItemDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _titleController = TextEditingController();
  final _searchController = TextEditingController();
  int? _selectedIconCodePoint;

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredIcons {
    if (_searchController.text.isEmpty) {
      return RoutineIcons.allIcons;
    }
    return RoutineIcons.allIcons
        .where(
          (iconData) => iconData['name']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()),
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
        final endIndex = (startIndex + iconsPerPage).clamp(0, _filteredIcons.length);
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
                      ? Border.all(
                          color: AppColors.primaryOrange,
                          width: 2.5,
                        )
                      : Border.all(
                          color: Colors.transparent,
                          width: 2.5,
                        ),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryOrange,
                  size: 24,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(
        child: Text(
          'Add New Habit',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Habit name',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                ),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.pencil),
              ),
            ),
            const SizedBox(height: 16),
            // Search input
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search icons...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                ),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            // Icon horizontal scroll with pages (5 rows per page)
            Expanded(
              child: _filteredIcons.isEmpty
                  ? const Center(child: Text('No icons found'))
                  : _buildIconPageView(),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: () {
            if (_titleController.text.trim().isNotEmpty) {
              widget.onAdd(_titleController.text.trim(), _selectedIconCodePoint);
              Navigator.pop(context);
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.white,
            backgroundColor: AppColors.primaryOrange,
            side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

