import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/routine_icons.dart';
import '../../../../core/providers/theme_provider.dart';

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

  Widget _buildIconPageView(ThemeProvider themeProvider) {
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
                          color: themeProvider.primaryColor,
                          width: 2.5,
                        )
                      : Border.all(
                          color: Colors.transparent,
                          width: 2.5,
                        ),
                ),
                child: Icon(
                  icon,
                  color: themeProvider.primaryColor,
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
    final themeProvider = context.watch<ThemeProvider>();
    
    return AlertDialog(
      backgroundColor: themeProvider.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: themeProvider.borderColor,
          width: 2,
        ),
      ),
      title: Center(
        child: Text(
          'Add New Habit',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeProvider.textPrimary,
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
              style: TextStyle(color: themeProvider.textPrimary),
              decoration: InputDecoration(
                hintText: 'Habit name',
                hintStyle: TextStyle(
                  color: themeProvider.textSecondary,
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
                prefixIcon: Icon(
                  LucideIcons.pencil,
                  color: themeProvider.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Search input
            TextField(
              controller: _searchController,
              style: TextStyle(color: themeProvider.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search icons...',
                hintStyle: TextStyle(
                  color: themeProvider.textSecondary,
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
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: themeProvider.primaryColor,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            // Icon horizontal scroll with pages (5 rows per page)
            Expanded(
              child: _filteredIcons.isEmpty
                  ? Center(
                      child: Text(
                        'No icons found',
                        style: TextStyle(color: themeProvider.textSecondary),
                      ),
                    )
                  : _buildIconPageView(themeProvider),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isNotEmpty) {
              widget.onAdd(_titleController.text.trim(), _selectedIconCodePoint);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: themeProvider.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Add',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

