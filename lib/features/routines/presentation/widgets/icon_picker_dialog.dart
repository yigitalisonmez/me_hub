import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/routine_icons.dart';

class IconPickerDialog extends StatefulWidget {
  final int? selectedIconCodePoint;

  const IconPickerDialog({super.key, this.selectedIconCodePoint});

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
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

