import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? actionIcon;
  final VoidCallback? onActionTap;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionIcon,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.displaySmall?.copyWith(
                color: themeProvider.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: themeProvider.textSecondary,
              ),
            ),
          ],
        ),
        if (actionIcon != null)
          GestureDetector(
            onTap: onActionTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: themeProvider.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeProvider.isDarkMode 
                      ? Colors.white.withValues(alpha: 0.05) 
                      : Colors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.isDarkMode 
                        ? Colors.white.withValues(alpha: 0.02) 
                        : Colors.white,
                    offset: const Offset(0, -1),
                    blurRadius: 2,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: themeProvider.isDarkMode 
                        ? Colors.black.withValues(alpha: 0.2) 
                        : themeProvider.primaryColor.withValues(alpha: 0.05),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: Icon(
                actionIcon,
                color: themeProvider.primaryColor,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }
}
