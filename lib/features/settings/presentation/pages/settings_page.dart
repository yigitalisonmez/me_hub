import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/voice_settings_provider.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/reminders/presentation/reminder_settings_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/app_route.dart';
import 'reminder_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final voiceSettings = context.watch<VoiceSettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const PageHeader(
                title: 'Settings',
                subtitle: 'Preferences for your local Kora',
                showBackButton: true,
              ),
              const SizedBox(height: 24),
              _SettingsSectionLabel(
                label: 'Reminders',
                themeProvider: themeProvider,
              ),
              const SizedBox(height: 10),
              Consumer<ReminderSettingsProvider>(
                builder: (context, reminders, _) {
                  final blocked =
                      reminders.permissionState ==
                      NotificationPermissionState.denied;
                  return _SettingsPanel(
                    padding: EdgeInsets.zero,
                    themeProvider: themeProvider,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Icon(
                        blocked ? LucideIcons.bellOff : LucideIcons.bellRing,
                        color: blocked
                            ? Colors.orange
                            : themeProvider.primaryColor,
                      ),
                      title: const Text('Feature reminders'),
                      subtitle: Text(
                        blocked
                            ? 'Blocked by system'
                            : reminders.preferences.masterEnabled
                            ? 'On · choose features and times'
                            : 'Off · preferences are preserved',
                      ),
                      trailing: const Icon(LucideIcons.chevronRight),
                      onTap: () => Navigator.push(
                        context,
                        AppRoute(page: const ReminderSettingsPage()),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _SettingsSectionLabel(
                label: 'Appearance',
                themeProvider: themeProvider,
              ),
              const SizedBox(height: 10),
              _SettingsPanel(
                padding: const EdgeInsets.all(16),
                themeProvider: themeProvider,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.palette,
                            color: themeProvider.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dark Mode',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: themeProvider.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Switch to dark theme',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: themeProvider.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: themeProvider.isDarkMode,
                      onChanged: themeProvider.setTheme,
                      activeColor: themeProvider.primaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SettingsSectionLabel(
                label: 'Voice',
                themeProvider: themeProvider,
              ),
              const SizedBox(height: 10),
              _SettingsPanel(
                padding: const EdgeInsets.all(16),
                themeProvider: themeProvider,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.mic,
                          color: themeProvider.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Voice Language',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: themeProvider.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Language for voice commands',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: themeProvider.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: VoiceSettingsProvider.availableLocales.map((
                        locale,
                      ) {
                        final isSelected =
                            voiceSettings.selectedLocale == locale['code'];
                        return GestureDetector(
                          onTap: () => voiceSettings.setLocale(locale['code']!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? themeProvider.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? themeProvider.primaryColor
                                    : themeProvider.textSecondary.withValues(
                                        alpha: 0.3,
                                      ),
                              ),
                            ),
                            child: Text(
                              '${locale['flag']} ${locale['name']}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : themeProvider.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  final String label;
  final ThemeProvider themeProvider;

  const _SettingsSectionLabel({
    required this.label,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: themeProvider.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final ThemeProvider themeProvider;
  final Widget child;

  const _SettingsPanel({
    required this.padding,
    required this.themeProvider,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.borderColor.withValues(alpha: 0.3),
        ),
      ),
      child: child,
    );
  }
}
