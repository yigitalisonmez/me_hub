import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/routine_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';

class IconPickerDialog extends StatefulWidget {
  final int? selectedIconCodePoint;
  final Color accentColor;

  const IconPickerDialog({
    super.key,
    this.selectedIconCodePoint,
    this.accentColor = AppColors.routineDeep,
  });

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
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return RoutineIcons.allIcons;

    return RoutineIcons.allIcons.where((iconData) {
      return iconData['name'].toString().toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accent = widget.accentColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.76,
        ),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: themeProvider.borderColor.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: themeProvider.isDarkMode ? 0.35 : 0.12,
              ),
              blurRadius: 34,
              offset: const Offset(0, 18),
              spreadRadius: -14,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PickerHeader(
                selectedIconCodePoint: _selectedIconCodePoint,
                accent: accent,
                onClose: () => Navigator.of(context).pop(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _SearchField(
                  controller: _searchController,
                  accent: accent,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: _filteredIcons.isEmpty
                    ? _EmptyIconsState(accent: accent)
                    : _IconGrid(
                        icons: _filteredIcons,
                        selectedIconCodePoint: _selectedIconCodePoint,
                        accent: accent,
                        onSelected: (codePoint) {
                          setState(() => _selectedIconCodePoint = codePoint);
                        },
                      ),
              ),
              _PickerActions(
                accent: accent,
                onCancel: () => Navigator.of(context).pop(),
                onSelect: () =>
                    Navigator.of(context).pop(_selectedIconCodePoint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerHeader extends StatelessWidget {
  final int? selectedIconCodePoint;
  final Color accent;
  final VoidCallback onClose;

  const _PickerHeader({
    required this.selectedIconCodePoint,
    required this.accent,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final selectedIcon = selectedIconCodePoint == null
        ? LucideIcons.circleCheck
        : RoutineIcons.getIconFromCodePoint(selectedIconCodePoint!) ??
              LucideIcons.circleCheck;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _accentTint(themeProvider, accent),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(selectedIcon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select icon',
                  style: TextStyle(
                    color: themeProvider.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Choose a symbol for this step',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: themeProvider.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: themeProvider.surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: themeProvider.borderColor.withValues(alpha: 0.24),
                ),
              ),
              child: Icon(
                LucideIcons.x,
                color: themeProvider.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final Color accent;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return TextField(
      controller: controller,
      style: TextStyle(
        color: themeProvider.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'Search icons',
        hintStyle: TextStyle(
          color: themeProvider.textTertiary,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: themeProvider.inputFillColor,
        prefixIcon: Icon(LucideIcons.search, color: accent, size: 18),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(
            color: themeProvider.borderColor.withValues(alpha: 0.28),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(
            color: themeProvider.borderColor.withValues(alpha: 0.28),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(color: accent, width: 1.6),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _IconGrid extends StatelessWidget {
  final List<Map<String, dynamic>> icons;
  final int? selectedIconCodePoint;
  final Color accent;
  final ValueChanged<int> onSelected;

  const _IconGrid({
    required this.icons,
    required this.selectedIconCodePoint,
    required this.accent,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 380 ? 5 : 6;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            childAspectRatio: 1,
          ),
          itemCount: icons.length,
          itemBuilder: (context, index) {
            final iconData = icons[index];
            final icon = iconData['icon'] as IconData;
            final isSelected = selectedIconCodePoint == icon.codePoint;

            return _IconTile(
              icon: icon,
              selected: isSelected,
              accent: accent,
              onTap: () => onSelected(icon.codePoint),
            );
          },
        );
      },
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _IconTile({
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? accent : themeProvider.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : themeProvider.borderColor.withValues(alpha: 0.22),
            width: 1.3,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.26),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    spreadRadius: -8,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : themeProvider.textSecondary,
              size: 22,
            ),
            if (selected)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.check, color: accent, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyIconsState extends StatelessWidget {
  final Color accent;

  const _EmptyIconsState({required this.accent});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.searchX, color: accent, size: 28),
          const SizedBox(height: 10),
          Text(
            'No icons found',
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerActions extends StatelessWidget {
  final Color accent;
  final VoidCallback onCancel;
  final VoidCallback onSelect;

  const _PickerActions({
    required this.accent,
    required this.onCancel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        border: Border(
          top: BorderSide(
            color: themeProvider.borderColor.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: themeProvider.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: themeProvider.borderColor.withValues(alpha: 0.34),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Select',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _accentTint(ThemeProvider themeProvider, Color accent) {
  if (themeProvider.isDarkMode) {
    return Color.alphaBlend(
      accent.withValues(alpha: 0.18),
      themeProvider.cardColor,
    );
  }
  return Color.alphaBlend(accent.withValues(alpha: 0.15), AppColors.surface);
}
