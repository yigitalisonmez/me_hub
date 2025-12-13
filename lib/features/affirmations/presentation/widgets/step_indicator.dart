import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';

/// Animated 3-step indicator for Affirmations flow
class StepIndicator extends StatelessWidget {
  final int currentStep; // 0, 1, or 2
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index <= currentStep;
        final isCurrent = index == currentStep;

        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: isCurrent ? 24 : 12,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: isActive
                    ? themeProvider.primaryColor
                    : themeProvider.textSecondary.withValues(alpha: 0.3),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: themeProvider.primaryColor.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
            if (index < totalSteps - 1) const SizedBox(width: 8),
          ],
        );
      }),
    );
  }
}
