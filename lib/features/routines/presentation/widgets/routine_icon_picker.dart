import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/routine_icons.dart';
import '../../../../core/providers/theme_provider.dart';

class RoutineIconPicker extends StatelessWidget {
  final int? selectedIconCodePoint;
  final Function(int iconCodePoint) onIconSelected;

  const RoutineIconPicker({
    super.key,
    this.selectedIconCodePoint,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return SizedBox(
      height: 200,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          direction: Axis.horizontal,
          spacing: 12,
          runSpacing: 12,
          children: RoutineIcons.allIcons.map((iconData) {
            final icon = iconData['icon'] as IconData;
            final isSelected = selectedIconCodePoint == icon.codePoint;

            return GestureDetector(
              onTap: () => onIconSelected(icon.codePoint),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected
                      ? themeProvider.primaryColor.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? themeProvider.primaryColor
                        : themeProvider.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: themeProvider.primaryColor,
                  size: 28,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

