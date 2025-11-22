import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';
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

  Widget _buildIconPageView(ThemeProvider themeProvider) {
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
                      ? Border.all(
                          color: themeProvider.primaryColor,
                          width: 2.5,
                        )
                      : Border.all(color: Colors.transparent, width: 2.5),
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
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: themeProvider.borderColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: themeProvider.primaryColor.withValues(alpha: 0.1),
              blurRadius: 20,
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
                      Icon(
                        LucideIcons.layoutGrid,
                        color: themeProvider.primaryColor,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SELECT ICON',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.primaryColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.layoutGrid,
                        color: themeProvider.primaryColor,
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    width: 80,
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor,
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
                      style: TextStyle(color: themeProvider.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search icons...',
                        hintStyle: TextStyle(
                          color: themeProvider.textSecondary,
                        ),
                        filled: true,
                        fillColor: themeProvider.surfaceColor,
                        prefixIcon: Icon(
                          LucideIcons.search,
                          color: themeProvider.primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: themeProvider.borderColor.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: themeProvider.borderColor.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: themeProvider.borderColor,
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
                                  color: themeProvider.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : _buildIconPageView(themeProvider),
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, _selectedIconCodePoint);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: themeProvider.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Select',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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

