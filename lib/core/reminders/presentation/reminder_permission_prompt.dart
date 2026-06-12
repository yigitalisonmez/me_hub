import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import 'reminder_settings_provider.dart';

Future<bool> explainReminderPermissionIfNeeded(
  BuildContext context,
  ReminderSettingsProvider provider,
) async {
  if (provider.permissionState == NotificationPermissionState.granted) {
    return true;
  }

  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Allow reminders?'),
      content: const Text(
        'Kora only schedules the reminders you turn on. You can pause them '
        'globally or change each feature later.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  return accepted == true;
}
