import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';

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
        if (showBackButton)
          Positioned(
            left: 0,
            top: 0,
            child: _HeaderIconButton(
              icon: LucideIcons.chevronLeft,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        if (centerTitle)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: reservedSidePadding),
            child: Center(
              child: _HeaderCopy(
                title: title,
                subtitle: subtitle,
                theme: theme,
                themeProvider: themeProvider,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HeaderCopy(
                  title: title,
                  subtitle: subtitle,
                  theme: theme,
                  themeProvider: themeProvider,
                  textAlign: TextAlign.start,
                ),
              ),
              if (hasAction) ...[
                const SizedBox(width: 12),
                _HeaderIconButton(
                  icon: actionIcon,
                  actionWidget: actionWidget,
                  onTap: onActionTap,
                ),
              ],
            ],
          ),
        if (centerTitle && hasAction)
          Positioned(
            right: 0,
            top: 0,
            child: _HeaderIconButton(
              icon: actionIcon,
              actionWidget: actionWidget,
              onTap: onActionTap,
            ),
          ),
      ],
    );
  }
}

class _HeaderCopy extends StatelessWidget {
  final String title;
  final String subtitle;
  final ThemeData theme;
  final ThemeProvider themeProvider;
  final TextAlign textAlign;

  const _HeaderCopy({
    required this.title,
    required this.subtitle,
    required this.theme,
    required this.themeProvider,
    required this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.displaySmall?.copyWith(
            color: themeProvider.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: themeProvider.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData? icon;
  final Widget? actionWidget;
  final VoidCallback? onTap;

  const _HeaderIconButton({this.icon, this.actionWidget, this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : AppColors.textPrimary.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.28)
                  : const Color(0xFF7C5E42).withValues(alpha: 0.08),
              offset: const Offset(0, 10),
              blurRadius: 24,
              spreadRadius: -12,
            ),
          ],
        ),
        child:
            actionWidget ??
            Icon(icon, color: themeProvider.primaryColor, size: 20),
      ),
    );
  }
}
