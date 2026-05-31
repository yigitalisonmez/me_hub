import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/theme_provider.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? actionIcon;
  final Widget? actionWidget;
  final VoidCallback? onActionTap;
  final bool showBackButton;
  final bool centerTitle;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionIcon,
    this.actionWidget,
    this.onActionTap,
    this.showBackButton = false,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final hasAction = actionIcon != null || actionWidget != null;
    final reservedSidePadding = showBackButton || hasAction ? 56.0 : 0.0;

    return Stack(
      children: [
        // Back button on the left
        if (showBackButton)
          Positioned(
            left: 0,
            top: 0,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
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
                  LucideIcons.chevronLeft,
                  color: themeProvider.primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),
        // Title and subtitle
        if (centerTitle)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: reservedSidePadding),
            child: Center(
              child: Column(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: themeProvider.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: themeProvider.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: themeProvider.primaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: themeProvider.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasAction) ...[
                const SizedBox(width: 12),
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
                              : themeProvider.primaryColor.withValues(
                                  alpha: 0.05,
                                ),
                          offset: const Offset(0, 3),
                          blurRadius: 6,
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                    child:
                        actionWidget ??
                        Icon(
                          actionIcon,
                          color: themeProvider.primaryColor,
                          size: 20,
                        ),
                  ),
                ),
              ],
            ],
          ),
        // Action button on the right (only when centerTitle is true)
        if (centerTitle && hasAction)
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
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
                child:
                    actionWidget ??
                    Icon(
                      actionIcon,
                      color: themeProvider.primaryColor,
                      size: 20,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}
