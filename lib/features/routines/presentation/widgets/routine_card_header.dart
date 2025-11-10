import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/routines_provider.dart';

class RoutineCardHeader extends StatelessWidget {
  final RoutinesProvider provider;

  const RoutineCardHeader({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final totalRoutines = provider.routines.length;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    int totalItemsToday = 0;
    int completedItemsToday = 0;

    for (final routine in provider.routines) {
      for (final item in routine.items) {
        totalItemsToday++;
        if (item.isCheckedToday(normalizedToday)) {
          completedItemsToday++;
        }
      }
    }

    final dateStr = DateFormat('EEEE, MMMM d').format(today);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📋 ROUTINES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryOrange,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.darkGrey.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Routines',
                  totalRoutines.toString(),
                  Icons.repeat,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.primaryOrange.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  'Today',
                  '$completedItemsToday/$totalItemsToday',
                  Icons.task_alt,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.darkGrey,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.darkGrey.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

