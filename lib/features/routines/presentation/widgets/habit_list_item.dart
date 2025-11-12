import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/routine_icons.dart';
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
    return Material(
      key: key,
      color: AppColors.white,
      elevation: 0.5,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primaryOrange.withValues(alpha: 0.25),
            width: 0.75,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Drag handle icon (visual indicator)
            Icon(
              LucideIcons.gripVertical,
              color: AppColors.primaryOrange,
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
                    color: AppColors.secondaryCream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    RoutineIcons.getIconFromCodePoint(item.iconCodePoint!) ??
                        LucideIcons.circle,
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
                    color: AppColors.primaryOrange,
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
                color: const Color(0xFFF44336).withValues(alpha: 0.8),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
