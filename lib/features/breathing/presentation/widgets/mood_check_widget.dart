import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../providers/breathing_provider.dart';

/// Widget for mood check before/after breathing session
class MoodCheckWidget extends StatelessWidget {
  final bool isBefore;
  final void Function(int mood) onMoodSelected;
  final VoidCallback? onSkip;

  const MoodCheckWidget({
    super.key,
    required this.isBefore,
    required this.onMoodSelected,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<BreathingProvider>();

    final techniqueColor =
        provider.selectedTechnique?.primaryColor ?? const Color(0xFF4DB6AC);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: techniqueColor.withValues(alpha: 0.15),
              ),
              child: Icon(
                isBefore ? LucideIcons.heartPulse : LucideIcons.sparkles,
                color: techniqueColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 32),

            // Question
            Text(
              isBefore
                  ? 'How are you feeling right now?'
                  : 'How do you feel after the exercise?',
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isBefore ? 'Rate your mood before starting' : 'Rate the change',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Mood options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MoodOption(
                  emoji: '😰',
                  label: 'Stressed',
                  value: 1,
                  color: const Color(0xFFE57373),
                  onTap: () => onMoodSelected(1),
                ),
                _MoodOption(
                  emoji: '😟',
                  label: 'Anxious',
                  value: 2,
                  color: const Color(0xFFFFB74D),
                  onTap: () => onMoodSelected(2),
                ),
                _MoodOption(
                  emoji: '😐',
                  label: 'Neutral',
                  value: 3,
                  color: const Color(0xFF90A4AE),
                  onTap: () => onMoodSelected(3),
                ),
                _MoodOption(
                  emoji: '🙂',
                  label: 'Good',
                  value: 4,
                  color: const Color(0xFF81C784),
                  onTap: () => onMoodSelected(4),
                ),
                _MoodOption(
                  emoji: '😌',
                  label: 'Relaxed',
                  value: 5,
                  color: const Color(0xFF4DB6AC),
                  onTap: () => onMoodSelected(5),
                ),
              ],
            ),

            // Skip button for after mood check
            if (!isBefore && onSkip != null) ...[
              const SizedBox(height: 32),
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: themeProvider.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoodOption extends StatelessWidget {
  final String emoji;
  final String label;
  final int value;
  final Color color;
  final VoidCallback onTap;

  const _MoodOption({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
