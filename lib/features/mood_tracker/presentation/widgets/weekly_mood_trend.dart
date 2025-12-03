import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/mood_provider.dart';
import '../utils/mood_utils.dart';

class WeeklyMoodTrend extends StatelessWidget {
  const WeeklyMoodTrend({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final moodProvider = context.watch<MoodProvider>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Generate last 7 days (including today)
    final days = List.generate(7, (index) {
      return today.subtract(Duration(days: 6 - index));
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeProvider.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((date) {
              final mood = moodProvider.getMoodForDate(date);
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              
              return _DayItem(
                date: date,
                score: mood?.score,
                isToday: isToday,
                themeProvider: themeProvider,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DayItem extends StatelessWidget {
  final DateTime date;
  final int? score;
  final bool isToday;
  final ThemeProvider themeProvider;

  const _DayItem({
    required this.date,
    required this.score,
    required this.isToday,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('E').format(date)[0]; // First letter of day
    final color = score != null 
        ? MoodUtils.getColorForScore(score!) 
        : themeProvider.borderColor;

    return Column(
      children: [
        Text(
          dayName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday 
                ? themeProvider.primaryColor 
                : themeProvider.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: score != null ? color : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: score != null ? color : themeProvider.borderColor,
              width: 2,
            ),
            boxShadow: score != null && isToday
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: score != null
              ? Center(
                  child: Text(
                    score.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
