# Notifications

Notifications are handled mainly by `lib/core/services/notification_service.dart`.

## Current Uses

- Routine reminders.
- Calendar event reminders.
- Test notification helpers.

## Related Code

- `lib/core/services/notification_service.dart`
- `lib/features/routines/presentation/providers/routines_provider.dart`
- `lib/features/calendar/presentation/providers/calendar_provider.dart`
- `lib/main.dart`

## Important Notes

- Timezone is initialized for `Europe/Istanbul` in the notification service.
- App startup reloads routines and attempts to reschedule routine notifications.
- Calendar reminders calculate notification time from event time minus reminder
  offset.

## Change Checklist

- Verify Android permissions and manifest entries.
- Verify timezone behavior for scheduled notifications.
- Cancel stale notifications when deleting routines/events.
- Avoid duplicate notification IDs.
- Test with a near-future reminder on a real device or emulator.

## Live Audit Notes

- Timezone is hardcoded to `Europe/Istanbul`.
- Settings no longer exposes test/check notification actions to users.
- Calendar and routine reminder scheduling should be verified on a real Android
  device after release build is fixed.
