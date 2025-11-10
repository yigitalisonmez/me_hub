import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../core/constants/water_constants.dart';

class WaterStats extends StatelessWidget {
  final int currentAmount;
  final int goalAmount;
  final int glassCount;

  const WaterStats({
    super.key,
    required this.currentAmount,
    required this.goalAmount,
    required this.glassCount,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = goalAmount - currentAmount;
    final percentage = ((currentAmount / goalAmount) * 100).clamp(0, 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryOrange, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildStatItem(
              Icons.local_drink,
              '$glassCount',
              'Glasses',
              WaterConstants.waterOrange,
            ),
          ),
          Container(
            width: 2,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryOrange.withValues(alpha: 0.1),
                  AppColors.primaryOrange.withValues(alpha: 0.3),
                  AppColors.primaryOrange.withValues(alpha: 0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Expanded(
            child: _buildStatItem(
              Icons.trending_up,
              '$percentage%',
              'Progress',
              WaterConstants.waterPeach,
            ),
          ),
          Container(
            width: 2,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryOrange.withValues(alpha: 0.1),
                  AppColors.primaryOrange.withValues(alpha: 0.3),
                  AppColors.primaryOrange.withValues(alpha: 0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Expanded(
            child: _buildStatItem(
              Icons.flag_outlined,
              '${remaining > 0 ? remaining : 0}ml',
              'Remaining',
              remaining > 0 ? AppColors.primaryOrangeDark : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.2),
                color.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.darkGrey.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

