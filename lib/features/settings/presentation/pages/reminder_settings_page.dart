import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/reminders/domain/reminder_feature.dart';
import '../../../../core/reminders/domain/reminder_preferences.dart';
import '../../../../core/reminders/presentation/reminder_permission_prompt.dart';
import '../../../../core/reminders/presentation/reminder_settings_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/page_header.dart';

class ReminderSettingsPage extends StatelessWidget {
  const ReminderSettingsPage({super.key});

  static const _dailyFeatures = [
    ReminderFeature.mood,
    ReminderFeature.gratitudeMorning,
    ReminderFeature.gratitudeEvening,
    ReminderFeature.breathing,
    ReminderFeature.affirmations,
    ReminderFeature.todo,
    ReminderFeature.challenges,
    ReminderFeature.weeklyInsights,
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final reminders = context.watch<ReminderSettingsProvider>();
    final preferences = reminders.preferences;

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const PageHeader(
              title: 'Reminders',
              subtitle: 'Choose what Kora should gently bring back',
              showBackButton: true,
            ),
            const SizedBox(height: 20),
            _PermissionCard(provider: reminders),
            const SizedBox(height: 12),
            _ReminderPanel(
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(LucideIcons.bellRing),
                title: const Text('All reminders'),
                subtitle: const Text(
                  'Pause schedules without losing feature preferences',
                ),
                value: preferences.masterEnabled,
                onChanged: reminders.busy
                    ? null
                    : (value) => _setMaster(context, reminders, value),
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel('Water'),
            const SizedBox(height: 8),
            _WaterReminderCard(provider: reminders),
            const SizedBox(height: 24),
            _SectionLabel('Daily practices'),
            const SizedBox(height: 8),
            _ReminderPanel(
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < _dailyFeatures.length;
                    index++
                  ) ...[
                    _FeatureReminderTile(
                      feature: _dailyFeatures[index],
                      provider: reminders,
                    ),
                    if (index != _dailyFeatures.length - 1)
                      Divider(color: themeProvider.borderColor),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Routine reminders are configured per routine. Calendar reminders '
              'remain attached to each event.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: themeProvider.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _setMaster(
    BuildContext context,
    ReminderSettingsProvider provider,
    bool enabled,
  ) async {
    if (enabled &&
        !await explainReminderPermissionIfNeeded(context, provider)) {
      return;
    }
    await provider.setMasterEnabled(enabled);
  }
}

class _PermissionCard extends StatelessWidget {
  final ReminderSettingsProvider provider;

  const _PermissionCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final blocked =
        provider.permissionState == NotificationPermissionState.denied;
    final unknown =
        provider.permissionState == NotificationPermissionState.unknown;
    return _ReminderPanel(
      child: Row(
        children: [
          Icon(
            blocked ? LucideIcons.bellOff : LucideIcons.shieldCheck,
            color: blocked
                ? Colors.orange
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blocked
                      ? 'Blocked by system'
                      : unknown
                      ? 'Permission not requested'
                      : 'Notifications allowed',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  blocked
                      ? 'Enable notifications in system settings.'
                      : 'Kora follows your feature choices below.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (blocked)
            TextButton(
              onPressed: () async {
                await provider.openSystemSettings();
                await provider.refreshPermissionState();
              },
              child: const Text('Open settings'),
            ),
        ],
      ),
    );
  }
}

class _WaterReminderCard extends StatelessWidget {
  final ReminderSettingsProvider provider;

  const _WaterReminderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final preferences = provider.preferences;
    final enabled = preferences.isEnabled(ReminderFeature.water);
    return _ReminderPanel(
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(LucideIcons.droplet),
            title: const Text('Water reminders'),
            subtitle: Text(
              '${preferences.waterStart.label}-${preferences.waterEnd.label} · '
              'every ${preferences.waterIntervalHours} hours',
            ),
            value: enabled,
            onChanged: provider.busy
                ? null
                : (value) async {
                    if (value &&
                        !await explainReminderPermissionIfNeeded(
                          context,
                          provider,
                        )) {
                      return;
                    }
                    await provider.setFeatureEnabled(
                      ReminderFeature.water,
                      value,
                    );
                  },
          ),
          if (enabled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'Start',
                    time: preferences.waterStart,
                    onChanged: (time) => provider.setWaterSettings(
                      start: time,
                      end: preferences.waterEnd,
                      intervalHours: preferences.waterIntervalHours,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TimeButton(
                    label: 'End',
                    time: preferences.waterEnd,
                    onChanged: (time) => provider.setWaterSettings(
                      start: preferences.waterStart,
                      end: time,
                      intervalHours: preferences.waterIntervalHours,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: preferences.waterIntervalHours,
                  underline: const SizedBox.shrink(),
                  items: const [2, 3, 4]
                      .map(
                        (hours) => DropdownMenuItem(
                          value: hours,
                          child: Text('${hours}h'),
                        ),
                      )
                      .toList(),
                  onChanged: (hours) {
                    if (hours == null) return;
                    provider.setWaterSettings(
                      start: preferences.waterStart,
                      end: preferences.waterEnd,
                      intervalHours: hours,
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureReminderTile extends StatelessWidget {
  final ReminderFeature feature;
  final ReminderSettingsProvider provider;

  const _FeatureReminderTile({required this.feature, required this.provider});

  @override
  Widget build(BuildContext context) {
    final enabled = provider.preferences.isEnabled(feature);
    final time = provider.preferences.timeFor(feature);
    return Column(
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(feature.title),
          subtitle: Text(
            feature == ReminderFeature.weeklyInsights
                ? 'Sunday at ${time.label}'
                : 'Daily at ${time.label}',
          ),
          value: enabled,
          onChanged: provider.busy
              ? null
              : (value) async {
                  if (value &&
                      !await explainReminderPermissionIfNeeded(
                        context,
                        provider,
                      )) {
                    return;
                  }
                  await provider.setFeatureEnabled(feature, value);
                },
        ),
        if (enabled)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _pickTime(context, time),
              icon: const Icon(LucideIcons.clock3, size: 16),
              label: Text(time.label),
            ),
          ),
      ],
    );
  }

  Future<void> _pickTime(BuildContext context, ReminderTime current) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (selected == null) return;
    await provider.setFeatureTime(
      feature,
      ReminderTime(hour: selected.hour, minute: selected.minute),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final ReminderTime time;
  final ValueChanged<ReminderTime> onChanged;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        final selected = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: time.hour, minute: time.minute),
        );
        if (selected != null) {
          onChanged(ReminderTime(hour: selected.hour, minute: selected.minute));
        }
      },
      child: Text('$label ${time.label}'),
    );
  }
}

class _ReminderPanel extends StatelessWidget {
  final Widget child;

  const _ReminderPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.3)),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Text(
      text,
      style: TextStyle(
        color: theme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
      ),
    );
  }
}
