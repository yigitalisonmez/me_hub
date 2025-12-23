import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// A reusable section header with title, optional action, and divider.
///
/// Provides consistent section title styling across the app.
///
/// Example:
/// ```dart
/// SectionHeader(
///   title: 'Productivity',
///   action: TextButton(
///     child: Text('See all'),
///     onPressed: () => ...,
///   ),
/// )
/// ```
class SectionHeader extends StatelessWidget {
  /// The section title text
  final String title;

  /// Optional action widget (typically a TextButton)
  final Widget? action;

  /// Whether to show a divider below the title
  final bool showDivider;

  /// Horizontal padding
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.showDivider = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: themeProvider.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              if (action != null) action!,
            ],
          ),
          if (showDivider)
            Divider(
              height: 20,
              thickness: 0.5,
              color: themeProvider.isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
            ),
        ],
      ),
    );
  }
}

/// A section header with a colored accent bar
class AccentSectionHeader extends StatelessWidget {
  final String title;
  final Color accentColor;
  final Widget? action;

  const AccentSectionHeader({
    super.key,
    required this.title,
    required this.accentColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (action != null) action!,
        ],
      ),
    );
  }
}
