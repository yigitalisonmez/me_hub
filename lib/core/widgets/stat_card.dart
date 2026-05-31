import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'elevated_card.dart';

/// Size variants for StatCard
enum StatCardSize { small, medium }

/// A reusable stat card component displaying an icon, value, and label.
///
/// Consolidates the duplicate `_MiniStatCard` implementations across the app.
///
/// Example:
/// ```dart
/// StatCard(
///   icon: LucideIcons.flame,
///   value: '7',
///   label: 'day streak',
///   color: Colors.orange,
/// )
/// ```
class StatCard extends StatelessWidget {
  /// The icon to display
  final IconData icon;

  /// The main value (e.g., "7", "125ml")
  final String value;

  /// The label below the value (e.g., "day streak", "consumed")
  final String label;

  /// The accent color for the icon
  final Color color;

  /// Size variant (small or medium)
  final StatCardSize size;

  /// Optional tap handler
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.size = StatCardSize.small,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final isSmall = size == StatCardSize.small;
    final padding = isSmall
        ? const EdgeInsets.symmetric(vertical: 12, horizontal: 8)
        : const EdgeInsets.all(16);
    final iconSize = isSmall ? 20.0 : 24.0;
    final valueSize = isSmall ? 18.0 : 22.0;
    final labelSize = isSmall ? 11.0 : 13.0;
    final borderRadius = isSmall ? 16.0 : 20.0;

    return ElevatedCard(
      padding: padding,
      borderRadius: borderRadius,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          SizedBox(height: isSmall ? 8 : 10),
          Text(
            value,
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontSize: valueSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmall ? 2 : 4),
          Text(
            label,
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: labelSize,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// A horizontal row of stat cards with equal spacing
class StatCardRow extends StatelessWidget {
  final List<StatCard> cards;
  final double spacing;

  const StatCardRow({super.key, required this.cards, this.spacing = 12});

  @override
  Widget build(BuildContext context) {
    return Row(
      children:
          cards
              .map((card) => Expanded(child: card))
              .toList()
              .expand((widget) => [widget, SizedBox(width: spacing)])
              .toList()
            ..removeLast(), // Remove trailing spacing
    );
  }
}
