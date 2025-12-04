import 'package:flutter/material.dart';

class MeHubWidget extends StatelessWidget {
  final int waterIntake;
  final int waterGoal;
  final String moodEmoji;
  final String moodLabel;

  const MeHubWidget({
    super.key,
    required this.waterIntake,
    required this.waterGoal,
    required this.moodEmoji,
    required this.moodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (waterIntake / waterGoal).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark background
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF333333), width: 2),
      ),
      child: Row(
        children: [
          // Water Section
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop, color: Colors.blue[400], size: 28),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${waterIntake}ml',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, color: const Color(0xFF333333)),
          // Mood Section
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  moodEmoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 4),
                Text(
                  moodLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
