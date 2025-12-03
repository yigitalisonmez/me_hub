import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';

class RoutineTimePicker extends StatelessWidget {
  final TimeOfDay? selectedTime;
  final Function(TimeOfDay time) onTimeSelected;

  const RoutineTimePicker({
    super.key,
    this.selectedTime,
    required this.onTimeSelected,
  });

  static const List<Map<String, dynamic>> predefinedTimes = [
    {
      'label': 'Early Morning',
      'hour': 6,
      'minute': 0,
      'icon': LucideIcons.sunrise,
    },
    {'label': 'Morning', 'hour': 8, 'minute': 0, 'icon': LucideIcons.sun},
    {'label': 'Noon', 'hour': 12, 'minute': 0, 'icon': LucideIcons.cloudSun},
    {'label': 'Afternoon', 'hour': 15, 'minute': 0, 'icon': LucideIcons.sun},
    {'label': 'Evening', 'hour': 18, 'minute': 0, 'icon': LucideIcons.sunset},
    {'label': 'Night', 'hour': 21, 'minute': 0, 'icon': LucideIcons.moon},
  ];

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showCustomTimePicker(BuildContext context) async {
    final themeProvider = context.read<ThemeProvider>();
    final initialTime = selectedTime ?? const TimeOfDay(hour: 8, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: themeProvider.primaryColor,
              onPrimary: themeProvider.textPrimary,
              surface: themeProvider.cardColor,
              onSurface: themeProvider.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final currentTime = selectedTime ?? const TimeOfDay(hour: 8, minute: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current time display - now tappable
        Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showCustomTimePicker(context),
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  color: themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: themeProvider.borderColor,
                    width: 1.5,
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        color: themeProvider.primaryColor,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatTime(currentTime),
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: themeProvider.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getTimeLabel(currentTime),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: themeProvider.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Predefined times
        ...predefinedTimes.map((timeData) {
          final time = TimeOfDay(
            hour: timeData['hour'] as int,
            minute: timeData['minute'] as int,
          );
          final isSelected =
              selectedTime != null &&
              selectedTime!.hour == time.hour &&
              selectedTime!.minute == time.minute;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => onTimeSelected(time),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
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
                    Icon(
                      timeData['icon'] as IconData,
                      color: isSelected
                          ? themeProvider.textPrimary
                          : themeProvider.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeData['label'] as String,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: isSelected
                                      ? themeProvider.textPrimary
                                      : themeProvider.textPrimary,
                                ),
                          ),
                          Text(
                            _formatTime(time),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isSelected
                                      ? themeProvider.textPrimary.withValues(
                                          alpha: 0.7,
                                        )
                                      : themeProvider.textSecondary,
                                ),
                          ),
                        ],
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
        }),
        const SizedBox(height: 12),
        // Custom time button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showCustomTimePicker(context),
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                color: themeProvider.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeProvider.borderColor, width: 1),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.clock,
                      color: themeProvider.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Custom Time',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: themeProvider.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeLabel(TimeOfDay time) {
    final predefined = predefinedTimes.firstWhere(
      (pt) => pt['hour'] == time.hour && pt['minute'] == time.minute,
      orElse: () => {},
    );
    return predefined['label'] as String? ?? 'Custom';
  }
}
