import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';

class RoutineDaysSelector extends StatelessWidget {
  final List<int> selectedDays;
  final Function(List<int> days) onDaysChanged;

  const RoutineDaysSelector({
    super.key,
    required this.selectedDays,
    required this.onDaysChanged,
  });

  static const List<Map<String, dynamic>> daysOfWeek = [
    {'name': 'Monday', 'abbr': 'M', 'index': 0},
    {'name': 'Tuesday', 'abbr': 'T', 'index': 1},
    {'name': 'Wednesday', 'abbr': 'W', 'index': 2},
    {'name': 'Thursday', 'abbr': 'T', 'index': 3},
    {'name': 'Friday', 'abbr': 'F', 'index': 4},
    {'name': 'Saturday', 'abbr': 'S', 'index': 5},
    {'name': 'Sunday', 'abbr': 'S', 'index': 6},
  ];

  void _toggleDay(int dayIndex) {
    final newDays = List<int>.from(selectedDays);
    if (newDays.contains(dayIndex)) {
      newDays.remove(dayIndex);
    } else {
      newDays.add(dayIndex);
    }
    onDaysChanged(newDays);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      children: daysOfWeek.map((dayData) {
        final dayIndex = dayData['index'] as int;
        final isSelected = selectedDays.contains(dayIndex);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _toggleDay(dayIndex),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? themeProvider.primaryColor
                    : themeProvider.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? themeProvider.primaryColor
                      : themeProvider.borderColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? themeProvider.textPrimary.withValues(alpha: 0.2)
                          : themeProvider.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        dayData['abbr'] as String,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isSelected
                              ? themeProvider.textPrimary
                              : themeProvider.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      dayData['name'] as String,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? themeProvider.textPrimary
                            : themeProvider.textPrimary,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      LucideIcons.check,
                      color: themeProvider.textPrimary,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

