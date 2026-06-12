# Notifications

Platform notification delivery is handled by
`lib/core/services/notification_service.dart`. Reminder product rules and
reconciliation live under `lib/core/reminders/`.

## Current Uses

- Routine reminders.
- Calendar event reminders.
- Water, Mood, Gratitude, Breathing, Affirmations, Todo, and Challenges.
- Optional weekly insights.

## Related Code

- `lib/core/services/notification_service.dart`
- `lib/core/reminders/services/reminder_coordinator.dart`
- `lib/core/reminders/services/reminder_schedule_planner.dart`
- `lib/core/reminders/services/reminder_id_registry.dart`
- `lib/core/reminders/data/reminder_preferences_repository.dart`
- `lib/features/routines/presentation/providers/routines_provider.dart`
- `lib/features/calendar/presentation/providers/calendar_provider.dart`
- `lib/main.dart`

## Important Notes

- Timezone is read from the device at startup via `flutter_timezone`. Falls
  back to UTC if the platform channel is unavailable.
- App startup performs a full persisted reminder reconciliation without
  requesting notification permission.
- Calendar reminders calculate notification time from event time minus reminder
  offset and fall back to inexact delivery when exact scheduling is unavailable.
- Reminder IDs are stable and persisted by logical namespace.
- Normal reconciliation is namespace-scoped and never calls `cancelAll()`.
- The global switch cancels schedules without deleting feature preferences.
- Notification payloads open the corresponding feature root or owned routine.

## Change Checklist

- Verify Android permissions and manifest entries.
- Verify timezone behavior for scheduled notifications.
- Cancel stale notifications when deleting routines/events.
- Avoid duplicate notification IDs.
- Test with a near-future reminder on a real device or emulator.

## Live Audit Notes

- Settings no longer exposes test/check notification actions to users.
- Calendar and routine reminder scheduling should be verified on a real Android
  device after a timezone or scheduling change.

## Implemented Expansion

The persisted global and per-feature reminder rollout is documented in
`../05-tasks/feature-reminders-plan.md`.
