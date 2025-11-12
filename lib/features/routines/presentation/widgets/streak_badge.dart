import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

class StreakBadge extends StatelessWidget {
  final int count;

  const StreakBadge({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryOrange.withValues(alpha: 0.15),
            AppColors.primaryOrange.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.flame,
            color: AppColors.primaryOrange,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

