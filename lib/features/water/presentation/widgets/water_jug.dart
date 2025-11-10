import 'package:flutter/material.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../core/constants/water_constants.dart';

class WaterJug extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int currentAmount;
  final int goalAmount;

  const WaterJug({
    super.key,
    required this.progress,
    required this.currentAmount,
    required this.goalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular liquid progress indicator
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, child) {
              return SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Liquid circular progress
                    LiquidCircularProgressIndicator(
                      value: animatedProgress.clamp(0.0, 1.0),
                      backgroundColor: AppColors.secondaryCream,
                      valueColor: AlwaysStoppedAnimation(
                        WaterConstants.waterOrangeLight,
                      ),
                      borderColor: AppColors.primaryOrange,
                      borderWidth: 8.0,
                      direction: Axis.vertical,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(animatedProgress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: animatedProgress > 0.5
                                  ? AppColors.white
                                  : AppColors.primaryOrange,
                              shadows: animatedProgress > 0.5
                                  ? [
                                      Shadow(
                                        color: AppColors.primaryOrangeDark.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.water_drop,
                            color: animatedProgress > 0.5
                                ? AppColors.white.withValues(alpha: 0.9)
                                : AppColors.primaryOrange.withValues(alpha: 0.8),
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Amount display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: WaterConstants.waterGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '$currentAmount ml / $goalAmount ml',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

