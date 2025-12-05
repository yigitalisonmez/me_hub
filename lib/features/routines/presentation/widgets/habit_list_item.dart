import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';

import '../../../../core/constants/routine_icons.dart';
import '../../../../core/widgets/elevated_card.dart';
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

    return ElevatedCard(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 16,
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
          if (item.iconCodePoint != null)
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(12),
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
                child: Icon(
                  RoutineIcons.getIconFromCodePoint(item.iconCodePoint!) ??
                      LucideIcons.circle,
                  color: themeProvider.primaryColor,
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
                child: Icon(
                  LucideIcons.circle,
                  color: themeProvider.primaryColor,
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: themeProvider.textPrimary,
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
              color: const Color(0xFFF44336).withValues(alpha: 0.8),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
