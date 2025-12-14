import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../providers/breathing_provider.dart';

/// Session complete widget showing stats and mood improvement
class SessionCompleteWidget extends StatelessWidget {
  final VoidCallback onClose;

  const SessionCompleteWidget({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<BreathingProvider>();

    final techniqueColor =
        provider.selectedTechnique?.primaryColor ?? const Color(0xFF4DB6AC);

    // Get the most recent session
    final lastSession = provider.sessionHistory.isNotEmpty
        ? provider.sessionHistory.first
        : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF81C784).withValues(alpha: 0.2),
              ),
              child: const Icon(
                LucideIcons.check,
                color: Color(0xFF81C784),
                size: 48,
              ),
            ),
            const SizedBox(height: 32),

            // Congratulations message
            Text(
              'Great job! 🎉',
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You completed the breathing exercise',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 40),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  icon: LucideIcons.repeat,
                  value: '${lastSession?.cyclesCompleted ?? 0}',
                  label: 'Cycles',
                  color: techniqueColor,
                ),
                _StatItem(
                  icon: LucideIcons.clock,
                  value: lastSession?.formattedDuration ?? '0s',
                  label: 'Duration',
                  color: const Color(0xFF42A5F5),
                ),
                _StatItem(
                  icon: LucideIcons.flame,
                  value: '${provider.currentStreak}',
                  label: 'Day Streak',
                  color: const Color(0xFFFF7043),
                ),
              ],
            ),

            // Mood improvement (if both moods recorded)
            if (lastSession?.moodBefore != null &&
                lastSession?.moodAfter != null) ...[
              const SizedBox(height: 32),
              _MoodComparisonCard(
                moodBefore: lastSession!.moodBefore!,
                moodAfter: lastSession.moodAfter!,
              ),
            ],

            const SizedBox(height: 40),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: techniqueColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: themeProvider.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: themeProvider.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _MoodComparisonCard extends StatelessWidget {
  final int moodBefore;
  final int moodAfter;

  const _MoodComparisonCard({
    required this.moodBefore,
    required this.moodAfter,
  });

  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😰';
      case 2:
        return '😟';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😌';
      default:
        return '😐';
    }
  }

  String _getMoodLabel(int mood) {
    switch (mood) {
      case 1:
        return 'Stressed';
      case 2:
        return 'Anxious';
      case 3:
        return 'Neutral';
      case 4:
        return 'Good';
      case 5:
        return 'Relaxed';
      default:
        return 'Neutral';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final improvement = moodAfter - moodBefore;
    final improvementPercent = (improvement * 25).clamp(-100, 100);

    return ElevatedCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Before
              Column(
                children: [
                  Text(
                    _getMoodEmoji(moodBefore),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Before',
                    style: TextStyle(
                      color: themeProvider.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _getMoodLabel(moodBefore),
                    style: TextStyle(
                      color: themeProvider.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Arrow
              Icon(
                LucideIcons.arrowRight,
                color: improvement > 0
                    ? const Color(0xFF81C784)
                    : improvement < 0
                    ? const Color(0xFFE57373)
                    : themeProvider.textSecondary,
                size: 24,
              ),

              // After
              Column(
                children: [
                  Text(
                    _getMoodEmoji(moodAfter),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'After',
                    style: TextStyle(
                      color: themeProvider.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _getMoodLabel(moodAfter),
                    style: TextStyle(
                      color: themeProvider.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (improvement != 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: improvement > 0
                    ? const Color(0xFF81C784).withValues(alpha: 0.15)
                    : const Color(0xFFE57373).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                improvement > 0
                    ? '$improvementPercent% better!'
                    : 'Next session will be even better!',
                style: TextStyle(
                  color: improvement > 0
                      ? const Color(0xFF81C784)
                      : const Color(0xFFE57373),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
