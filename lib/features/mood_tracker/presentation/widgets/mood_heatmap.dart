import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../domain/entities/mood_entry.dart';
import '../providers/mood_provider.dart';

class MoodHeatMap extends StatelessWidget {
  const MoodHeatMap({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final moodProvider = context.watch<MoodProvider>();

    // Get last 28 days of data (4x7 grid)
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 27));

    // Create a map of dates to mood entries
    final moodMap = <DateTime, MoodEntry>{};
    for (final mood in moodProvider.allMoods) {
      final normalizedDate = mood.normalizedDate;
      if (normalizedDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          normalizedDate.isBefore(today.add(const Duration(days: 1)))) {
        moodMap[normalizedDate] = mood;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Center the title to align with grid's first cell
          Center(
            child: SizedBox(
              width: (32 + 8) * 7, // cell width + margin * columns
              child: Text(
                'Mood History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: themeProvider.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 4x7 Grid (4 rows, 7 columns)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (rowIndex) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(7, (colIndex) {
                    final dayIndex = rowIndex * 7 + colIndex;
                    final date = startDate.add(Duration(days: dayIndex));
                    final normalizedDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                    );
                    final mood = moodMap[normalizedDate];
                    final isToday =
                        normalizedDate.year == today.year &&
                        normalizedDate.month == today.month &&
                        normalizedDate.day == today.day;

                    return _buildDayCell(
                      context,
                      themeProvider,
                      date,
                      mood,
                      isToday,
                    );
                  }),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(context, themeProvider),
        ],
      ),
    );
  }

  /// Get color for mood score (1-10) using gradient scale
  /// 1-5: Red to White
  /// 5-10: White to Dark Green
  Color _getColorForScore(int score) {
    if (score <= 5) {
      // 1-5: Red to White
      final normalized = (score - 1) / 4.0; // 0.0 to 1.0 for scores 1-5
      return Color.lerp(
        const Color.fromARGB(255, 66, 24, 24), // Red
        Colors.white,
        normalized,
      )!;
    } else {
      // 5-10: White to Dark Green
      final normalized = (score - 5) / 5.0; // 0.0 to 1.0 for scores 5-10
      return Color.lerp(
        Colors.white,
        const Color(0xFF15803D), // Dark Green
        normalized,
      )!;
    }
  }

  Widget _buildDayCell(
    BuildContext context,
    ThemeProvider themeProvider,
    DateTime date,
    MoodEntry? mood,
    bool isToday,
  ) {
    Color cellColor;
    if (mood != null) {
      cellColor = _getColorForScore(mood.score);
    } else {
      cellColor = themeProvider.surfaceColor;
    }

    return GestureDetector(
      onTap: mood != null
          ? () => _showMoodDetails(context, mood, themeProvider)
          : null,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(9),
        ),
      ),
    );
  }

  void _showMoodDetails(
    BuildContext context,
    MoodEntry mood,
    ThemeProvider themeProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: themeProvider.borderColor, width: 2),
        ),
        title: Text(
          'Mood Entry',
          style: TextStyle(
            color: themeProvider.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getColorForScore(mood.score),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${mood.score}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Score: ${mood.score}/10',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Date: ${_formatDate(mood.date)}',
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: themeProvider.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildLegend(BuildContext context, ThemeProvider themeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Less',
          style: TextStyle(fontSize: 12, color: themeProvider.textSecondary),
        ),
        const SizedBox(width: 8),
        // Gradient legend showing color scale (Red to White to Dark Green)
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFDC2626), // Red
                  Colors.white, // White
                  Color(0xFF15803D), // Dark Green
                ],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'More',
          style: TextStyle(fontSize: 12, color: themeProvider.textSecondary),
        ),
      ],
    );
  }
}
