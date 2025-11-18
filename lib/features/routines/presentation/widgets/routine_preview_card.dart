import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/routine_icons.dart';
import '../../../../core/providers/theme_provider.dart';

class RoutinePreviewCard extends StatelessWidget {
  final String name;
  final int? iconCodePoint;
  final TimeOfDay? time;

  const RoutinePreviewCard({
    super.key,
    required this.name,
    this.iconCodePoint,
    this.time,
  });

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final icon = iconCodePoint != null
        ? RoutineIcons.getIconFromCodePoint(iconCodePoint!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.borderColor,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeProvider.primaryColor,
                width: 2,
              ),
            ),
            child: Icon(
              icon ?? LucideIcons.circle,
              color: themeProvider.primaryColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            name.isEmpty ? 'Routine Name' : name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: themeProvider.textPrimary,
            ),
          ),
          // Time
          if (time != null) ...[
            const SizedBox(height: 8),
            Text(
              _formatTime(time!),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: themeProvider.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

