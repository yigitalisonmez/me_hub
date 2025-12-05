import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';

import '../../../../core/constants/routine_icons.dart';
import '../../../../core/widgets/clay_container.dart';
import '../../domain/entities/routine.dart';

class HabitListItem extends StatelessWidget {
  final RoutineItem item;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const HabitListItem({
    super.key,
    required this.item,
    required this.index,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Drag handle icon (visual indicator)
          Icon(
            LucideIcons.gripVertical,
            color: themeProvider.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          // Icon with background
          GestureDetector(
            onTap: onEdit,
            child: ClayContainer(
              width: 48,
              height: 48,
              borderRadius: 12,
              color: themeProvider.surfaceColor,
              child: Center(
                child: Icon(
                  item.iconCodePoint != null
                      ? RoutineIcons.getIconFromCodePoint(
                              item.iconCodePoint!,
                            ) ??
                            LucideIcons.circle
                      : LucideIcons.circle,
                  color: themeProvider.primaryColor,
                  size: 24,
                ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Delete button
          GestureDetector(
            onTap: onDelete,
            child: ClayContainer(
              width: 40,
              height: 40,
              borderRadius: 20,
              color: themeProvider.surfaceColor,
              child: Center(
                child: Icon(
                  LucideIcons.trash2,
                  color: const Color(0xFFF44336).withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
